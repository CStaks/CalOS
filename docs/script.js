document.addEventListener('DOMContentLoaded', () => {
    const githubBtn = document.getElementById('btn-github');
    const downloadBtn = document.getElementById('btn-download');
    const graphicsStep = document.getElementById('graphics-step');
    const installStep = document.getElementById('install-step');
    const vmStep = document.getElementById('vm-step');
    const recommendation = document.getElementById('recommendation');
    const recommendationTitle = document.getElementById('recommendation-title');
    const recommendationCopy = document.getElementById('recommendation-copy');
    const chooserReset = document.getElementById('chooser-reset');
    const recommendationLink = document.getElementById('recommendation-link');
    let graphicsChoice = '';

    if (githubBtn) {
        githubBtn.addEventListener('click', () => {
            window.location.href = 'https://github.com/callenflynn/CalOS';
        });
    }

    if (downloadBtn) {
        downloadBtn.addEventListener('click', () => {
            document.getElementById('chooser')?.scrollIntoView({ behavior: 'smooth' });
        });
    }

    const show = (element) => element?.classList.remove('is-hidden');
    const hide = (element) => element?.classList.add('is-hidden');

    document.querySelectorAll('[data-graphics]').forEach((button) => {
        button.addEventListener('click', () => {
            graphicsChoice = button.dataset.graphics;
            show(installStep);
            hide(vmStep);
            hide(recommendation);
            installStep?.scrollIntoView({ behavior: 'smooth', block: 'center' });
        });
    });

    document.querySelectorAll('[data-install]').forEach((button) => {
        button.addEventListener('click', () => {
            if (button.dataset.install === 'vm') {
                show(vmStep);
                hide(recommendation);
                vmStep?.scrollIntoView({ behavior: 'smooth', block: 'center' });
            } else {
                showRecommendation(
                    graphicsChoice === 'nvidia' ? 'NVIDIA ISO' : 'Standard ISO',
                    graphicsChoice === 'nvidia'
                        ? 'For NVIDIA graphics on real hardware. This ISO includes the NVIDIA build.'
                        : 'For AMD or Intel graphics on real hardware. This is the normal CalOS build.',
                    graphicsChoice === 'nvidia' ? 'nvidia-install.iso' : 'standard-install.iso',
                );
            }
        });
    });

    document.querySelectorAll('[data-vm]').forEach((button) => {
        button.addEventListener('click', () => {
            const format = button.dataset.vm === 'vmdk' ? 'VMDK' : 'QCOW2';
            const gpu = graphicsChoice === 'nvidia' ? 'NVIDIA' : 'Standard';
            showRecommendation(
                `${gpu} ${format}`,
                button.dataset.vm === 'vmdk'
                    ? `${gpu} VMDK for VMware virtual machines.`
                    : `${gpu} QCOW2 for QEMU or GNOME Boxes virtual machines.`,
                `${graphicsChoice === 'nvidia' ? 'nvidia' : 'standard'}-disk.${button.dataset.vm}`,
            );
        });
    });

    chooserReset?.addEventListener('click', () => {
        graphicsChoice = '';
        hide(installStep);
        hide(vmStep);
        hide(recommendation);
        graphicsStep?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    });

    function showRecommendation(title, copy, filename) {
        if (!recommendation || !recommendationTitle || !recommendationCopy) return;
        recommendationTitle.textContent = `Recommended: ${title}`;
        recommendationCopy.textContent = copy;
        if (recommendationLink && filename) {
            recommendationLink.href = `https://sourceforge.net/projects/calos-linux/files/${filename}/download`;
        }
        show(recommendation);
        recommendationLink?.focus();
        recommendation.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
});
