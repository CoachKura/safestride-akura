// SafeStride flicker and reload guard
(function() {
    'use strict';

    // Fade-in once DOM is ready
    document.addEventListener('DOMContentLoaded', () => {
        document.body.classList.add('loaded');
    });

    // Prevent rapid reload loops
    let isLoading = false;
    const originalReload = window.location.reload;

    window.location.reload = function() {
        if (isLoading) {
            console.warn('Reload blocked - already loading');
            return;
        }
        isLoading = true;
        setTimeout(() => { isLoading = false; }, 2000);
        originalReload.call(window.location);
    };

    // Throttle DOM updates per element to reduce flicker
    const updateQueue = new Set();
    window.safeUpdate = function(elementId, content) {
        if (updateQueue.has(elementId)) return;

        updateQueue.add(elementId);
        const element = document.getElementById(elementId);
        if (element) element.innerHTML = content;

        setTimeout(() => updateQueue.delete(elementId), 100);
    };
})();
