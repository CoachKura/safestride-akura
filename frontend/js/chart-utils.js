/* =============================================================================
   AKURA CHART-UTILS.JS - Chart.js Utilities & Visualization Helpers
   ============================================================================= */

/**
 * Render AIFRI Donut Chart with 6-Pillar Breakdown
 */
function renderAIFRIDonutChart(canvasId, aifriResult) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) {
    console.error(`Canvas element with ID "${canvasId}" not found`);
    return null;
  }

  // Destroy existing chart if it exists
  if (window.aifriBartChart) {
    window.aifriBartChart.destroy();
  }

  const ctx = canvas.getContext('2d');
  const pillars = aifriResult.pillars;

  const chartData = {
    labels: [
      `Running (40%)`,
      `Strength (15%)`,
      `ROM (12%)`,
      `Balance (13%)`,
      `Mobility (10%)`,
      `Alignment (10%)`
    ],
    datasets: [
      {
        data: [
          pillars.running,
          pillars.strength,
          pillars.rom,
          pillars.balance,
          pillars.mobility,
          pillars.alignment
        ],
        backgroundColor: [
          '#1e3a5f', // Navy - Running
          '#ff8c42', // Orange - Strength
          '#33BEF3', // Teal - ROM
          '#4caf50', // Green - Balance
          '#9c27b0', // Purple - Mobility
          '#e74c3c'  // Red - Alignment
        ],
        borderColor: 'white',
        borderWidth: 3,
        borderRadius: 8
      }
    ]
  };

  const options = {
    responsive: true,
    maintainAspectRatio: true,
    cutout: '65%',
    plugins: {
      legend: {
        position: 'bottom',
        labels: {
          font: {
            family: '"Open Sans", sans-serif',
            size: 14,
            weight: '600'
          },
          padding: 15,
          usePointStyle: true,
          pointStyle: 'circle',
          color: '#333'
        }
      },
      tooltip: {
        backgroundColor: 'rgba(0, 0, 0, 0.8)',
        padding: 12,
        titleFont: { size: 14, weight: 'bold' },
        bodyFont: { size: 12 },
        borderColor: '#33BEF3',
        borderWidth: 2,
        callbacks: {
          label: (context) => {
            const value = context.parsed || 0;
            return `${value}/100 points`;
          }
        }
      },
      datalabels: {
        color: 'white',
        font: {
          weight: 'bold',
          size: 12
        },
        formatter: (value) => `${value}`,
        align: 'center',
        anchor: 'center'
      }
    }
  };

  // Create the chart
  window.aifriBartChart = new Chart(ctx, {
    type: 'doughnut',
    data: chartData,
    options: options,
    plugins: [
      {
        id: 'centerText',
        beforeDraw(chart) {
          const ctx = chart.ctx;
          const { width, height, chartArea } = chart;
          const centerX = chartArea.left + chartArea.width / 2;
          const centerY = chartArea.top + chartArea.height / 2;

          ctx.save();

          // Draw score
          ctx.font = 'bold 48px "Open Sans"';
          ctx.fillStyle = '#1e3a5f';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(aifriResult.total, centerX, centerY - 15);

          // Draw grade label
          ctx.font = 'semibold 16px "Open Sans"';
          ctx.fillStyle = aifriResult.grade.color;
          ctx.fillText(aifriResult.grade.label, centerX, centerY + 20);

          ctx.restore();
        }
      }
    ]
  });

  return window.aifriBartChart;
}

/**
 * Render Weekly AIFRI Trend Chart (Line Chart)
 */
function renderWeeklyTrendChart(canvasId, weeklyData) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) {
    console.error(`Canvas element with ID "${canvasId}" not found`);
    return null;
  }

  if (window.weeklyTrendChart) {
    window.weeklyTrendChart.destroy();
  }

  const ctx = canvas.getContext('2d');

  const chartData = {
    labels: weeklyData.map(w => `Week ${w.week}`),
    datasets: [
      {
        label: 'Running',
        data: weeklyData.map(w => w.running),
        borderColor: '#1e3a5f',
        backgroundColor: 'rgba(30, 58, 95, 0.1)',
        tension: 0.4,
        fill: true,
        pointBackgroundColor: '#1e3a5f',
        pointBorderColor: 'white',
        pointBorderWidth: 2,
        pointRadius: 4
      },
      {
        label: 'Strength',
        data: weeklyData.map(w => w.strength),
        borderColor: '#ff8c42',
        backgroundColor: 'rgba(255, 140, 66, 0.1)',
        tension: 0.4,
        fill: false,
        pointBackgroundColor: '#ff8c42',
        pointBorderColor: 'white',
        pointBorderWidth: 2,
        pointRadius: 4
      },
      {
        label: 'ROM',
        data: weeklyData.map(w => w.rom),
        borderColor: '#33BEF3',
        backgroundColor: 'rgba(51, 190, 243, 0.1)',
        tension: 0.4,
        fill: false,
        pointBackgroundColor: '#33BEF3',
        pointBorderColor: 'white',
        pointBorderWidth: 2,
        pointRadius: 4
      },
      {
        label: 'Balance',
        data: weeklyData.map(w => w.balance),
        borderColor: '#4caf50',
        backgroundColor: 'rgba(76, 175, 80, 0.1)',
        tension: 0.4,
        fill: false,
        pointBackgroundColor: '#4caf50',
        pointBorderColor: 'white',
        pointBorderWidth: 2,
        pointRadius: 4
      }
    ]
  };

  const options = {
    responsive: true,
    maintainAspectRatio: true,
    plugins: {
      legend: {
        position: 'top',
        labels: {
          font: { size: 12, weight: '600' },
          padding: 15,
          usePointStyle: true
        }
      },
      tooltip: {
        backgroundColor: 'rgba(0, 0, 0, 0.8)',
        padding: 12,
        callbacks: {
          label: (context) => `${context.dataset.label}: ${context.parsed.y.toFixed(0)}/100`
        }
      }
    },
    scales: {
      y: {
        min: 0,
        max: 100,
        beginAtZero: true,
        grid: {
          color: 'rgba(0, 0, 0, 0.05)'
        },
        ticks: {
          callback: (value) => `${value}%`
        }
      },
      x: {
        grid: {
          display: false
        }
      }
    }
  };

  window.weeklyTrendChart = new Chart(ctx, {
    type: 'line',
    data: chartData,
    options: options
  });

  return window.weeklyTrendChart;
}

/**
 * Render Comparison Bar Chart (Athlete vs Standard)
 */
function renderComparisonChart(canvasId, athleteData, standardData) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) {
    console.error(`Canvas element with ID "${canvasId}" not found`);
    return null;
  }

  if (window.comparisonChart) {
    window.comparisonChart.destroy();
  }

  const ctx = canvas.getContext('2d');

  const chartData = {
    labels: ['Running', 'Strength', 'ROM', 'Balance', 'Mobility', 'Alignment'],
    datasets: [
      {
        label: 'Your Score',
        data: [
          athleteData.running,
          athleteData.strength,
          athleteData.rom,
          athleteData.balance,
          athleteData.mobility,
          athleteData.alignment
        ],
        backgroundColor: '#33BEF3',
        borderRadius: 6,
        borderSkipped: false
      },
      {
        label: 'Category Average',
        data: [
          standardData.running,
          standardData.strength,
          standardData.rom,
          standardData.balance,
          standardData.mobility,
          standardData.alignment
        ],
        backgroundColor: '#d0d0d0',
        borderRadius: 6,
        borderSkipped: false
      }
    ]
  };

  const options = {
    responsive: true,
    maintainAspectRatio: true,
    indexAxis: 'y',
    plugins: {
      legend: {
        position: 'bottom',
        labels: {
          font: { size: 12, weight: '600' },
          padding: 15
        }
      },
      tooltip: {
        callbacks: {
          label: (context) => `${context.dataset.label}: ${context.parsed.x.toFixed(0)}/100`
        }
      }
    },
    scales: {
      x: {
        min: 0,
        max: 100,
        ticks: {
          callback: (value) => `${value}`
        }
      }
    }
  };

  window.comparisonChart = new Chart(ctx, {
    type: 'bar',
    data: chartData,
    options: options
  });

  return window.comparisonChart;
}

/**
 * Render Progress Gauge Chart
 */
function renderProgressGauge(canvasId, score, target) {
  const canvas = document.getElementById(canvasId);
  if (!canvas) {
    console.error(`Canvas element with ID "${canvasId}" not found`);
    return null;
  }

  if (window.gaugeChart) {
    window.gaugeChart.destroy();
  }

  const ctx = canvas.getContext('2d');
  const percentage = (score / target) * 100;

  const chartData = {
    labels: ['Progress', 'Remaining'],
    datasets: [
      {
        data: [percentage, 100 - percentage],
        backgroundColor: ['#33BEF3', '#e0e0e0'],
        borderColor: 'white',
        borderWidth: 3
      }
    ]
  };

  const options = {
    responsive: true,
    maintainAspectRatio: true,
    cutout: '70%',
    plugins: {
      legend: {
        display: false
      },
      tooltip: {
        callbacks: {
          label: (context) => `${context.parsed}%`
        }
      }
    }
  };

  window.gaugeChart = new Chart(ctx, {
    type: 'doughnut',
    data: chartData,
    options: options,
    plugins: [
      {
        id: 'gaugeText',
        beforeDraw(chart) {
          const ctx = chart.ctx;
          const { chartArea } = chart;
          const centerX = chartArea.left + chartArea.width / 2;
          const centerY = chartArea.top + chartArea.height / 2;

          ctx.save();
          ctx.font = 'bold 36px "Open Sans"';
          ctx.fillStyle = '#33BEF3';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(`${Math.round(percentage)}%`, centerX, centerY);
          ctx.restore();
        }
      }
    ]
  });

  return window.gaugeChart;
}

/**
 * Update chart data (for real-time updates)
 */
function updateChartData(chart, newData) {
  if (!chart) return;

  chart.data.datasets[0].data = newData;
  chart.update();
}

/**
 * Destroy chart instance
 */
function destroyChart(chart) {
  if (chart) {
    chart.destroy();
  }
}

/**
 * Generate color for a pillar based on value
 */
function getPillarColor(pillarName, value) {
  const colors = {
    running: '#1e3a5f',
    strength: '#ff8c42',
    rom: '#33BEF3',
    balance: '#4caf50',
    mobility: '#9c27b0',
    alignment: '#e74c3c'
  };

  return colors[pillarName] || '#666';
}

/**
 * Format number as percentage
 */
function formatPercentage(value, decimals = 0) {
  return `${value.toFixed(decimals)}%`;
}

/**
 * Export for use in modules
 */
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    renderAIFRIDonutChart,
    renderWeeklyTrendChart,
    renderComparisonChart,
    renderProgressGauge,
    updateChartData,
    destroyChart,
    getPillarColor,
    formatPercentage
  };
}
