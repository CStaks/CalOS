document.addEventListener('DOMContentLoaded', () => {
    const githubBtn = document.getElementById('btn-github');
    const downloadBtn = document.getElementById('btn-download');

    if (githubBtn) {
        githubBtn.addEventListener('click', () => {
            window.location.href = 'https://github.com/callenflynn/CalOS';
        });
    }

    if (downloadBtn) {
        downloadBtn.addEventListener('click', () => {
            window.location.href = 'https://sourceforge.net/projects/calos-linux/files/';
        });
    }
});