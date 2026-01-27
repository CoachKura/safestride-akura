# Cloudflare Worker Deployment Guide
# Alternative to Nginx - No Server Required!

## Overview
Use Cloudflare Workers to proxy `api.akura.in` → Render backend without managing a VPS.

**Benefits:**
- ✅ No server management
- ✅ Automatic SSL/TLS
- ✅ Global CDN (faster worldwide)
- ✅ Free tier: 100,000 requests/day
- ✅ 5-minute setup

## Prerequisites
- Cloudflare account (free)
- Domain registered at Cloudflare or transferred there
- `akura.in` domain in Cloudflare DNS

## Setup Steps

### 1. Login to Cloudflare
Visit: https://dash.cloudflare.com

### 2. Create Worker
1. Click **Workers & Pages** in left sidebar
2. Click **Create Application** → **Create Worker**
3. Name: `akura-api-proxy`
4. Click **Deploy** (default script)

### 3. Edit Worker Code
1. Click **Edit Code**
2. Delete default code
3. Paste contents from `cloudflare-worker.js`
4. Click **Save and Deploy**

### 4. Add Custom Domain
1. Click **Settings** tab
2. Scroll to **Triggers** section
3. Click **Add Custom Domain**
4. Enter: `api.akura.in`
5. Click **Add Custom Domain**

Cloudflare will:
- Automatically create DNS records
- Provision SSL certificate
- Route `api.akura.in` → your worker

### 5. Verify DNS (Automatic)
Cloudflare handles this automatically. Verify in **DNS** tab:
```
Type: CNAME
Name: api
Target: akura-api-proxy.workers.dev (or similar)
Proxy: Enabled (orange cloud)
```

### 6. Test Endpoints
Wait 1-2 minutes for propagation, then test:

```powershell
# Health check
curl https://api.akura.in/api/health

# Should return Render backend response
```

## Update Frontend .env

Once `api.akura.in` works, update:

```dotenv
VITE_API_BASE_URL=https://api.akura.in/api
VITE_ENABLE_OFFLINE_MODE=false
VITE_LOG_LEVEL=info
```

## Monitoring & Logs

### View Logs
1. Go to **Workers & Pages** → `akura-api-proxy`
2. Click **Logs** tab (real-time)
3. Or use Logpush for historical data

### Metrics
- **Requests:** Dashboard shows request count
- **Errors:** 4xx/5xx breakdown
- **Latency:** P50, P95, P99

## Troubleshooting

### Worker not receiving requests
```bash
# Check DNS
nslookup api.akura.in

# Should show Cloudflare proxy IP (orange cloud)
```

### CORS errors
- Check `allowedOrigins` array in worker
- Add your frontend domain
- Verify Origin header in request

### 522 Connection Timeout
- Render backend may be cold-starting
- Worker timeout is 30 seconds (should be enough)
- Check Render backend logs

### Rate Limiting (100k free requests/day)
If exceeded:
- Upgrade to Workers Paid ($5/month for 10M requests)
- Or add caching:
```javascript
// Add after line 16
const cache = caches.default
const cacheKey = new Request(backendUrl, request)
let response = await cache.match(cacheKey)

if (!response) {
  response = await fetch(modifiedRequest)
  // Cache for 60 seconds
  response.headers.set('Cache-Control', 'public, max-age=60')
  event.waitUntil(cache.put(cacheKey, response.clone()))
}
```

## Advanced: Add /docs Path

To serve API docs at `api.akura.in/docs`:

### Option A: Deploy docs to Cloudflare Pages
1. Run: `cd api-docs && bash ./deploy_api_docs.sh`
2. Deploy `api-docs-deploy` to Cloudflare Pages
3. Modify worker to route `/docs/*` to Pages

### Option B: Serve from R2 (Cloudflare Storage)
1. Upload `api-docs-deploy/*` to R2 bucket
2. Add route in worker:
```javascript
if (url.pathname.startsWith('/docs')) {
  // Serve from R2 or Pages
  const docsUrl = `https://akura-docs.pages.dev${url.pathname.replace('/docs', '')}`
  return fetch(docsUrl)
}
```

## Cost Breakdown

**Free Tier:**
- 100,000 requests/day
- Sufficient for beta launch

**Paid ($5/month):**
- 10 million requests/month
- ~333,000 requests/day
- Recommended for production

## Rollback Plan

If worker has issues, quickly disable:
1. Go to **Custom Domains**
2. Remove `api.akura.in`
3. Update `.env` back to: `https://safestride-backend-cave.onrender.com/api`

## Comparison: Cloudflare vs Nginx

| Feature | Cloudflare Worker | Self-Hosted Nginx |
|---------|------------------|-------------------|
| Setup Time | 5 minutes | 30-60 minutes |
| Cost | Free (100k/day) | $5-10/month VPS |
| Maintenance | Zero | Regular updates |
| SSL | Automatic | Manual (Certbot) |
| Scaling | Automatic | Manual |
| CDN | Global | Single location |
| Best For | Most users | Full control needed |

**Recommendation:** Use Cloudflare Worker unless you need specific Nginx features.

## Support

- Cloudflare Docs: https://developers.cloudflare.com/workers
- Community: https://community.cloudflare.com
- Status: https://www.cloudflarestatus.com
