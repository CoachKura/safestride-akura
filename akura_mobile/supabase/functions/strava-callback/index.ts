// Supabase Edge Function to handle Strava OAuth callback
// This receives the authorization code from Strava and redirects back to the mobile app

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  // Get the authorization code from query parameters
  const url = new URL(req.url)
  const code = url.searchParams.get('code')
  const error = url.searchParams.get('error')
  const scope = url.searchParams.get('scope')
  
  // Log for debugging
  console.log('Received Strava callback:', { code, error, scope })
  
  // Redirect back to the mobile app using deep link
  let redirectUrl = 'safestride://strava-callback'
  
  if (error) {
    redirectUrl += `?error=${encodeURIComponent(error)}`
  } else if (code) {
    redirectUrl += `?code=${encodeURIComponent(code)}`
    if (scope) {
      redirectUrl += `&scope=${encodeURIComponent(scope)}`
    }
  }
  
  // Return HTML with auto-redirect
  const html = `
    <!DOCTYPE html>
    <html>
      <head>
        <title>Strava Authorization</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-align: center;
            padding: 20px;
          }
          .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 40px;
            border-radius: 20px;
            backdrop-filter: blur(10px);
          }
          h1 { margin: 0 0 20px 0; }
          p { margin: 10px 0; opacity: 0.9; }
          .spinner {
            border: 3px solid rgba(255,255,255,0.3);
            border-top: 3px solid white;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 20px auto;
          }
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
          a {
            color: white;
            text-decoration: none;
            background: rgba(255,255,255,0.2);
            padding: 12px 24px;
            border-radius: 8px;
            display: inline-block;
            margin-top: 20px;
          }
        </style>
        <script>
          // Immediately try to redirect to the app
          window.location.href = '${redirectUrl}';
          
          // Fallback: Show manual link if auto-redirect fails
          setTimeout(() => {
            document.getElementById('manual-link').style.display = 'block';
          }, 2000);
        </script>
      </head>
      <body>
        <div class="container">
          <h1>✅ Authorization Complete</h1>
          <div class="spinner"></div>
          <p>Redirecting back to SafeStride app...</p>
          <div id="manual-link" style="display:none;">
            <p>If the app doesn't open automatically:</p>
            <a href="${redirectUrl}">Open SafeStride App</a>
          </div>
        </div>
      </body>
    </html>
  `
  
  return new Response(html, {
    headers: {
      'Content-Type': 'text/html',
    },
  })
})
