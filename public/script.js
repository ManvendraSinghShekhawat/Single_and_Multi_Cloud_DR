document.addEventListener('DOMContentLoaded', () => {
    const statusText = document.getElementById('statusText');
    const activeDb = document.getElementById('activeDb');
    const refreshButton = document.getElementById('refreshButton');

    async function fetchStatus() {
        try {
            const response = await fetch('/status');
            const data = await response.json();
            if (data.status === 'connected') {
                statusText.textContent = 'Connected';
                activeDb.textContent = data.activeDb;
            } else {
                statusText.textContent = 'Error';
                activeDb.textContent = 'N/A';
            }
        } catch (error) {
            statusText.textContent = 'Error';
            activeDb.textContent = 'N/A';
        }
    }

    refreshButton.addEventListener('click', fetchStatus);

    // Initial fetch
    fetchStatus();
});
