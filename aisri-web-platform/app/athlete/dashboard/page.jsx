'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Activity, TrendingUp, AlertCircle, Calendar } from 'lucide-react'

export default function AthleteDashboard() {
  const router = useRouter()
  const [user, setUser] = useState(null)
  const [profile, setProfile] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const loadUserData = async () => {
      const supabase = createClient()
      const { data: { user } } = await supabase.auth.getUser()
      
      if (!user) {
        router.push('/login')
        return
      }

      const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('user_id', user.id)
        .single()

      setUser(user)
      setProfile(profile)
      setLoading(false)
    }

    loadUserData()
  }, [router])

  const handleLogout = async () => {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/')
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <Activity className="h-12 w-12 animate-pulse text-purple-600 mx-auto mb-4" />
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b">
        <div className="container mx-auto px-4 py-4 flex justify-between items-center">
          <div className="flex items-center gap-3">
            <Activity className="h-8 w-8 text-purple-600" />
            <div>
              <h1 className="text-xl font-bold">AISRi Athlete</h1>
              <p className="text-sm text-gray-600">{profile?.full_name}</p>
            </div>
          </div>
          <Button variant="outline" onClick={handleLogout}>
            Logout
          </Button>
        </div>
      </header>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        <div className="mb-8">
          <h2 className="text-3xl font-bold mb-2">Welcome back, {profile?.full_name}!</h2>
          <p className="text-gray-600">Here\'s your training overview</p>
        </div>

        {/* Quick Stats */}
        <div className="grid md:grid-cols-4 gap-6 mb-8">
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-gray-600">Training Load</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">Moderate</div>
              <Badge variant="secondary" className="mt-2">Week 4/12</Badge>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-gray-600">Injury Risk</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-green-600">Low</div>
              <p className="text-sm text-gray-600 mt-2">Excellent recovery</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-gray-600">This Week</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">42 km</div>
              <p className="text-sm text-gray-600 mt-2">Target: 50 km</p>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-gray-600">Next Race</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">12 weeks</div>
              <p className="text-sm text-gray-600 mt-2">Marathon prep</p>
            </CardContent>
          </Card>
        </div>

        {/* Main Dashboard Sections */}
        <div className="grid md:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calendar className="h-5 w-5" />
                Upcoming Workouts
              </CardTitle>
              <CardDescription>Your scheduled training sessions</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="p-3 bg-purple-50 rounded-lg">
                  <div className="flex justify-between items-start mb-1">
                    <h4 className="font-semibold">Long Run</h4>
                    <Badge>Tomorrow</Badge>
                  </div>
                  <p className="text-sm text-gray-600">20 km @ easy pace</p>
                </div>
                <div className="p-3 bg-gray-50 rounded-lg">
                  <div className="flex justify-between items-start mb-1">
                    <h4 className="font-semibold">Interval Training</h4>
                    <Badge variant="outline">Mon, Mar 3</Badge>
                  </div>
                  <p className="text-sm text-gray-600">8x800m @ threshold</p>
                </div>
                <div className="p-3 bg-gray-50 rounded-lg">
                  <div className="flex justify-between items-start mb-1">
                    <h4 className="font-semibold">Recovery Run</h4>
                    <Badge variant="outline">Wed, Mar 5</Badge>
                  </div>
                  <p className="text-sm text-gray-600">10 km @ recovery pace</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <TrendingUp className="h-5 w-5" />
                Recent Activities
              </CardTitle>
              <CardDescription>Your latest training sessions</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="p-3 border rounded-lg">
                  <div className="flex justify-between items-start mb-1">
                    <h4 className="font-semibold">Easy Run</h4>
                    <span className="text-sm text-gray-600">Today</span>
                  </div>
                  <p className="text-sm text-gray-600">8.2 km • 5:15/km • Zone 2</p>
                </div>
                <div className="p-3 border rounded-lg">
                  <div className="flex justify-between items-start mb-1">
                    <h4 className="font-semibold">Tempo Run</h4>
                    <span className="text-sm text-gray-600">Yesterday</span>
                  </div>
                  <p className="text-sm text-gray-600">15 km • 4:30/km • Zone 3-4</p>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <AlertCircle className="h-5 w-5" />
                AI Insights
              </CardTitle>
              <CardDescription>Personalized recommendations</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="p-3 bg-blue-50 border-l-4 border-blue-500 rounded">
                  <p className="text-sm font-medium">Recovery Recommendation</p>
                  <p className="text-sm text-gray-600 mt-1">
                    Your HRV is slightly elevated. Consider an extra rest day this week.
                  </p>
                </div>
                <div className="p-3 bg-green-50 border-l-4 border-green-500 rounded">
                  <p className="text-sm font-medium">Performance Trend</p>
                  <p className="text-sm text-gray-600 mt-1">
                    Your threshold pace has improved by 5% over the last 4 weeks!
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  )
}
