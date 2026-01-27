# Netlify Deployment Guide
# AKURA SafeStride Frontend

## Quick Deploy (2 minutes)

### Option A: Netlify Dashboard (Easiest)

1. **Login to Netlify**
   - Visit: https://app.netlify.com
   - Click **Add new site** → **Import an existing project**

2. **Connect GitHub**
   - Select **GitHub**
   - Authorize Netlify
   - Choose repo: `CoachKura/safestride-akura`

3. **Configure Build Settings**
   - Base directory: `.` (root)
   - Build command: (leave empty)
   - Publish directory: `frontend`
   - Click **Deploy site**

4. **Wait for Deployment** (30-60 seconds)
   - Netlify auto-detects `netlify.toml`
   - Builds and deploys automatically
   - Generates URL: `https://random-name-123.netlify.app`

5. **Custom Domain** (Optional)
   - Click **Domain settings**
   - Click **Add custom domain**
   - Enter: `akura.in` or `www.akura.in`
   - Follow DNS instructions

### Option B: Netlify CLI (Fast)

```powershell
# Install CLI globally
npm install -g netlify-cli

# Login
netlify login

# Deploy from root directory
cd "E:\Akura Safe Stride\safestride"
netlify deploy --prod

# Follow prompts:
# - Create new site? Yes
# - Publish directory: frontend
```

Your site will be live at: `https://your-site.netlify.app`

## Features Included in netlify.toml

✅ **Backend Proxy**: `/api/*` → Render backend  
✅ **Security Headers**: HSTS, CSP, X-Frame-Options  
✅ **Asset Caching**: CSS/JS cached for 1 year  
✅ **SPA Routing**: Client-side routes work  
✅ **Environment Variables**: Auto-injected from config  

## Testing After Deployment

```powershell
# Test frontend
curl -I https://your-site.netlify.app

# Test API proxy
curl https://your-site.netlify.app/api/health

# Should return Render backend response
```

## Custom Domain Setup

### Add Domain in Netlify

1. **Domain Settings** → **Add custom domain**
2. Enter: `akura.in`
3. Netlify provides DNS records

### Configure DNS (at your registrar)

Add these records:
```
Type: A
Host: @
Value: 75.2.60.5 (Netlify's load balancer)

Type: CNAME
Host: www
Value: your-site.netlify.app
```

Or use Netlify DNS:
```
Nameserver 1: dns1.p04.nsone.net
Nameserver 2: dns2.p04.nsone.net
Nameserver 3: dns3.p04.nsone.net
Nameserver 4: dns4.p04.nsone.net
```

### Enable HTTPS (Automatic)

1. **Domain settings** → **HTTPS**
2. Click **Verify DNS configuration**
3. Click **Provision certificate** (auto via Let's Encrypt)
4. Wait 5-10 minutes for propagation

## Environment Variables (UI Method)

If you need to override `.env` values:

1. **Site settings** → **Build & deploy** → **Environment**
2. Click **Add variable**
3. Add:
   - `VITE_API_BASE_URL` = `https://safestride-backend-cave.onrender.com/api`
   - `VITE_ENABLE_OFFLINE_MODE` = `false`
   - `VITE_LOG_LEVEL` = `info`

## Continuous Deployment

Once connected to GitHub:
- Every push to `main` triggers auto-deploy
- Pull requests get preview URLs
- Rollback to previous deploy in 1 click

## Monitoring

### Analytics (Built-in)
- **Site overview** → **Analytics**
- Page views, bandwidth, forms

### Real User Monitoring
```html
<!-- Already included if using Netlify Analytics -->
<script defer src="https://analytics.netlify.com/script.js"></script>
```

### Build Logs
- **Deploys** tab shows each build
- Click any deploy to see logs
- Debug build failures here

## Troubleshooting

### Build Failed
```
Error: Cannot find frontend directory
```
**Fix**: Check `netlify.toml` → `publish = "frontend"`

### API Calls Not Working
```
Error: CORS or 404
```
**Fix**: Verify redirect in `netlify.toml`:
```toml
[[redirects]]
  from = "/api/*"
  to = "https://safestride-backend-cave.onrender.com/api/:splat"
  status = 200
  force = true
```

### Custom Domain Not Working
```
DNS_PROBE_FINISHED_NXDOMAIN
```
**Fix**: 
- Wait 15-60 minutes for DNS propagation
- Check DNS records: `nslookup akura.in`
- Use Netlify DNS for faster setup

### 404 on Page Refresh
```
Page not found on /assessment-intake
```
**Fix**: Already handled by SPA fallback in `netlify.toml`:
```toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

## Comparison: Netlify vs Render vs Cloudflare

| Feature | Netlify | Render | Cloudflare Pages |
|---------|---------|--------|------------------|
| Setup | 2 min | 5 min | 3 min |
| Free Tier | 100GB/month | 100GB/month | Unlimited |
| Build Minutes | 300/month | 500/month | 500/month |
| Custom Domain | ✅ Free | ✅ Free | ✅ Free |
| API Proxy | ✅ Redirects | ❌ Separate service | ✅ Workers |
| Analytics | ✅ Built-in | ✅ Built-in | ✅ Built-in |
| Best For | **All-in-one** | Containers | Global CDN |

**Recommendation**: Use Netlify for fastest setup with built-in API proxy.

## Cost (Free Tier)

- **Bandwidth**: 100GB/month (sufficient for 50k+ visits)
- **Build minutes**: 300/month (enough for daily deploys)
- **Upgrade**: $19/month if exceeded

## Rollback

If deployment fails, rollback in 1 click:
1. **Deploys** tab
2. Find last working deploy
3. Click **⋮** → **Publish deploy**

## Next Steps

After successful deployment:
1. Update `.env` if needed (or use Netlify env vars)
2. Test all pages and API calls
3. Run Lighthouse audit
4. Send test link to 5-10 users
5. Add custom domain when ready

## Support

- Docs: https://docs.netlify.com
- Community: https://answers.netlify.com
- Status: https://www.netlifystatus.com
