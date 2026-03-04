# 🔄 Migration Plan: Supabase → Cloudflare Full Stack

## 📋 Overview
Migrate SafeStride from Supabase (connectivity issues) to Cloudflare's full stack (D1, KV, R2, Workers) for permanent, reliable deployment.

---

## ⚡ Phase 1: Backend Migration (Day 1)

### **1.1: Consolidate Backend into Hono**

Move Python backend logic into Hono API routes:

**File**: `src/index.tsx`

```typescript
import { Hono } from 'hono';
import { cors } from 'hono/cors';

type Bindings = {
  DB: D1Database;
  KV: KVNamespace;
  R2: R2Bucket;
}

const app = new Hono<{ Bindings: Bindings }>();

// Enable CORS
app.use('/api/*', cors());

// AISRI Calculation API (replaces aisri-ai-engine)
app.post('/api/aisri/calculate', async (c) => {
  const { env } = c;
  const data = await c.req.json();
  
  // Calculate AISRI score
  const aisri_score = calculateAISRI(data);
  const risk_category = getRiskCategory(aisri_score);
  
  // Store in D1
  await env.DB.prepare(`
    INSERT INTO aisri_score_history (athlete_id, aisri_score, risk_category, pillar_scores)
    VALUES (?, ?, ?, ?)
  `).bind(data.athlete_id, aisri_score, risk_category, JSON.stringify(data.pillar_scores)).run();
  
  return c.json({ aisri_score, risk_category, timestamp: new Date().toISOString() });
});

// Notification API (replaces aisri-communication-v2)
app.post('/api/notifications/send', async (c) => {
  const { env } = c;
  const { user_id, message, type } = await c.req.json();
  
  // Store notification in KV
  await env.KV.put(`notification:${user_id}:${Date.now()}`, JSON.stringify({
    message,
    type,
    sent_at: new Date().toISOString(),
    read: false
  }));
  
  // TODO: Send actual notification (email, push, SMS)
  
  return c.json({ success: true, notification_id: Date.now() });
});

// Helper functions
function calculateAISRI(data: any): number {
  const weights = {
    running: 0.40,
    strength: 0.15,
    rom: 0.12,
    balance: 0.13,
    alignment: 0.10,
    mobility: 0.10
  };
  
  return (
    data.running_score * weights.running +
    data.strength_score * weights.strength +
    data.rom_score * weights.rom +
    data.balance_score * weights.balance +
    data.alignment_score * weights.alignment +
    data.mobility_score * weights.mobility
  );
}

function getRiskCategory(score: number): string {
  if (score < 40) return 'Low';
  if (score < 55) return 'Medium';
  if (score < 75) return 'High';
  return 'Critical';
}

export default app;
```

---

## 🗄️ Phase 2: Database Migration (Day 2)

### **2.1: Create D1 Database**

```bash
# Create production D1 database
npx wrangler d1 create safestride-production

# Output will give you database_id - add to wrangler.jsonc
```

### **2.2: Run Migrations**

Use existing migration file `migrations/003_modern_safestride_schema.sql`:

```bash
# Apply migration to D1
npx wrangler d1 migrations apply safestride-production
```

### **2.3: Export Data from Supabase**

```sql
-- In Supabase SQL Editor, export each table:

-- Export athletes/profiles
COPY (SELECT * FROM profiles) TO STDOUT WITH CSV HEADER;

-- Export aisri_score_history
COPY (SELECT * FROM aisri_score_history) TO STDOUT WITH CSV HEADER;

-- Export training_plans
COPY (SELECT * FROM training_plans) TO STDOUT WITH CSV HEADER;

-- Export daily_workouts
COPY (SELECT * FROM daily_workouts) TO STDOUT WITH CSV HEADER;

-- Save each as CSV files
```

### **2.4: Import Data into D1**

```bash
# Convert CSV to SQL INSERT statements
# Use a script or do manually for initial data

# Import into D1
npx wrangler d1 execute safestride-production --file=./import_data.sql
```

---

## 🔐 Phase 3: Authentication Migration (Day 3)

### **3.1: Replace Supabase Auth**

**Option A: Cloudflare Access (Enterprise)**  
**Option B: Clerk (Recommended)**  
**Option C: Custom JWT with Cloudflare Workers**

**Using Clerk** (easiest):

```typescript
import { clerkMiddleware } from '@clerk/backend';

app.use('/api/*', clerkMiddleware({
  publishableKey: c.env.CLERK_PUBLISHABLE_KEY,
  secretKey: c.env.CLERK_SECRET_KEY
}));

app.get('/api/profile', async (c) => {
  const userId = c.get('userId'); // From Clerk middleware
  // ... fetch user data
});
```

### **3.2: Update Frontend Auth Calls**

Replace Supabase client with Clerk:

```typescript
// Before (Supabase)
const { data, error } = await supabase.auth.signIn({ email, password });

// After (Clerk)
const { signIn } = useSignIn();
await signIn.create({ identifier: email, password });
```

---

## 📁 Phase 4: File Storage Migration (Day 4)

### **4.1: Move Files to R2**

```typescript
// Upload assessment images to R2
app.post('/api/upload/assessment-image', async (c) => {
  const { env } = c;
  const formData = await c.req.formData();
  const file = formData.get('file');
  
  const key = `assessments/${Date.now()}-${file.name}`;
  await env.R2.put(key, file.stream());
  
  return c.json({ url: `https://your-r2-bucket.r2.dev/${key}` });
});

// Retrieve images from R2
app.get('/api/media/:key', async (c) => {
  const { env } = c;
  const key = c.req.param('key');
  
  const object = await env.R2.get(key);
  if (!object) return c.notFound();
  
  return new Response(object.body, {
    headers: { 'Content-Type': object.httpMetadata?.contentType || 'application/octet-stream' }
  });
});
```

---

## 🔧 Phase 5: Update Configuration (Day 5)

### **5.1: Update wrangler.jsonc**

```jsonc
{
  "$schema": "node_modules/wrangler/config-schema.json",
  "name": "safestride",
  "main": "src/index.tsx",
  "compatibility_date": "2024-01-01",
  "compatibility_flags": ["nodejs_compat"],
  
  "d1_databases": [
    {
      "binding": "DB",
      "database_name": "safestride-production",
      "database_id": "your-d1-database-id"
    }
  ],
  
  "kv_namespaces": [
    {
      "binding": "KV",
      "id": "your-kv-namespace-id",
      "preview_id": "your-kv-preview-id"
    }
  ],
  
  "r2_buckets": [
    {
      "binding": "R2",
      "bucket_name": "safestride-media"
    }
  ],
  
  "vars": {
    "ENVIRONMENT": "production"
  }
}
```

### **5.2: Add Secrets**

```bash
# Add sensitive credentials
npx wrangler secret put CLERK_SECRET_KEY
npx wrangler secret put STRAVA_CLIENT_SECRET
npx wrangler secret put EMAIL_API_KEY
```

---

## 📱 Phase 6: Update Frontend (Day 6)

### **6.1: Replace Supabase Client**

**Before**:
```typescript
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
const { data } = await supabase.from('athletes').select('*');
```

**After**:
```typescript
// Call your Cloudflare Workers API
const response = await fetch('https://safestride.pages.dev/api/athletes');
const data = await response.json();
```

### **6.2: Update All API Calls**

Replace all Supabase calls with fetch calls to your Workers API:

```typescript
// Athletes
GET /api/athletes
POST /api/athletes
GET /api/athletes/:id
PUT /api/athletes/:id

// Assessments
POST /api/assessments
GET /api/assessments/:id

// AISRI
POST /api/aisri/calculate
GET /api/aisri/history/:athlete_id

// Training Plans
GET /api/training-plans/:athlete_id
POST /api/training-plans

// Workouts
GET /api/workouts/:athlete_id
POST /api/workouts/complete
```

---

## 🧪 Phase 7: Testing (Day 7)

### **7.1: Local Testing**

```bash
# Start Wrangler dev server
npx wrangler pages dev dist --d1=safestride-production --local

# Test all API endpoints
curl http://localhost:8787/api/athletes
curl -X POST http://localhost:8787/api/aisri/calculate -d '{"data":"..."}'
```

### **7.2: Production Deployment**

```bash
# Deploy database
npx wrangler d1 migrations apply safestride-production

# Deploy Workers
npx wrangler pages deploy dist --project-name safestride

# Verify deployment
curl https://safestride.pages.dev/api/health
```

---

## ✅ Migration Checklist

- [ ] **Day 1**: Move backend logic to Hono routes
- [ ] **Day 2**: Migrate database to D1
- [ ] **Day 3**: Set up authentication (Clerk/custom)
- [ ] **Day 4**: Migrate files to R2
- [ ] **Day 5**: Update configuration and secrets
- [ ] **Day 6**: Update frontend API calls
- [ ] **Day 7**: Test and deploy

---

## 🎯 Success Criteria

After migration:
- ✅ No Supabase dependency
- ✅ All data in Cloudflare D1
- ✅ All files in Cloudflare R2
- ✅ Authentication working (Clerk/custom)
- ✅ All API endpoints functional
- ✅ Frontend connected to new backend
- ✅ No India connectivity issues
- ✅ No deployment failures
- ✅ Faster global performance

---

## 📊 Cost Comparison

| Service | Supabase | Cloudflare |
|---------|----------|------------|
| **Database** | Free: 500MB | Free: 5GB |
| **Storage** | Free: 1GB | Free: 10GB |
| **Bandwidth** | Free: 2GB | Free: Unlimited |
| **Requests** | Free: 50K/month | Free: 100K/day |
| **Edge Network** | ❌ No | ✅ Yes |
| **India Issues** | ⚠️ Yes | ✅ No |

---

## 🆘 Rollback Plan

If migration fails:
1. Keep Supabase active during migration
2. Run both systems in parallel
3. Gradually migrate users
4. Switch DNS/routing when ready
5. Keep Supabase as backup for 30 days

---

**Created**: March 4, 2026  
**Estimated Time**: 7 days (or 1-2 days intensive)  
**Difficulty**: Medium  
**Risk**: Low (with parallel running)  
**Reward**: High (permanent, reliable solution)
