#!/usr/bin/env python3
"""Build the CalOS wiki.

Reads the wiki layout (docs/wiki-layout.json), the markdown sources in
docs/wiki-src/, and generates themed HTML pages in docs/wiki/. Each page
reuses the brand theme via ../wiki.css and gets a sidebar of all pages.

Dependencies (installed in CI or locally):
    pip install markdown PyYAML
"""

import json
import re
import unicodedata
from pathlib import Path

try:
    import markdown as md_lib
except ImportError:  # pragma: no cover
    raise SystemExit("Missing dependency: `pip install markdown`")

try:
    import yaml
except ImportError:  # pragma: no cover
    raise SystemExit("Missing dependency: `pip install PyYAML`")

REPO_ROOT = Path(__file__).resolve().parents[1]
LAYOUT_FILE = REPO_ROOT / "docs" / "wiki-layout.json"
WIKI_SRC = REPO_ROOT / "docs" / "wiki-src"
WIKI_OUT = REPO_ROOT / "docs" / "wiki"
CSS_LINK = "../wiki.css"
MAIN_SITE_URL = "https://callenflynn.github.io/CalOS/"
INDEX_SLUG = "index"


def escape(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def slugify(value: str) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = value.encode("ascii", "ignore").decode("ascii")
    value = re.sub(r"[^\w\s-]", "", value).strip().lower()
    return re.sub(r"[-\s]+", "-", value)


def parse_front_matter(text: str):
    """Split leading '---' front matter from the markdown body.

    Returns (meta_dict, body). If there is no front matter, returns ({}, text).
    """
    if not text.startswith("---"):
        return {}, text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text
    try:
        meta = yaml.safe_load(parts[1]) or {}
        if not isinstance(meta, dict):
            meta = {}
    except yaml.YAMLError:
        meta = {}
    return meta, parts[2].lstrip("\n")


def render_markdown(text: str) -> str:
    return md_lib.markdown(text, extensions=["fenced_code", "tables"])


def title_from_path(rel_path: str) -> str:
    stem = Path(rel_path).stem
    return re.sub(r"[_-]+", " ", stem).strip().title()


def load_layout():
    """Return a list of (category, [rel_path, ...]) preserving order."""
    data = json.loads(LAYOUT_FILE.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise SystemExit("wiki-layout.json must be a JSON object")
    # Tolerate the simple form {"sub-wiki": [...]} as one flat group.
    if set(data.keys()) == {"sub-wiki"} and isinstance(data["sub-wiki"], list):
        return [("Pages", data["sub-wiki"])]
    groups = []
    for category, pages in data.items():
        if not isinstance(pages, list):
            raise SystemExit(f"Expected a list of pages for group '{category}'")
        groups.append((category, pages))
    return groups


def read_meta(rel_path: str):
    src = WIKI_SRC / rel_path
    meta, _ = parse_front_matter(src.read_text(encoding="utf-8"))
    return meta


def slug_for(rel_path: str) -> str:
    meta = read_meta(rel_path)
    return slugify(meta.get("name") or Path(rel_path).stem)


def name_for(rel_path: str) -> str:
    meta = read_meta(rel_path)
    return meta.get("name") or title_from_path(rel_path)


def make_nav(groups, active_slug):
    out = []
    for category, paths in groups:
        out.append(f"<h2>{escape(category)}</h2>")
        out.append("<ul>")
        for rel_path in paths:
            if not (WIKI_SRC / rel_path).exists():
                continue
            slug = slug_for(rel_path)
            cls = ' class="active"' if slug == active_slug else ""
            out.append(
                f'<li><a href="{escape(slug + ".html")}"{cls}>{escape(name_for(rel_path))}</a></li>'
            )
        out.append("</ul>")
    return "\n".join(out)


def chrome(active_slug, title, body, description=None):
    groups = load_layout()
    nav = make_nav(groups, active_slug)
    meta_desc = f'<meta name="description" content="{escape(description)}">' if description else ""
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{escape(title)} · CalOS Wiki</title>
{meta_desc}
<link rel="stylesheet" href="{CSS_LINK}">
<link rel="icon" type="image/x-icon" href="../CalOS.ico">
</head>
<body>
<header class="wiki-topbar">
  <div class="wiki-topbar-inner">
    <a class="wiki-brand" href="index.html">CalOS<span style="color:var(--bg-color)"> · Wiki</span></a>
    <a class="wiki-back" href="{MAIN_SITE_URL}">← Back to CalOS</a>
  </div>
</header>
<div class="wiki-layout">
  <nav class="wiki-nav" aria-label="Wiki pages">
{nav}
  </nav>
  <main class="wiki-content">
{body}
  </main>
</div>
<footer class="wiki-footer">
  <div class="wiki-footer-inner">
    <span>Distributed under the <a href="https://www.apache.org/licenses/LICENSE-2.0.txt">Apache 2.0 License</a>.</span>
    <span><a href="{MAIN_SITE_URL}">CalOS</a></span>
  </div>
</footer>
</body>
</html>
"""


def build_index(groups):
    body = "<p>Guides, walkthroughs, and answers for CalOS.</p>\n"
    for category, paths in groups:
        body += f"<h2>{escape(category)}</h2>\n<ul>\n"
        for rel_path in paths:
            body += (
                f'  <li><a href="{escape(slug_for(rel_path) + ".html")}">{escape(name_for(rel_path))}</a></li>\n'
            )
        body += "</ul>\n"
    (WIKI_OUT / "index.html").write_text(
        chrome(INDEX_SLUG, "Wiki home", body),
        encoding="utf-8",
    )
    print("  built docs/wiki/index.html")


def build():
    WIKI_OUT.mkdir(parents=True, exist_ok=True)
    groups = load_layout()
    generated = {Path("index.html")}

    for _category, paths in groups:
        for rel_path in paths:
            src = WIKI_SRC / rel_path
            if not src.exists():
                print(f"!! missing source: {rel_path}")
                continue
            meta, body = parse_front_matter(src.read_text(encoding="utf-8"))
            slug = slugify(meta.get("name") or Path(rel_path).stem)
            title = meta.get("name") or title_from_path(rel_path)
            description = meta.get("description") or None

            html_body = render_markdown(body)
            if description:
                html_body = (
                    f'<p class="wiki-description" style="color:var(--muted)">{escape(description)}</p>'
                    + html_body
                )
            out = WIKI_OUT / f"{slug}.html"
            out.write_text(chrome(slug, title, html_body, description), encoding="utf-8")
            generated.add(Path(f"{slug}.html"))
            print(f"  built {out.relative_to(REPO_ROOT)}")

    build_index(groups)

    # Remove any *.html left over from pages no longer in the layout.
    for existing in WIKI_OUT.glob("*.html"):
        if existing.name not in {g.name for g in generated}:
            existing.unlink()
            print(f"  removed stale {existing.name}")

    print("Wiki built into docs/wiki/")


if __name__ == "__main__":
    build()