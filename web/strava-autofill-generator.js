/**
 * SafeStride Strava Auto-Fill Generator
 * Programmatically generates Strava-style pages with all fields populated
 * Integrates with SafeStride authentication and role-based access
 */

class StravaAutoFillGenerator {
  constructor() {
    this.baseAssets = {
      css: [
        "https://d3nn82uaxijpm6.cloudfront.net/assets/strava-app-icons-7d41623e38c3a1a0947c9b1f49e22497.css",
        "https://d3nn82uaxijpm6.cloudfront.net/assets/application-81dcdbd7f0c3e7a1a36e4090f5c1b3c1.css",
      ],
      js: [
        "https://d3nn82uaxijpm6.cloudfront.net/packs/js/runtime-d5723e3ff5db5c0f8ca4.js",
        "https://d3nn82uaxijpm6.cloudfront.net/packs/js/vendor-d5723e3ff5db5c0f8ca4.js",
        "https://d3nn82uaxijpm6.cloudfront.net/packs/js/application-d5723e3ff5db5c0f8ca4.js",
      ],
    };

    this.supabaseUrl = "https://bdisppaxbvygsspcuymb.supabase.co";
    this.supabaseKey =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJkaXNwcGF4YnZ5Z3NzcGN1eW1iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY4MjM4OTEsImV4cCI6MjA1MjM5OTg5MX0.4vYk5u3AijkkNMB0JxFy0t2dNUPPGS8BnpWCym_hl_w";
  }

  /**
   * Generate complete Strava-style page with auto-filled data
   */
  async generatePage(athleteData, options = {}) {
    const { pageType = "profile", role = "athlete", autoFill = true } = options;

    const template = this.getPageTemplate(pageType);
    const filledData = autoFill
      ? await this.autoFillFields(athleteData, pageType)
      : {};

    return this.renderPage(template, filledData, role);
  }

  /**
   * Get page template based on type
   */
  getPageTemplate(pageType) {
    const templates = {
      profile: this.getProfileTemplate(),
      activities: this.getActivitiesTemplate(),
      training: this.getTrainingTemplate(),
      settings: this.getSettingsTemplate(),
    };

    return templates[pageType] || templates.profile;
  }

  /**
   * Auto-fill all required fields from athlete data
   */
  async autoFillFields(athleteData, pageType) {
    const filled = {
      athlete: {},
      strava: {},
      aisri: {},
      computed: {},
    };

    // Get athlete info from SafeStride auth
    if (athleteData.uid) {
      filled.athlete = await this.getAthleteInfo(athleteData.uid);
    }

    // Get Strava data if connected
    if (filled.athlete && filled.athlete.strava_connected) {
      filled.strava = await this.getStravaData(athleteData.uid);
    }

    // Get AISRI scores
    filled.aisri = await this.getAISRIScores(athleteData.uid);

    // Compute derived fields
    filled.computed = this.computeFields(filled);

    return filled;
  }

  /**
   * Get athlete info from SafeStride database
   */
  async getAthleteInfo(uid) {
    try {
      const response = await fetch(
        `${this.supabaseUrl}/rest/v1/profiles?uid=eq.${uid}&select=*`,
        {
          headers: {
            apikey: this.supabaseKey,
            Authorization: `Bearer ${sessionStorage.getItem("session_token")}`,
          },
        },
      );

      if (!response.ok) return null;
      const data = await response.json();
      return data[0] || null;
    } catch (error) {
      console.error("Error fetching athlete info:", error);
      return null;
    }
  }

  /**
   * Get Strava connection and activity data
   */
  async getStravaData(uid) {
    try {
      // Get Strava connection
      const connResponse = await fetch(
        `${this.supabaseUrl}/rest/v1/strava_connections?athlete_id=eq.${uid}&select=*`,
        {
          headers: {
            apikey: this.supabaseKey,
            Authorization: `Bearer ${sessionStorage.getItem("session_token")}`,
          },
        },
      );

      if (!connResponse.ok) return null;
      const connections = await connResponse.json();
      const connection = connections[0];

      if (!connection) return null;

      // Get recent activities
      const activitiesResponse = await fetch(
        `${this.supabaseUrl}/rest/v1/strava_activities?athlete_id=eq.${uid}&order=created_at.desc&limit=10`,
        {
          headers: {
            apikey: this.supabaseKey,
            Authorization: `Bearer ${sessionStorage.getItem("session_token")}`,
          },
        },
      );

      const activities = activitiesResponse.ok
        ? await activitiesResponse.json()
        : [];

      return {
        connection,
        activities,
        athlete_data: connection.athlete_data,
      };
    } catch (error) {
      console.error("Error fetching Strava data:", error);
      return null;
    }
  }

  /**
   * Get AISRI scores
   */
  async getAISRIScores(uid) {
    try {
      const response = await fetch(
        `${this.supabaseUrl}/rest/v1/aisri_scores?athlete_id=eq.${uid}&order=assessment_date.desc&limit=1`,
        {
          headers: {
            apikey: this.supabaseKey,
            Authorization: `Bearer ${sessionStorage.getItem("session_token")}`,
          },
        },
      );

      if (!response.ok) return null;
      const scores = await response.json();
      return scores[0] || null;
    } catch (error) {
      console.error("Error fetching AISRI scores:", error);
      return null;
    }
  }

  /**
   * Compute derived fields
   */
  computeFields(data) {
    const computed = {
      totalActivities: 0,
      totalDistance: 0,
      totalTime: 0,
      averagePace: 0,
      recentForm: "Good",
      riskLevel: "Low",
      nextMilestone: null,
    };

    // Calculate from Strava activities
    if (data.strava && data.strava.activities) {
      const activities = data.strava.activities;
      computed.totalActivities = activities.length;

      activities.forEach((activity) => {
        const actData = activity.activity_data || {};
        computed.totalDistance += (actData.distance || 0) / 1000; // Convert to km
        computed.totalTime += (actData.moving_time || 0) / 60; // Convert to minutes
      });

      if (computed.totalDistance > 0 && computed.totalTime > 0) {
        computed.averagePace = computed.totalTime / computed.totalDistance; // min/km
      }
    }

    // Determine form based on AISRI
    if (data.aisri) {
      const score = data.aisri.total_score || 0;
      computed.riskLevel = data.aisri.risk_category || "Unknown";

      if (score >= 75) computed.recentForm = "Excellent";
      else if (score >= 55) computed.recentForm = "Good";
      else if (score >= 35) computed.recentForm = "Fair";
      else computed.recentForm = "Poor";
    }

    return computed;
  }

  /**
   * Render complete page with filled data
   */
  renderPage(template, data, role) {
    let html = template;

    // Replace placeholders with actual data
    html = html.replace(
      /\{\{athlete\.name\}\}/g,
      data.athlete?.full_name || "Athlete",
    );
    html = html.replace(/\{\{athlete\.uid\}\}/g, data.athlete?.uid || "");
    html = html.replace(/\{\{athlete\.email\}\}/g, data.athlete?.email || "");
    html = html.replace(/\{\{athlete\.phone\}\}/g, data.athlete?.phone || "");

    // Strava data
    html = html.replace(
      /\{\{strava\.username\}\}/g,
      data.strava?.athlete_data?.username || "Not connected",
    );
    html = html.replace(
      /\{\{strava\.profile_url\}\}/g,
      data.strava?.athlete_data?.profile || "#",
    );
    html = html.replace(
      /\{\{strava\.avatar\}\}/g,
      data.strava?.athlete_data?.profile_medium || "/assets/default-avatar.png",
    );

    // AISRI scores
    html = html.replace(/\{\{aisri\.total\}\}/g, data.aisri?.total_score || 0);
    html = html.replace(
      /\{\{aisri\.risk\}\}/g,
      data.aisri?.risk_category || "Unknown",
    );
    html = html.replace(
      /\{\{aisri\.running\}\}/g,
      data.aisri?.pillar_scores?.running || 0,
    );
    html = html.replace(
      /\{\{aisri\.strength\}\}/g,
      data.aisri?.pillar_scores?.strength || 0,
    );
    html = html.replace(
      /\{\{aisri\.rom\}\}/g,
      data.aisri?.pillar_scores?.rom || 0,
    );
    html = html.replace(
      /\{\{aisri\.balance\}\}/g,
      data.aisri?.pillar_scores?.balance || 0,
    );
    html = html.replace(
      /\{\{aisri\.alignment\}\}/g,
      data.aisri?.pillar_scores?.alignment || 0,
    );
    html = html.replace(
      /\{\{aisri\.mobility\}\}/g,
      data.aisri?.pillar_scores?.mobility || 0,
    );

    // Computed fields
    html = html.replace(
      /\{\{computed\.totalActivities\}\}/g,
      data.computed?.totalActivities || 0,
    );
    html = html.replace(
      /\{\{computed\.totalDistance\}\}/g,
      (data.computed?.totalDistance || 0).toFixed(1),
    );
    html = html.replace(
      /\{\{computed\.totalTime\}\}/g,
      Math.round(data.computed?.totalTime || 0),
    );
    html = html.replace(
      /\{\{computed\.averagePace\}\}/g,
      this.formatPace(data.computed?.averagePace || 0),
    );
    html = html.replace(
      /\{\{computed\.recentForm\}\}/g,
      data.computed?.recentForm || "Unknown",
    );
    html = html.replace(
      /\{\{computed\.riskLevel\}\}/g,
      data.computed?.riskLevel || "Unknown",
    );

    // Add role-specific content
    html = this.addRoleContent(html, role);

    return html;
  }

  /**
   * Format pace (min/km)
   */
  formatPace(pace) {
    if (pace === 0) return "--:--";
    const minutes = Math.floor(pace);
    const seconds = Math.round((pace - minutes) * 60);
    return `${minutes}:${seconds.toString().padStart(2, "0")}`;
  }

  /**
   * Add role-specific content
   */
  addRoleContent(html, role) {
    const roleIndicators = {
      admin: '<div class="role-badge bg-red-600">Admin</div>',
      coach: '<div class="role-badge bg-blue-600">Coach</div>',
      athlete: '<div class="role-badge bg-green-600">Athlete</div>',
    };

    html = html.replace("</header>", `${roleIndicators[role] || ""}</header>`);
    return html;
  }

  /**
   * Profile page template
   */
  getProfileTemplate() {
    return `<!DOCTYPE html>
<html class="logged-in" lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SafeStride - Athlete Profile</title>
    
    <!-- Strava Assets -->
    ${this.baseAssets.css.map((url) => `<link rel="stylesheet" href="${url}">`).join("\n    ")}
    
    <!-- Tailwind CSS -->
    <script src="https://cdn.tailwindcss.com"></script>
    
    <style>
        .role-badge {
            position: fixed;
            top: 20px;
            right: 20px;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-weight: bold;
            z-index: 1000;
            box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        }
        
        .stat-card {
            background: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            transition: transform 0.2s;
        }
        
        .stat-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
        }
        
        .pillar-score {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 16px;
            background: #f8f9fa;
            border-radius: 8px;
            margin-bottom: 12px;
        }
        
        .score-bar {
            height: 8px;
            background: #e9ecef;
            border-radius: 4px;
            overflow: hidden;
            flex-grow: 1;
            margin: 0 16px;
        }
        
        .score-fill {
            height: 100%;
            transition: width 0.3s ease;
        }
        
        .risk-low { background: #28a745; }
        .risk-medium { background: #ffc107; }
        .risk-high { background: #fd7e14; }
        .risk-critical { background: #dc3545; }
    </style>
</head>
<body class="bg-gray-50">
    <header class="bg-white border-b border-gray-200 sticky top-0 z-50">
        <div class="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
            <div class="flex items-center space-x-4">
                <img src="{{strava.avatar}}" alt="Profile" class="w-12 h-12 rounded-full">
                <div>
                    <h1 class="text-xl font-bold text-gray-900">{{athlete.name}}</h1>
                    <p class="text-sm text-gray-600">{{athlete.uid}}</p>
                </div>
            </div>
            <nav class="flex space-x-6">
                <a href="/dashboard.html" class="text-gray-700 hover:text-gray-900">Dashboard</a>
                <a href="/training-plan-builder.html" class="text-gray-700 hover:text-gray-900">Training</a>
                <a href="/strava-profile.html" class="text-orange-600 font-semibold">Profile</a>
                <button onclick="logout()" class="text-red-600 hover:text-red-700">Logout</button>
            </nav>
        </div>
    </header>

    <main class="max-w-7xl mx-auto px-4 py-8">
        <!-- AISRI Score Card -->
        <div class="stat-card mb-8">
            <div class="flex items-center justify-between mb-6">
                <h2 class="text-2xl font-bold text-gray-900">AISRI Score</h2>
                <div class="text-right">
                    <div class="text-4xl font-bold text-gray-900">{{aisri.total}}</div>
                    <div class="text-sm text-gray-600">Risk: <span class="font-semibold">{{aisri.risk}}</span></div>
                </div>
            </div>
            
            <!-- Six Pillars -->
            <div class="space-y-3">
                <div class="pillar-score">
                    <span class="font-semibold text-gray-700 w-32">Running</span>
                    <div class="score-bar">
                        <div class="score-fill bg-blue-500" style="width: {{aisri.running}}%"></div>
                    </div>
                    <span class="font-bold text-gray-900 w-12 text-right">{{aisri.running}}</span>
                </div>
                
                <div class="pillar-score">
                    <span class="font-semibold text-gray-700 w-32">Strength</span>
                    <div class="score-bar">
                        <div class="score-fill bg-purple-500" style="width: {{aisri.strength}}%"></div>
                    </div>
                    <span class="font-bold text-gray-900 w-12 text-right">{{aisri.strength}}</span>
                </div>
                
                <div class="pillar-score">
                    <span class="font-semibold text-gray-700 w-32">ROM</span>
                    <div class="score-bar">
                        <div class="score-fill bg-green-500" style="width: {{aisri.rom}}%"></div>
                    </div>
                    <span class="font-bold text-gray-900 w-12 text-right">{{aisri.rom}}</span>
                </div>
                
                <div class="pillar-score">
                    <span class="font-semibold text-gray-700 w-32">Balance</span>
                    <div class="score-bar">
                        <div class="score-fill bg-yellow-500" style="width: {{aisri.balance}}%"></div>
                    </div>
                    <span class="font-bold text-gray-900 w-12 text-right">{{aisri.balance}}</span>
                </div>
                
                <div class="pillar-score">
                    <span class="font-semibold text-gray-700 w-32">Alignment</span>
                    <div class="score-bar">
                        <div class="score-fill bg-orange-500" style="width: {{aisri.alignment}}%"></div>
                    </div>
                    <span class="font-bold text-gray-900 w-12 text-right">{{aisri.alignment}}</span>
                </div>
                
                <div class="pillar-score">
                    <span class="font-semibold text-gray-700 w-32">Mobility</span>
                    <div class="score-bar">
                        <div class="score-fill bg-pink-500" style="width: {{aisri.mobility}}%"></div>
                    </div>
                    <span class="font-bold text-gray-900 w-12 text-right">{{aisri.mobility}}</span>
                </div>
            </div>
        </div>

        <!-- Activity Stats -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <div class="stat-card">
                <div class="text-sm text-gray-600 mb-2">Total Activities</div>
                <div class="text-3xl font-bold text-gray-900">{{computed.totalActivities}}</div>
            </div>
            
            <div class="stat-card">
                <div class="text-sm text-gray-600 mb-2">Total Distance</div>
                <div class="text-3xl font-bold text-gray-900">{{computed.totalDistance}} <span class="text-lg">km</span></div>
            </div>
            
            <div class="stat-card">
                <div class="text-sm text-gray-600 mb-2">Average Pace</div>
                <div class="text-3xl font-bold text-gray-900">{{computed.averagePace}} <span class="text-lg">/km</span></div>
            </div>
            
            <div class="stat-card">
                <div class="text-sm text-gray-600 mb-2">Recent Form</div>
                <div class="text-3xl font-bold text-gray-900">{{computed.recentForm}}</div>
            </div>
        </div>

        <!-- Strava Connection -->
        <div class="stat-card">
            <h3 class="text-lg font-bold text-gray-900 mb-4">Strava Connection</h3>
            <div class="flex items-center justify-between">
                <div class="flex items-center space-x-4">
                    <img src="{{strava.avatar}}" alt="Strava" class="w-16 h-16 rounded-full">
                    <div>
                        <div class="font-semibold text-gray-900">{{strava.username}}</div>
                        <a href="{{strava.profile_url}}" target="_blank" class="text-sm text-orange-600 hover:text-orange-700">
                            View on Strava →
                        </a>
                    </div>
                </div>
                <button onclick="syncStrava()" class="px-6 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition">
                    Sync Activities
                </button>
            </div>
        </div>

        <!-- Contact Info -->
        <div class="stat-card mt-8">
            <h3 class="text-lg font-bold text-gray-900 mb-4">Contact Information</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                    <label class="block text-sm text-gray-600 mb-1">Email</label>
                    <div class="text-gray-900 font-medium">{{athlete.email}}</div>
                </div>
                <div>
                    <label class="block text-sm text-gray-600 mb-1">Phone</label>
                    <div class="text-gray-900 font-medium">{{athlete.phone}}</div>
                </div>
            </div>
        </div>
    </main>

    <!-- Scripts -->
    ${this.baseAssets.js.map((url) => `<script src="${url}"></script>`).join("\n    ")}
    
    <script src="/strava-autofill-generator.js"></script>
    <script>
        // Initialize on page load
        document.addEventListener('DOMContentLoaded', async () => {
            const generator = new StravaAutoFillGenerator();
            
            // Get current athlete from session
            const session = JSON.parse(sessionStorage.getItem('safestride_session') || '{}');
            if (!session.uid) {
                window.location.href = '/login.html';
                return;
            }

            // Auto-fill page
            const athleteData = { uid: session.uid };
            const filledHtml = await generator.generatePage(athleteData, {
                pageType: 'profile',
                role: session.role,
                autoFill: true
            });

            // Replace body content (keeping scripts)
            const parser = new DOMParser();
            const doc = parser.parseFromString(filledHtml, 'text/html');
            document.body.replaceChildren(...doc.body.childNodes);
        });

        async function syncStrava() {
            const session = JSON.parse(sessionStorage.getItem('safestride_session') || '{}');
            
            try {
                const response = await fetch('https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/strava-sync-activities', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': \`Bearer \${session.token}\`
                    },
                    body: JSON.stringify({ athlete_id: session.uid })
                });

                if (response.ok) {
                    alert('Activities synced successfully!');
                    location.reload();
                } else {
                    alert('Failed to sync activities');
                }
            } catch (error) {
                console.error('Sync error:', error);
                alert('Error syncing activities');
            }
        }

        function logout() {
            sessionStorage.clear();
            window.location.href = '/login.html';
        }
    </script>
</body>
</html>`;
  }

  /**
   * Activities page template
   */
  getActivitiesTemplate() {
    return `<!-- Similar structure for activities list -->`;
  }

  /**
   * Training page template
   */
  getTrainingTemplate() {
    return `<!-- Similar structure for training plans -->`;
  }

  /**
   * Settings page template
   */
  getSettingsTemplate() {
    return `<!-- Similar structure for settings -->`;
  }
}

// Export for use in other modules
if (typeof module !== "undefined" && module.exports) {
  module.exports = StravaAutoFillGenerator;
}
