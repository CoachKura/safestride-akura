# 🚀 AISRi Web Platform - Complete Setup Guide

## 📋 **What We're Building**

A production-ready SaaS platform for **AISRi** with:

✅ Modern landing page  
✅ Multi-role authentication (Athlete/Coach/Admin)  
✅ Athlete dashboard with AI predictions  
✅ Coach dashboard for managing athletes  
✅ Admin panel for system management  
✅ Integration with existing FastAPI AI Engine  
✅ Connected to existing Supabase database

---

## 🎯 **Prerequisites**

Before starting, ensure you have:

- [x] Node.js 18+ installed
- [x] Supabase project: `bdisppaxbvygsspcuymb.supabase.co`
- [x] FastAPI AI Engine: `api.akura.in`
- [x] Text editor (VS Code recommended)
- [x] Terminal/PowerShell access

---

## 📦 **Step 1: Project Setup**

### **1.1 Navigate to Project**

```powershell
cd c:\safestride\aisri-web-platform
```

### **1.2 Install Dependencies**

```powershell
npm install
```

Expected output:

```
added 342 packages in 45s
```

### **1.3 Install shadcn/ui Components**

```powershell
# Initialize shadcn/ui
npx shadcn-ui@latest init

# When prompted, choose:
# - Style: Default
# - Base color: Slate
# - CSS variables: Yes
```

```powershell
# Install essential components
npx shadcn-ui@latest add button
npx shadcn-ui@latest add card
npx shadcn-ui@latest add form
npx shadcn-ui@latest add input
npx shadcn-ui@latest add label
npx shadcn-ui@latest add select
npx shadcn-ui@latest add dialog
npx shadcn-ui@latest add dropdown-menu
npx shadcn-ui@latest add tabs
npx shadcn-ui@latest add avatar
npx shadcn-ui@latest add badge
npx shadcn-ui@latest add progress
```

---

## 🔐 **Step 2: Environment Configuration**

### **2.1 Get Supabase Keys**

1. Go to: https://app.supabase.com/project/bdisppaxbvygsspcuymb/settings/api
2. Copy:
   - **Project URL**: `https://bdisppaxbvygsspcuymb.supabase.co`
   - **anon/public key**: `eyJhbG...` (starts with eyJ)
   - **service_role key**: `eyJhbG...` (secret - has full access)

### **2.2 Create `.env.local` File**

```powershell
# Copy example file
cp .env.local.example .env.local
```

Edit `.env.local`:

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://bdisppaxbvygsspcuymb.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# AISRi AI Engine
NEXT_PUBLIC_AISRI_API_URL=https://api.akura.in

# App Configuration
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
```

⚠️ **Security**: Never commit `.env.local` to Git!

---

## 🗄️ **Step 3: Database Setup**

### **3.1 Verify Existing Tables**

Your Supabase already has these tables:

- ✅ `profiles`
- ✅ `athlete_coach_relationships`
- ✅ `AISRI_assessments`
- ✅ `athlete_detailed_profile`
- ✅ `workout_assignments`
- ✅ `workout_results`

### **3.2 Add New Table for Web Platform**

1. **Open Supabase SQL Editor**:
   https://app.supabase.com/project/bdisppaxbvygsspcuymb/sql

2. **Copy Migration File**:
   Open: `c:\safestride\aisri-web-platform\database\migrations\01_evaluation_responses.sql`
   Select all (Ctrl+A) and copy (Ctrl+C)

3. **Paste and Execute**:
   - Paste in SQL Editor
   - Click **RUN** button
   - Expected: ✅ "Success. No rows returned"

4. **Verify Table Created**:
   - Go to: Dashboard → Table Editor
   - Find: `evaluation_responses` table
   - Should have 23 columns

---

## 🚀 **Step 4: Start Development Server**

```powershell
npm run dev
```

Expected output:

```
   ▲ Next.js 14.2.0
   - Local:        http://localhost:3000
   - Ready in 2.3s
```

Open browser: http://localhost:3000

---

## 🏗️ **Step 5: Build Phase 1 (Landing + Auth)**

### **5.1 Create Landing Page**

Create: `app/page.tsx`

```typescript
import Link from 'next/link'
import { Button } from '@/components/ui/button'

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-900 to-slate-800 text-white">
      {/* Hero Section */}
      <div className="container mx-auto px-4 py-20">
        <div className="text-center max-w-4xl mx-auto">
          <h1 className="text-6xl font-bold mb-6">
            AI-Powered Running Intelligence
          </h1>
          <p className="text-xl text-slate-300 mb-8">
            Prevent injuries. Optimize performance. Train smarter with AISRi.
          </p>
          <div className="flex gap-4 justify-center">
            <Link href="/signup">
              <Button size="lg" className="text-lg px-8">
                Get Started Free
              </Button>
            </Link>
            <Link href="/login">
              <Button size="lg" variant="outline" className="text-lg px-8">
                Sign In
              </Button>
            </Link>
          </div>
        </div>
      </div>

      {/* Features Section */}
      <div className="container mx-auto px-4 py-20">
        <h2 className="text-4xl font-bold text-center mb-12">
          What is AISRi?
        </h2>
        <div className="grid md:grid-cols-3 gap-8">
          <FeatureCard
            icon="🩺"
            title="Injury Prevention"
            description="AI predicts injury risk before pain starts. Train safely."
          />
          <FeatureCard
            icon="📈"
            title="Performance Prediction"
            description="Know your race times. VO2max. Personalized pacing."
          />
          <FeatureCard
            icon="🤖"
            title="Autonomous Coaching"
            description="Daily training decisions. Adaptive plans. 24/7 guidance."
          />
        </div>
      </div>

      {/* CTA Section */}
      <div className="container mx-auto px-4 py-20 text-center">
        <h2 className="text-4xl font-bold mb-6">
          Ready to Transform Your Training?
        </h2>
        <p className="text-xl text-slate-300 mb-8">
          Join 1,000+ athletes using AISRi to train smarter.
        </p>
        <Link href="/signup">
          <Button size="lg" className="text-lg px-8">
            Start Your Free Trial
          </Button>
        </Link>
      </div>
    </div>
  )
}

function FeatureCard({ icon, title, description }: {
  icon: string
  title: string
  description: string
}) {
  return (
    <div className="bg-slate-800 p-6 rounded-lg border border-slate-700">
      <div className="text-4xl mb-4">{icon}</div>
      <h3 className="text-2xl font-bold mb-2">{title}</h3>
      <p className="text-slate-300">{description}</p>
    </div>
  )
}
```

### **5.2 Create Login Page**

Create: `app/(auth)/login/page.tsx`

```typescript
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { supabase } from '@/lib/supabase/client'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      })

      if (error) throw error

      // Get user profile to determine role
      const { data: profile } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', data.user.id)
        .single()

      // Redirect based on role
      if (profile?.role === 'athlete') {
        router.push('/athlete/dashboard')
      } else if (profile?.role === 'coach') {
        router.push('/coach/dashboard')
      } else if (profile?.role === 'admin') {
        router.push('/admin/dashboard')
      }
    } catch (err: any) {
      setError(err.message || 'Login failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-b from-slate-900 to-slate-800 p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-3xl font-bold">Welcome Back</CardTitle>
          <CardDescription>Sign in to your AISRi account</CardDescription>
        </CardHeader>
        <form onSubmit={handleLogin}>
          <CardContent className="space-y-4">
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
                {error}
              </div>
            )}
            <div className="space-y-2">
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="athlete@example.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Password</Label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
          </CardContent>
          <CardFooter className="flex flex-col space-y-4">
            <Button
              type="submit"
              className="w-full"
              disabled={loading}
            >
              {loading ? 'Signing in...' : 'Sign In'}
            </Button>
            <p className="text-sm text-center text-slate-600">
              Don't have an account?{' '}
              <Link href="/signup" className="text-blue-600 hover:underline">
                Sign up
              </Link>
            </p>
          </CardFooter>
        </form>
      </Card>
    </div>
  )
}
```

### **5.3 Create Auth Layout**

Create: `app/(auth)/layout.tsx`

```typescript
export default function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return <>{children}</>
}
```

### **5.4 Test Landing + Login**

1. Visit: http://localhost:3000
2. Should see: Landing page with hero, features, CTA
3. Click "Sign In" → Should see login form
4. Test with existing Supabase user

---

## ✅ **Phase 1 Complete Checklist**

- [ ] Dependencies installed
- [ ] Environment variables configured
- [ ] Database migration executed
- [ ] Development server running
- [ ] Landing page displays correctly
- [ ] Login page accessible
- [ ] Can sign in with existing user

---

## 🎯 **Next Steps (Phase 2)**

After Phase 1 is complete, we'll build:

### **Phase 2: Athlete Experience**

1. **Evaluation Form** (Multi-step onboarding)
   - Personal info (age, gender, height, weight)
   - Training history (volume, experience)
   - Injury history (past injuries, pain areas)
   - Goals (upcoming races, targets)

2. **Athlete Dashboard**
   - Injury risk score (with visual gauge)
   - Performance predictions (5K, 10K, Half, Marathon)
   - Today's workout recommendation
   - Progress charts (training load, ability)
   - AI coach chat

3. **AISRi Integration**
   - Connect to FastAPI endpoints
   - Display predictions
   - Handle loading states
   - Error boundaries

---

## 🐛 **Troubleshooting**

### **Issue: npm install fails**

```powershell
# Clear npm cache
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### **Issue: Port 3000 already in use**

```powershell
# Kill process on port 3000
Get-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess | Stop-Process -Force

# Or use different port
npm run dev -- -p 3001
```

### **Issue: Supabase connection fails**

- Verify `.env.local` has correct keys
- Check Supabase project is accessible
- Ensure anon key is not expired

### **Issue: Database migration fails**

- Check SQL syntax (no doubled quotes)
- Verify you have service_role permissions
- Try running migration line-by-line

---

## 📞 **Get Help**

If stuck, check:

1. **README.md** - Full project documentation
2. **Next.js Docs**: https://nextjs.org/docs
3. **Supabase Docs**: https://supabase.com/docs
4. **shadcn/ui Docs**: https://ui.shadcn.com

---

## 🚀 **Ready to Launch?**

Once Phase 1 is complete and tested, reply with:

- ✅ Landing page works
- ✅ Login page works
- ✅ Database migration successful

And we'll proceed to **Phase 2: Athlete Dashboard & Evaluation Form**! 🎯
