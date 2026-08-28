document.addEventListener('DOMContentLoaded', () => {
    const githubBtn = document.getElementById('btn-github');
    const wikiBtn = document.getElementById('btn-wiki');
    const downloadBtn = document.getElementById('btn-download');
    const questionPanel = document.getElementById('question-panel');
    const stepLabel = document.getElementById('step-label');
    const questionTitle = document.getElementById('question-title');
    const choiceGrid = document.getElementById('choice-grid');
    const recommendation = document.getElementById('recommendation');
    const recommendationTitle = document.getElementById('recommendation-title');
    const recommendationCopy = document.getElementById('recommendation-copy');
    const chooserReset = document.getElementById('chooser-reset');
    const recommendationLink = document.getElementById('recommendation-link');

    document.querySelectorAll('a.js-smooth-scroll').forEach((link) => {
        link.addEventListener('click', (event) => {
            const target = document.querySelector(link.getAttribute('href'));
            if (!target) return;
            event.preventDefault();
            history.pushState(null, '', link.getAttribute('href'));
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        });
    });

    const state = { graphics: '', arch: '', install: '', vm: '' };
    let shouldScrollToChooser = false;

    const show = (el) => el?.classList.remove('is-hidden');
    const hide = (el) => el?.classList.add('is-hidden');
    const totalSteps = () => 4;

    const renderQuestion = (label, title, choices) => {
        if (!stepLabel || !questionTitle || !choiceGrid) return;
        stepLabel.textContent = label;
        questionTitle.textContent = title;
        choiceGrid.replaceChildren(...choices.map(({ text, detail, attributes }) => {
            const button = document.createElement('button');
            button.className = 'choice';
            button.textContent = text;
            if (attributes) Object.entries(attributes).forEach(([key, value]) => (button.dataset[key] = value));
            const span = document.createElement('span');
            span.textContent = detail;
            button.append(span);
            return button;
        }));
        show(questionPanel);
        hide(recommendation);
        if (shouldScrollToChooser) {
            questionPanel?.scrollIntoView({ behavior: 'smooth', block: 'center' });
            shouldScrollToChooser = false;
        }
    };

    const askArch = () => {
        renderQuestion(`Question 1 of ${totalSteps()}`, 'What kind of computer is it?', [
            { text: 'x86_64', detail: 'Intel or AMD — what most computers have', attributes: { arch: 'x86_64' } },
            { text: 'ARM64', detail: 'Apple Silicon, Raspberry Pi-style boards, and other ARM systems', attributes: { arch: 'arm64' } },
        ]);
    };

    const askGraphics = () => {
        renderQuestion(`Question 2 of ${totalSteps()}`, 'What graphics card do you have?', [
            { text: 'AMD or Intel', detail: 'Use the Standard build', attributes: { graphics: 'standard' } },
            { text: 'NVIDIA', detail: 'Use the NVIDIA build (x86_64 only)', attributes: { graphics: 'nvidia' } },
        ]);
    };

    const askInstall = () => {
        renderQuestion('Question 3 of 4', 'Are you installing on hardware or in a VM?', [
            { text: 'Hardware', detail: 'Install from an ISO', attributes: { install: 'hardware' } },
            { text: 'Virtual machine', detail: 'Choose QCOW2 or VMDK next', attributes: { install: 'vm' } },
        ]);
    };

    const askVm = () => {
        const choices = [
            { text: 'QEMU or GNOME Boxes', detail: 'Download QCOW2', attributes: { vm: 'qcow2' } },
            { text: 'VMware', detail: 'Download VMDK', attributes: { vm: 'vmdk' } },
        ];
        renderQuestion('Question 4 of 4', 'Which virtual machine software?', choices);
    };

    const diskFile = (arch, variant, ext) =>
        `calos-v${window.CALOS_LATEST_RELEASE || '1.1.4'}_${arch}${variant === 'nvidia' ? '-nvidia' : ''}.${ext}`;

    const recommend = () => {
        let title, copy, filename;
        if (state.install === 'hardware') {
            if (state.graphics === 'nvidia') {
                title = 'NVIDIA ISO (x86_64)';
                copy = 'For NVIDIA graphics on real hardware. This ISO includes the NVIDIA build — x86_64 only.';
                filename = diskFile('x86_64', 'nvidia', 'iso');
            } else if (state.arch === 'arm64') {
                title = 'Standard ISO (ARM64)';
                copy = 'For ARM64 hardware. This is the normal CalOS build for ARM.';
                filename = diskFile('arm64', 'standard', 'iso');
            } else {
                title = 'Standard ISO (x86_64)';
                copy = 'For AMD or Intel graphics on real hardware. This is the normal CalOS build.';
                filename = diskFile('x86_64', 'standard', 'iso');
            }
        } else if (state.vm === 'vmdk') {
            title = state.arch === 'arm64' ? 'Standard VMDK (ARM64)' : 'Standard VMDK (x86_64)';
            copy = 'For VMware machines, VMware virtualizes the GPU, so use this file for NVIDIA, AMD, or Intel hosts.';
            filename = diskFile(state.arch, 'standard', 'vmdk');
        } else if (state.graphics === 'nvidia') {
            title = 'NVIDIA QCOW2 (x86_64)';
            copy = 'NVIDIA QCOW2 for QEMU or GNOME Boxes virtual machines. NVIDIA builds are x86_64 only.';
            filename = diskFile('x86_64', 'nvidia', 'qcow2');
        } else {
            title = state.arch === 'arm64' ? 'Standard QCOW2 (ARM64)' : 'Standard QCOW2 (x86_64)';
            copy = `Standard ${state.arch === 'arm64' ? 'ARM64' : 'x86_64'} QCOW2 for QEMU or GNOME Boxes virtual machines.`;
            filename = diskFile(state.arch, 'standard', 'qcow2');
        }
        showRecommendation(title, copy, filename);
    };

    choiceGrid?.addEventListener('click', (event) => {
        const button = event.target.closest('button');
        if (!button) return;
        shouldScrollToChooser = true;
        if (button.dataset.arch) {
            state.arch = button.dataset.arch;
            askGraphics();
        } else if (button.dataset.graphics) {
            state.graphics = button.dataset.graphics;
            if (state.graphics === 'nvidia') {
                state.arch = 'x86_64';
            }
            askInstall();
        } else if (button.dataset.install) {
            state.install = button.dataset.install;
            if (state.install === 'vm') askVm();
            else recommend();
        } else if (button.dataset.vm) {
            state.vm = button.dataset.vm;
            recommend();
        }
    });

    chooserReset?.addEventListener('click', () => {
        state.graphics = state.arch = state.install = state.vm = '';
        shouldScrollToChooser = true;
        askArch();
    });

    function showRecommendation(title, copy, filename) {
        if (!recommendation || !recommendationTitle || !recommendationCopy) return;
        recommendationTitle.textContent = `Recommended: ${title}`;
        recommendationCopy.textContent = copy;
        if (recommendationLink && filename) {
            const latestRelease = window.CALOS_LATEST_RELEASE || '1.1.4';
            recommendationLink.href = `https://sourceforge.net/projects/calos-linux/files/${latestRelease}/${encodeURIComponent(filename)}/download`;
            recommendationLink.textContent = 'Download from SourceForge →';
        }
        hide(questionPanel);
        show(recommendation);
        recommendationLink?.focus();
        if (shouldScrollToChooser) {
            recommendation.scrollIntoView({ behavior: 'smooth', block: 'center' });
            shouldScrollToChooser = false;
        }
    }

    downloadBtn?.addEventListener('click', () => {
        shouldScrollToChooser = true;
        document.getElementById('chooser')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });

    githubBtn?.addEventListener('click', () => {
        window.location.href = 'https://github.com/callenflynn/CalOS';
    });

    wikiBtn?.addEventListener('click', () => {
        window.location.href = 'wiki/';
    });

    // Initialize without scrolling so URLs such as /#about remain at their target.
    askArch();
});

// Populate the GitHub repo card live from the GitHub API.
// The static content in the markup acts as a fallback if the request fails.
(async function loadGithubCard() {
    const card = document.getElementById('github-card');
    if (!card) return;
    try {
        const res = await fetch('https://api.github.com/repos/callenflynn/CalOS');
        if (!res.ok) throw new Error(`GitHub API responded ${res.status}`);
        const data = await res.json();
        card.querySelectorAll('[data-field]').forEach((el) => {
            const value = data[el.dataset.field];
            if (value != null) el.textContent = value;
        });
    } catch (err) {
        // Keep the static fallback content as-is.
    }
})();

// Auto-update the copyright year in the footer.
document.addEventListener('DOMContentLoaded', () => {
    const yearEl = document.getElementById('year');
    if (yearEl) yearEl.textContent = String(new Date().getFullYear());
});