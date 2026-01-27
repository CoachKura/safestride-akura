// Cloudflare Worker: akura-api-proxy
// Purpose: Proxy api.akura.in → safestride-backend-cave.onrender.com
// Deployed at: api.akura.in (proxies all requests to Render backend)

addEventListener('fetch', event => {
  event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
  const url = new URL(request.url)
  
  // Rewrite URL to Render backend
  const backendUrl = `https://safestride-backend-cave.onrender.com${url.pathname}${url.search}`
  
  // Clone request with new URL and preserve headers
  const modifiedRequest = new Request(backendUrl, {
    method: request.method,
    headers: request.headers,
    body: request.body,
    redirect: 'follow'
  })
  
  // Forward to Render backend
  let response = await fetch(modifiedRequest)
  
  // Clone response to modify headers
  response = new Response(response.body, response)
  
  // Add CORS headers for frontend
  const origin = request.headers.get('Origin')
  const allowedOrigins = [
    'https://akura.in',
    'https://www.akura.in',
    'https://safestride-akura.onrender.com',
    'http://localhost:8080',
    'http://127.0.0.1:8080'
  ]
  
  if (allowedOrigins.includes(origin)) {
    response.headers.set('Access-Control-Allow-Origin', origin)
  } else {
    response.headers.set('Access-Control-Allow-Origin', 'https://akura.in')
  }
  
  response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
  response.headers.set('Access-Control-Allow-Headers', 'Authorization, Content-Type, X-Request-Id, X-Client-Id, Idempotency-Key')
  response.headers.set('Access-Control-Expose-Headers', 'X-RateLimit-Limit, X-RateLimit-Remaining, X-Request-Id')
  response.headers.set('Access-Control-Allow-Credentials', 'true')
  response.headers.set('Access-Control-Max-Age', '86400')
  
  // Handle preflight OPTIONS requests
  if (request.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: response.headers
    })
  }
  
  // Add security headers
  response.headers.set('X-Content-Type-Options', 'nosniff')
  response.headers.set('X-Frame-Options', 'DENY')
  response.headers.set('X-XSS-Protection', '1; mode=block')
  
  return response
}
