# AKURA SafeStride - API Documentation Deployment Guide

This guide provides instructions for hosting the OpenAPI documentation at `api.akura.in/docs` using various deployment methods.

---

## 📦 Deliverables Generated

1. **AKURA_API_Collection.postman.json** - Postman collection with all endpoints
2. **AKURA_API_Spec.yaml** - OpenAPI 3.0 specification
3. **DEPLOY_API_DOCS.md** - This deployment guide

---

## 🚀 Deployment Options

### Option 1: Swagger UI (Recommended for Quick Setup)

**Best for:** Quick deployment, free hosting, no infrastructure needed

#### Step 1: Host YAML on GitHub Pages

1. Create a public GitHub repository (e.g., `akura-api-docs`)
2. Add `AKURA_API_Spec.yaml` to the repository
3. Enable GitHub Pages in repository settings
4. Access at: `https://<username>.github.io/akura-api-docs/AKURA_API_Spec.yaml`

#### Step 2: Use Swagger UI Online

Visit: https://petstore.swagger.io/

In the top bar, paste your YAML URL:
```
https://<username>.github.io/akura-api-docs/AKURA_API_Spec.yaml
```

**Pros:**
- ✅ Free
- ✅ No server required
- ✅ Interactive "Try It Out" buttons
- ✅ Instant updates (just push to GitHub)

**Cons:**
- ❌ Not your custom domain (api.akura.in)
- ❌ Depends on external service

---

### Option 2: Self-Hosted Swagger UI (Custom Domain)

**Best for:** Professional setup with custom domain (api.akura.in/docs)

#### Prerequisites
- Node.js installed
- Render.com account (or any hosting platform)
- DNS access for akura.in

#### Step 1: Create Swagger UI Server

Create a new directory:
```bash
mkdir akura-api-docs-server
cd akura-api-docs-server
npm init -y
```

Install dependencies:
```bash
npm install express swagger-ui-express yamljs cors
```

Create `server.js`:
```javascript
const express = require('express');
const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3001;

// Enable CORS
app.use(cors());

// Load OpenAPI specification
const swaggerDocument = YAML.load(path.join(__dirname, 'AKURA_API_Spec.yaml'));

// Serve Swagger UI
app.use('/docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: 'AKURA SafeStride API Documentation'
}));

// Redirect root to /docs
app.get('/', (req, res) => {
  res.redirect('/docs');
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'AKURA API Docs' });
});

app.listen(PORT, () => {
  console.log(`📚 AKURA API Docs running at http://localhost:${PORT}/docs`);
});
```

Copy `AKURA_API_Spec.yaml` to this directory.

Update `package.json`:
```json
{
  "name": "akura-api-docs",
  "version": "1.0.0",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "swagger-ui-express": "^5.0.0",
    "yamljs": "^0.3.0",
    "cors": "^2.8.5"
  }
}
```

Test locally:
```bash
npm start
# Visit http://localhost:3001/docs
```

#### Step 2: Deploy to Render.com

1. Push code to GitHub repository
2. Go to Render.com → New Web Service
3. Connect your GitHub repository
4. Configure:
   - **Name:** akura-api-docs
   - **Environment:** Node
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - **Port:** 3001
5. Click "Create Web Service"

Render will provide a URL like: `https://akura-api-docs.onrender.com`

#### Step 3: Configure Custom Domain (api.akura.in)

**In Render Dashboard:**
1. Go to your service → Settings → Custom Domains
2. Add custom domain: `api.akura.in`
3. Render will show DNS records to configure

**In Your DNS Provider (Namecheap/GoDaddy/etc.):**
1. Add CNAME record:
   - **Type:** CNAME
   - **Host:** api
   - **Value:** akura-api-docs.onrender.com
   - **TTL:** 3600

Wait 5-60 minutes for DNS propagation.

**Access your docs:**
- https://api.akura.in/docs

---

### Option 3: Redoc (Alternative UI)

**Best for:** Beautiful, responsive documentation with better mobile support

#### Using CDN (Quick Method)

Create `index.html`:
```html
<!DOCTYPE html>
<html>
  <head>
    <title>AKURA SafeStride API</title>
    <meta charset="utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700" rel="stylesheet">
    <style>
      body {
        margin: 0;
        padding: 0;
      }
    </style>
  </head>
  <body>
    <redoc spec-url='./AKURA_API_Spec.yaml'></redoc>
    <script src="https://cdn.redoc.ly/redoc/latest/bundles/redoc.standalone.js"> </script>
  </body>
</html>
```

Deploy `index.html` + `AKURA_API_Spec.yaml` to:
- Netlify (drag & drop)
- Vercel (CLI: `vercel deploy`)
- GitHub Pages

---

## 📤 Import Postman Collection

### For Backend Team

1. Open Postman
2. Click **Import** button
3. Select `AKURA_API_Collection.postman.json`
4. Collection will appear in left sidebar

### Configure Environment Variables

Create a Postman environment:

```json
{
  "name": "AKURA Development",
  "values": [
    {
      "key": "baseUrl",
      "value": "http://localhost:3000/api",
      "enabled": true
    },
    {
      "key": "authToken",
      "value": "",
      "enabled": true
    },
    {
      "key": "userId",
      "value": "",
      "enabled": true
    },
    {
      "key": "protocolId",
      "value": "",
      "enabled": true
    }
  ]
}
```

For production, create another environment with:
- baseUrl: `https://safestride-backend-cave.onrender.com/api`

### Test Workflow

1. **Login** → Get token (auto-saved to environment)
2. **Submit Assessment** → Get protocolId (auto-saved)
3. **Get Protocol** → Uses saved protocolId
4. **Submit Feedback** → Uses saved protocolId and userId

Tests run automatically after each request to validate responses.

---

## 🧪 Frontend Testing Instructions

### When You're Ready to Test Frontend

1. Ensure local server is running:
```bash
cd "e:\Akura Safe Stride\safestride\frontend"
npx http-server -p 5502 -c-1
```

2. Open browser: `http://localhost:5502`

3. Open DevTools (F12) → Console

4. Paste and run the consolidated test suite (provided earlier)

5. Expected behaviors:
   - ✅ **Flow 1:** AIFRI calculation succeeds (70-85 range)
   - ⚠️ **Flow 1:** Backend submission fails (expected - backend not ready)
   - ✅ **Flow 1:** Data cached in localStorage (pendingAssessment)
   - ⚠️ **Flow 2:** Protocol fetch fails (expected)
   - ✅ **Flow 2:** Mock protocol generated from cache
   - ⚠️ **Flow 3:** Feedback submission fails (expected)
   - ✅ **Flow 3:** Feedback cached in localStorage (pendingFeedback)

6. Visual checks:
   - Training plans page renders (5 sections visible)
   - Feedback form works (shows success/offline message)
   - No console errors (except expected network failures)

---

## 🔄 Update Workflow

### When API Spec Changes

1. Update `AKURA_API_Spec.yaml`
2. Push to GitHub (if using GitHub Pages)
3. Redeploy server (if using Option 2)
4. Re-import Postman collection (new version)

### Frontend Changes

1. Update `js/api-client.js` to match new API format
2. Test with Postman first (verify request/response)
3. Run frontend tests again
4. Report any mismatches

---

## 📊 API Documentation URLs

After deployment:

| Service | URL |
|---------|-----|
| Production API | `https://safestride-backend-cave.onrender.com/api` |
| API Documentation | `https://api.akura.in/docs` |
| Postman Collection | Import from file |
| OpenAPI Spec | `https://api.akura.in/AKURA_API_Spec.yaml` |

---

## ✅ Verification Checklist

After deployment, verify:

- [ ] Can access https://api.akura.in/docs
- [ ] Swagger UI loads correctly
- [ ] "Try It Out" buttons work
- [ ] SSL certificate is valid (HTTPS)
- [ ] All 3 flows documented (Assessment, Protocol, Feedback)
- [ ] Postman collection imports without errors
- [ ] Backend team has access to Postman collection
- [ ] Frontend test results match API spec

---

## 🆘 Troubleshooting

### DNS Not Resolving
- Wait 1 hour for propagation
- Check DNS with: `nslookup api.akura.in`
- Verify CNAME points to Render domain

### Swagger UI Not Loading
- Check YAML syntax: https://www.yamllint.com/
- Ensure CORS is enabled on server
- Check browser console for errors

### Postman Collection Errors
- Re-import latest version
- Clear Postman cache
- Check environment variables are set

---

## 🎯 Next Steps

1. ✅ **Backend Team:** Import Postman collection and start implementation
2. ✅ **Frontend Team:** Run test suite and verify integration
3. ✅ **DevOps:** Deploy API docs to https://api.akura.in/docs
4. ⏳ **Testing:** E2E integration tests after backend is ready

---

## 📞 Support

Questions about API implementation?
- Email: support@akura.in
- Slack: #akura-backend-integration
- API Docs: https://api.akura.in/docs

---

**Generated:** January 27, 2026
**Version:** 1.0.0
**Status:** Ready for Production
