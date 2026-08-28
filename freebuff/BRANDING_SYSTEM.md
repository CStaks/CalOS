# Branding System

Everything that makes CalOS look like CalOS. All of it ships through the
`system_files/` overlay (copied to `/` by `build.sh`) plus the `CalOS/` asset
folder. Brand tokens are defined once and reused across GRUB, Plymouth, GDM,
fastfetch/neofetch, starship, and wallpapers.

## Brand Tokens

| Token | Value | Used in |
|---|---|---|
| Primary accent | `#FF3B00` | GRUB highlight, Plymouth spinner, starship, ANSI color |
| Background | `#050505` | Plymouth, starship |
| Text | `#E0E0E0` | Starship text, Plymouth text |
| Teal (logo alt) | `#71aab9` | `CalOS-71aab9.*` logo colorway |
| Slate (logo alt) | `#7a899c` | `CalOS-7a899c.*` logo colorway |
| OS ANSI color | `0;38;2;255;59;0` | `os-release` `ANSI_COLOR` (= `#FF3B00`) |

## `system_files/` overlay — file by file

### Identity (`usr/lib/os-release`)
```
NAME="CalOS"  ID="fedora"  ID_LIKE="fedora"  VERSION="CalOS"  VERSION_ID="43"
PRETTY_NAME="CalOS"  LOGO="/usr/share/pixmaps/CalOS.svg"
HOME_URL/SUPPORT_URL/BUG_REPORT_URL → github.com/callenflynn/CalOS
```
`ID`/`ID_LIKE` stay `fedora` (bootc-image-builder requires it). `VERSION_ID`
is **restored from the base image at build time** — `build.sh` captures it
before the `system_files/` overlay and re-applies it after, so the committed
value is a placeholder that never goes stale. Rolling builds keep the generic
`VERSION`/`PRETTY_NAME`; versioned tag builds stamp `VERSION="1.2 (Superior)"`
and `PRETTY_NAME="CalOS Superior"`. The repository URLs use the actual owner,
`callenflynn` (Callen Flynn).

### GRUB (`etc/default/grub`)
`GRUB_DISTRIBUTOR="CalOS"`, highlight color `#FF3B00/black`, `rhgb quiet` cmdline,
5s timeout.

### Boot splash (`usr/share/plymouth/themes/calos/`)
- `calos.plymouth` — theme manifest (script module, ImageDir + ScriptFile).
- `calos.script` — dark `#050505` background, a "CalOS" title that switches to
  "Shutting down..." / "Restarting..." by mode, three `#FF3B00` pulsing dots
  (`●` glyphs via `Image.Text`), and the boot status message via
  `Plymouth.SetDisplayMessageFunction`. Uses only real Plymouth script APIs
  (`Image.Text`, `Sprite`, `Window`, `Plymouth`) — no image assets needed.
- Activated by `plymouth-set-default-theme calos` in build.sh (with a
  `plymouthd.conf` fallback).

### GDM login screen (`usr/share/pixmaps/CalOS.svg`)
Set as `org.gnome.login-screen` logo via the `gdm.d` dconf keyfile, with the
`night-iceberg.png` wallpaper on the greeter; `dconf update` compiles it at
build time.

### Desktop defaults (`usr/share/glib-2.0/schemas/zz_calos.gschema.override`)
- **Wallpapers:** `mountains.png` (light) / `night-iceberg.png` (dark); screensaver
  also `mountains.png`.
- **Dock favorites:** Files, Brave, Zed, Ghostty, Software, Settings.
- **Default terminal:** `ghostty`.

The `zz_` prefix sorts after Bluefin's `zz1-bluefin-extensions.gschema.override`,
so CalOS values win when both sets apply.

### Shell prompt (`etc/skel/.config/starship.toml`)
CalOS-themed segmented prompt: `calos` OS chip, username, truncated git-aware
directory, git branch/status, command duration; accent `#FF3B00`, success symbol
`❯` in accent, error in red. Enabled for new users via `/etc/profile.d/calos.sh`
(bash only — see INDEX gotcha #9). The same profile script installs the
`calos-update` / `calos-rollback` / `calos-version` / `calos-switch-latest`
aliases. System updates use Universal Blue's `ujust update` (inherited from
Bluefin), so no custom Justfile is shipped.

### Terminal info tools
- `usr/share/fastfetch/calos-logo.txt` — the ASCII CalOS logo (source of truth).
- `usr/share/fastfetch/presets/calos.jsonc` + `etc/skel/.config/fastfetch/config.jsonc`
  — point fastfetch at the logo file. `/etc/profile.d/calos.sh` also exports
  `FASTFETCH_CONFIG` so the CalOS preset wins over a base-image default.
- `etc/skel/.config/neofetch/config.conf` — neofetch uses the same ASCII file with
  brand-colored ANSI palette `(1 6 4 12 8 14)`.

## Assets (`CalOS/`)

| Asset | Role |
|---|---|
| `CalOS.png` / `CalOS.svg` | Primary logo; `CalOS.svg` is the GDM greeter logo; `CalOS.png` is the ArtifactHub logo URL |
| `CalOS-71aab9.png/svg`, `CalOS-7a899c.png/svg` | Alternate colorway logos |
| `calos-github-social.png` | README hero image |
| `ascii-art.txt` | ASCII logo (duplicated into `system_files/usr/share/fastfetch/`) |
| `wallpapers/` | `mountains.png`, `night-iceberg.png`, `fuji.png`, `macos-big-sur-wallpaper-5-scaled.jpg` — copied to `usr/share/backgrounds/calos/` |

## How the overlay is applied

`build.sh` runs `cp -avf /ctx/system_files/. /` **after** all package installs
(so the CalOS os-release never blocks dnf5), then `glib-compile-schemas` +
`dconf update`. The `.gitkeep` files in `system_files/etc/` and
`system_files/usr/` keep empty dirs in git.
