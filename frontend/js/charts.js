/**
 * Chart.js utility for pace progression visualization
 */

/**
 * Create a pace progression chart over 30 days
 */
async function createPaceProgressionChart(canvasId, authToken, apiBaseUrl) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) {
        console.error(`Canvas element #${canvasId} not found`);
        return null;
    }

    const ctx = canvas.getContext('2d');

    try {
        // Fetch workouts from API
        const response = await fetch(`${apiBaseUrl}/api/workouts`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) throw new Error('Failed to fetch workouts');

        const workouts = await response.json();

        // Filter to last 30 days and sort by date
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const recentWorkouts = workouts
            .filter(w => new Date(w.date) >= thirtyDaysAgo)
            .sort((a, b) => new Date(a.date) - new Date(b.date));

        if (recentWorkouts.length === 0) {
            console.warn('No workouts found in last 30 days');
            return null;
        }

        // Convert pace strings to seconds for consistent display
        const toSeconds = (paceStr) => {
            if (!paceStr) return null;
            const [min, sec] = paceStr.split(':').map(Number);
            return (min || 0) * 60 + (sec || 0);
        };

        // Prepare chart data
        const dates = recentWorkouts.map(w => new Date(w.date).toLocaleDateString());
        const paces = recentWorkouts.map(w => toSeconds(w.pace)).filter(v => v !== null);
        const distances = recentWorkouts.map(w => w.distance || 0);

        // Create Chart.js instance
        const chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: dates,
                datasets: [
                    {
                        label: 'Pace (min/km)',
                        data: paces,
                        borderColor: 'rgb(59, 130, 246)',
                        backgroundColor: 'rgba(59, 130, 246, 0.1)',
                        borderWidth: 2,
                        tension: 0.3,
                        fill: true,
                        pointRadius: 5,
                        pointBackgroundColor: 'rgb(59, 130, 246)',
                        pointBorderColor: '#fff',
                        pointBorderWidth: 2,
                        yAxisID: 'y'
                    },
                    {
                        label: 'Distance (km)',
                        data: distances,
                        borderColor: 'rgb(34, 197, 94)',
                        backgroundColor: 'rgba(34, 197, 94, 0.1)',
                        borderWidth: 2,
                        tension: 0.3,
                        fill: false,
                        pointRadius: 4,
                        pointBackgroundColor: 'rgb(34, 197, 94)',
                        yAxisID: 'y1'
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: {
                    mode: 'index',
                    intersect: false
                },
                plugins: {
                    legend: {
                        display: true,
                        position: 'top'
                    },
                    title: {
                        display: true,
                        text: 'Pace Progression (Last 30 Days)'
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                if (context.dataset.yAxisID === 'y') {
                                    const seconds = context.parsed.y;
                                    const min = Math.floor(seconds / 60);
                                    const sec = Math.round(seconds % 60);
                                    return `Pace: ${min}:${sec.toString().padStart(2, '0')}/km`;
                                }
                                return `Distance: ${context.parsed.y} km`;
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        type: 'linear',
                        display: true,
                        position: 'left',
                        reverse: true, // Lower pace is better
                        title: {
                            display: true,
                            text: 'Pace (min/km)'
                        },
                        ticks: {
                            callback: function(value) {
                                const min = Math.floor(value / 60);
                                const sec = Math.round(value % 60);
                                return `${min}:${sec.toString().padStart(2, '0')}`;
                            }
                        }
                    },
                    y1: {
                        type: 'linear',
                        display: true,
                        position: 'right',
                        title: {
                            display: true,
                            text: 'Distance (km)'
                        },
                        grid: {
                            drawOnChartArea: false
                        }
                    }
                }
            }
        });

        return chart;
    } catch (error) {
        console.error('Error creating pace progression chart:', error);
        return null;
    }
}

/**
 * Simple pace-only chart (without distance)
 */
async function createSimplePaceChart(canvasId, authToken, apiBaseUrl) {
    const canvas = document.getElementById(canvasId);
    if (!canvas) {
        console.error(`Canvas element #${canvasId} not found`);
        return null;
    }

    const ctx = canvas.getContext('2d');

    try {
        // Fetch workouts from API
        const response = await fetch(`${apiBaseUrl}/api/workouts`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${authToken}`,
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) throw new Error('Failed to fetch workouts');

        const workouts = await response.json();

        // Filter to last 30 days
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const recentWorkouts = workouts
            .filter(w => new Date(w.date) >= thirtyDaysAgo)
            .sort((a, b) => new Date(a.date) - new Date(b.date));

        if (recentWorkouts.length === 0) {
            console.warn('No workouts found in last 30 days');
            return null;
        }

        // Convert pace strings to seconds
        const toSeconds = (paceStr) => {
            if (!paceStr) return null;
            const [min, sec] = paceStr.split(':').map(Number);
            return (min || 0) * 60 + (sec || 0);
        };

        // Prepare chart data
        const dates = recentWorkouts.map(w => new Date(w.date).toLocaleDateString());
        const paces = recentWorkouts.map(w => toSeconds(w.pace)).filter(v => v !== null);

        // Create Chart.js instance
        const chart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: dates,
                datasets: [{
                    label: 'Pace (min/km)',
                    data: paces,
                    borderColor: 'rgb(59, 130, 246)',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    borderWidth: 3,
                    tension: 0.4,
                    fill: true,
                    pointRadius: 6,
                    pointBackgroundColor: 'rgb(59, 130, 246)',
                    pointBorderColor: '#fff',
                    pointBorderWidth: 2,
                    pointHoverRadius: 8
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: true,
                        position: 'top'
                    },
                    title: {
                        display: true,
                        text: '30-Day Pace Progression'
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const seconds = context.parsed.y;
                                const min = Math.floor(seconds / 60);
                                const sec = Math.round(seconds % 60);
                                return `Pace: ${min}:${sec.toString().padStart(2, '0')}/km`;
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        reverse: true, // Lower pace is better
                        title: {
                            display: true,
                            text: 'Pace (min/km) - Lower is Better'
                        },
                        ticks: {
                            callback: function(value) {
                                const min = Math.floor(value / 60);
                                const sec = Math.round(value % 60);
                                return `${min}:${sec.toString().padStart(2, '0')}`;
                            }
                        }
                    }
                }
            }
        });

        return chart;
    } catch (error) {
        console.error('Error creating pace chart:', error);
        return null;
    }
}

// Make functions globally available
window.createPaceProgressionChart = createPaceProgressionChart;
window.createSimplePaceChart = createSimplePaceChart;
