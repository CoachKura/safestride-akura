import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Activity, Brain, TrendingUp, Shield, Zap, Users } from 'lucide-react'

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-purple-50 to-white">
      {/* Navigation */}
      <nav className="border-b bg-white/80 backdrop-blur-sm fixed w-full top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex justify-between items-center">
          <div className="flex items-center gap-2">
            <Activity className="h-8 w-8 text-purple-600" />
            <span className="text-2xl font-bold text-purple-600">AISRi</span>
          </div>
          <div className="flex gap-4">
            <Button variant="ghost" asChild>
              <Link href="/login">Login</Link>
            </Button>
            <Button asChild>
              <Link href="/signup">Get Started</Link>
            </Button>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4">
        <div className="container mx-auto text-center">
          <Badge className="mb-4" variant="secondary">
            AI-Powered Training Intelligence
          </Badge>
          <h1 className="text-5xl md:text-6xl font-bold mb-6 text-gray-900">
            Train Smarter with
            <span className="text-purple-600"> AI Sports Intelligence</span>
          </h1>
          <p className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto">
            AISRi combines advanced AI, biomechanics analysis, and real-time data 
            to create personalized training plans that prevent injuries and maximize performance.
          </p>
          <div className="flex gap-4 justify-center">
            <Button size="lg" asChild>
              <Link href="/signup">Start Free Trial</Link>
            </Button>
            <Button size="lg" variant="outline" asChild>
              <Link href="#features">Learn More</Link>
            </Button>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="py-20 px-4 bg-gray-50">
        <div className="container mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12">
            Intelligent Training for Athletes & Coaches
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            <Card>
              <CardHeader>
                <Brain className="h-10 w-10 text-purple-600 mb-2" />
                <CardTitle>AI Autonomous Agent</CardTitle>
                <CardDescription>
                  Self-learning AI that adapts training plans based on your progress, 
                  biomechanics, and recovery metrics.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card>
              <CardHeader>
                <Shield className="h-10 w-10 text-purple-600 mb-2" />
                <CardTitle>Injury Prevention</CardTitle>
                <CardDescription>
                  Predictive analytics monitor fatigue, biomechanics, and training load 
                  to prevent injuries before they happen.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card>
              <CardHeader>
                <TrendingUp className="h-10 w-10 text-purple-600 mb-2" />
                <CardTitle>Performance Optimization</CardTitle>
                <CardDescription>
                  Data-driven insights from GPS activities, HR zones, and race history 
                  to achieve peak performance.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card>
              <CardHeader>
                <Zap className="h-10 w-10 text-purple-600 mb-2" />
                <CardTitle>Real-Time Analysis</CardTitle>
                <CardDescription>
                  Instant feedback on workouts, biomechanics, and recovery status 
                  through Telegram and mobile integration.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card>
              <CardHeader>
                <Users className="h-10 w-10 text-purple-600 mb-2" />
                <CardTitle>Coach Dashboard</CardTitle>
                <CardDescription>
                  Manage multiple athletes, assign workouts, track progress, 
                  and communicate with your team in one place.
                </CardDescription>
              </CardHeader>
            </Card>

            <Card>
              <CardHeader>
                <Activity className="h-10 w-10 text-purple-600 mb-2" />
                <CardTitle>Activity Integration</CardTitle>
                <CardDescription>
                  Seamless sync with Strava, Garmin, and other platforms for 
                  comprehensive training data analysis.
                </CardDescription>
              </CardHeader>
            </Card>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 px-4">
        <div className="container mx-auto text-center">
          <Card className="max-w-2xl mx-auto border-purple-200 bg-purple-50">
            <CardHeader>
              <CardTitle className="text-3xl">Ready to Transform Your Training?</CardTitle>
              <CardDescription className="text-lg">
                Join hundreds of athletes and coaches using AI to train smarter, 
                prevent injuries, and achieve their goals.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button size="lg" asChild>
                <Link href="/signup">Get Started Free</Link>
              </Button>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t py-8 px-4 bg-gray-50">
        <div className="container mx-auto text-center text-gray-600">
          <p>&copy; 2026 AISRi. All rights reserved.</p>
        </div>
      </footer>
    </div>
  )
}
