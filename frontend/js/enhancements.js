// Enhanced navigation & interactions for the dashboard
(function(){
  // Show toast notification
  function showToast(message, type = 'info') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `
      <div style="font-weight: 600; color: #1a202c;">${message}</div>
    `;
    document.body.appendChild(toast);
    setTimeout(() => {
      toast.style.opacity = '0';
      setTimeout(() => toast.remove(), 300);
    }, 3000);
  }

  // Add "Coming Soon" toast
  function showComingSoon(featureName) {
    showToast(`${featureName} - Coming Soon! 🚀`, 'info');
  }

  // Add badges to specified sections
  function addComingSoonBadges() {
    const sectionsWithBadges = [
      { selector: '.pillar-chart-card', text: 'Enhanced Charts' },
      { selector: '.workout-item:first-child', text: 'Track Workout' },
      { selector: '[data-device="strava"]', text: 'Coming Soon' },
      { selector: '[data-device="apple-health"]', text: 'Coming Soon' },
      { selector: '[data-device="coros"]', text: 'Coming Soon' },
    ];

    sectionsWithBadges.forEach(({ selector, text }) => {
      const element = document.querySelector(selector);
      if (element && !element.querySelector('.coming-soon-badge')) {
        const badge = document.createElement('div');
        badge.className = 'coming-soon-badge';
        badge.textContent = text;
        element.style.position = 'relative';
        element.appendChild(badge);
      }
    });
  }

  // Wire up interactive behaviors once DOM is ready
  document.addEventListener('DOMContentLoaded', () => {
    addComingSoonBadges();

    // Make workout card clickable
    document.querySelector('.workout-card')?.addEventListener('click', function(e) {
      if (!e.target.closest('.btn-primary')) {
        showComingSoon('Workout Details');
      }
    });

    // Make progress cards clickable
    document.querySelectorAll('.progress-card').forEach(card => {
      card.addEventListener('click', function() {
        const cardType = this.classList.contains('week-progress') ? 'Weekly Progress Details' :
                        this.classList.contains('rpe') ? 'RPE Analysis' :
                        this.classList.contains('injury') ? 'Injury Management' :
                        'Assessment Schedule';
        showComingSoon(cardType);
      });
    });

    // Make pillar chart clickable
    document.querySelector('.pillar-chart-card')?.addEventListener('click', function() {
      showComingSoon('Detailed Pillar Analysis');
    });

    // Make workout items clickable
    document.querySelectorAll('.workout-item').forEach(item => {
      item.addEventListener('click', function() {
        showComingSoon('Workout Details & History');
      });
    });

    // Handle START WORKOUT button
    document.querySelectorAll('.btn-start, .btn-primary').forEach(btn => {
      btn.addEventListener('click', function(e) {
        e.stopPropagation();
        showToast('Starting workout... 💪', 'success');
        setTimeout(() => {
          showComingSoon('Workout Tracker');
        }, 1000);
      });
    });

    // Handle View Full Details button
    document.querySelectorAll('.btn-secondary, .btn-secondary-outline').forEach(btn => {
      btn.addEventListener('click', function(e) {
        e.stopPropagation();
        showComingSoon('Full Workout Details');
      });
    });

    // Handle device connection buttons
    document.querySelectorAll('[data-device]').forEach(button => {
      button.addEventListener('click', function() {
        const device = this.getAttribute('data-device');
        showComingSoon(`${device} Integration`);
      });
    });

    // Handle AIFRI score click
    document.querySelector('.aifri-badge')?.addEventListener('click', function() {
      showComingSoon('Detailed AIFRI Analysis & Recommendations');
    });

    // Handle streak badge click
    document.querySelector('.streak-badge')?.addEventListener('click', function() {
      showComingSoon('Activity Streak Details & Challenges');
    });

    // Welcome toast
    setTimeout(() => {
      showToast('Welcome to your enhanced dashboard! 🎉', 'success');
    }, 500);

    console.log('✅ Enhanced navigation & interactions loaded!');
  });
})();
