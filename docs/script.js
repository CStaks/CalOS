document.addEventListener('DOMContentLoaded', () => {
    const githubBtn = document.getElementById('btn-github');
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

    const renderQuestion = (label, title, choices) => {
        if (!stepLabel || !questionTitle || !choiceGrid) return;
        stepLabel.textContent = label;
        questionTitle.textContent = title;
        choiceGrid.replaceChildren(...choices.map(({ text, detail, attributes }) => {
            const button = document.createElement('button');
            button.className = 'choice';
            button.textContent = text;
            if (attributes) Object.entries(attributes).forEach(([key, value]) => button.dataset[key] = value);
            const span = document.createElement('span');
            span.textContent = detail;
            button.append(span);
            return button;
        }));
        questionPanel?.classList.remove('is-hidden');
        hide(recommendation);
        questionPanel?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    };

    const show = (element) => element?.classList.remove('is-hidden');
    const hide = (element) => element?.classList.add('is-hidden');

    choiceGrid?.addEventListener('click', (event) => {
        const button = event.target.closest('button');
        if (!button) return;
        if (button.dataset.graphics) {
            graphicsChoice = button.dataset.graphics;
            renderQuestion('Question 2 of 2', 'Are you installing on hardware or in a VM?', [
                { text: 'Hardware', detail: 'Install from an ISO', attributes: { install: 'hardware' } },
                { text: 'Virtual machine', detail: 'Choose QCOW2 or VMDK next', attributes: { install: 'vm' } },
            ]);
        } else if (button.dataset.install === 'vm') {
            renderQuestion('One last choice', 'Which virtual machine software?', [
                { text: 'QEMU or GNOME Boxes', detail: 'Download QCOW2', attributes: { vm: 'qcow2' } },
                { text: 'VMware', detail: 'Download VMDK', attributes: { vm: 'vmdk' } },
            ]);
        } else if (button.dataset.install === 'hardware') {
            showRecommendation(
                graphicsChoice === 'nvidia' ? 'NVIDIA ISO' : 'Standard ISO',
                graphicsChoice === 'nvidia'
                    ? 'For NVIDIA graphics on real hardware. This ISO includes the NVIDIA build.'
                    : 'For AMD or Intel graphics on real hardware. This is the normal CalOS build.',
                graphicsChoice === 'nvidia' ? 'nvidia-install.iso' : 'standard-install.iso',
            );
        } else if (button.dataset.vm) {
            const format = button.dataset.vm === 'vmdk' ? 'VMDK' : 'QCOW2';
            const gpu = graphicsChoice === 'nvidia' ? 'NVIDIA' : 'Standard';
            showRecommendation(
                `${gpu} ${format}`,
                button.dataset.vm === 'vmdk'
                    ? `${gpu} VMDK for VMware virtual machines.`
                    : `${gpu} QCOW2 for QEMU or GNOME Boxes virtual machines.`,
                `${graphicsChoice === 'nvidia' ? 'nvidia' : 'standard'}-disk.${button.dataset.vm}`,
            );
        }
    });

    chooserReset?.addEventListener('click', () => {
        graphicsChoice = '';
        renderQuestion('Question 1 of 2', 'What graphics card do you have?', [
            { text: 'AMD or Intel', detail: 'Use the Standard build', attributes: { graphics: 'standard' } },
            { text: 'NVIDIA', detail: 'Use the NVIDIA build', attributes: { graphics: 'nvidia' } },
        ]);
    });

    function showRecommendation(title, copy, filename) {
        if (!recommendation || !recommendationTitle || !recommendationCopy) return;
        recommendationTitle.textContent = `Recommended: ${title}`;
        recommendationCopy.textContent = copy;
        if (recommendationLink && filename) {
            const releaseUrl = 'https://github.com/callenflynn/CalOS/releases/latest';
            recommendationLink.href = `${releaseUrl}#${filename}`;
            recommendationLink.textContent = 'Open the latest release downloads →';
        }
        hide(questionPanel);
        show(recommendation);
        recommendationLink?.focus();
        recommendation.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }
});
