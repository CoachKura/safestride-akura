import { Link } from 'react-router-dom';
import { Activity, Calendar, Heart, Smartphone, TrendingUp, Users } from 'lucide-react';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-primary-50 to-white">
      {/* Header */}
      <header className="border-b bg-white/80 backdrop-blur-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <Activity className="h-8 w-8 text-primary-600" />
            <div>
              <h1 className="text-2xl font-bold text-gray-900">SafeStride</h1>
              <p className="text-sm text-gray-600">by AKURA</p>
            </div>
          </div>
          <div className="flex space-x-4">
            <Link
              to="/login"
              className="px-4 py-2 text-primary-600 hover:text-primary-700 font-medium"
            >
              Sign In
            </Link>
            <Link
              to="/signup"
              className="px-6 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 font-medium"
            >
              Join Now
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="py-20 px-4">
        <div className="max-w-7xl mx-auto text-center">
          <h2 className="text-5xl font-bold text-gray-900 mb-6">
            Transform Your Running with <span className="text-primary-600">Elite Coaching</span>
          </h2>
          <p className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto">
            VDOT O2-inspired platform for Chennai's elite runners. Personalized training, automatic device sync,
            and HR-based protocols designed to take you from recreational to elite performance.
          </p>
          <div className="flex justify-center space-x-4">
            <Link
              to="/signup"
              className="px-8 py-4 bg-primary-600 text-white rounded-lg hover:bg-primary-700 font-semibold text-lg"
            >
              Start Your Journey
            </Link>
            <a
              href="#features"
              className="px-8 py-4 border-2 border-primary-600 text-primary-600 rounded-lg hover:bg-primary-50 font-semibold text-lg"
            >
              Learn More
            </a>
          </div>
        </div>
      </section>

      {/* Features */}
      <section id="features" className="py-20 px-4 bg-white">
        <div className="max-w-7xl mx-auto">
          <h3 className="text-3xl font-bold text-center mb-12">Platform Features</h3>
          <div className="grid md:grid-cols-3 gap-8">
            <FeatureCard
              icon={<Calendar className="h-10 w-10 text-primary-600" />}
              title="Auto-Synced Workouts"
              description="Coach publishes once, workouts appear in your Garmin/Strava calendar automatically"
            />
            <FeatureCard
              icon={<Heart className="h-10 w-10 text-primary-600" />}
              title="HR-Based Training"
              description="5-zone system calculated from your Max HR (208 - 0.7 × Age) with personalized targets"
            />
            <FeatureCard
              icon={<Smartphone className="h-10 w-10 text-primary-600" />}
              title="Device Integration"
              description="Connect Garmin, Strava, Coros, or Apple Health for automatic activity tracking"
            />
            <FeatureCard
              icon={<TrendingUp className="h-10 w-10 text-primary-600" />}
              title="7 Protocol System"
              description="START, ENGINE, OXYGEN, POWER, ZONES, STRENGTH, LONG RUN - comprehensive training"
            />
            <FeatureCard
              icon={<Users className="h-10 w-10 text-primary-600" />}
              title="Coach Dashboard"
              description="Manage all athletes, publish group calendars, track progress in real-time"
            />
            <FeatureCard
              icon={<Activity className="h-10 w-10 text-primary-600" />}
              title="Chennai Optimized"
              description="Training adapted for Chennai's climate with optimal timing and hydration strategies"
            />
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-20 px-4 bg-primary-600 text-white">
        <div className="max-w-4xl mx-auto text-center">
          <h3 className="text-4xl font-bold mb-6">Ready to Transform Your Running?</h3>
          <p className="text-xl mb-8 opacity-90">
            Join Coach Kura's elite training program and achieve your sub-4:00/km Half Marathon goal
          </p>
          <Link
            to="/signup"
            className="inline-block px-8 py-4 bg-white text-primary-600 rounded-lg hover:bg-gray-100 font-semibold text-lg"
          >
            Get Started Now
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12 px-4">
        <div className="max-w-7xl mx-auto text-center">
          <div className="mb-6">
            <h4 className="text-2xl font-bold mb-2">SafeStride by AKURA</h4>
            <p className="text-gray-400">Professional Running Coach Platform</p>
          </div>
          <div className="flex justify-center space-x-6 mb-6">
            <a href="mailto:coach@akura.in" className="text-gray-400 hover:text-white">
              coach@akura.in
            </a>
            <a href="https://instagram.com/akura_safestride" className="text-gray-400 hover:text-white">
              @akura_safestride
            </a>
            <a href="https://wa.me/message/24CYRZY5TMH7F1" className="text-gray-400 hover:text-white">
              WhatsApp
            </a>
          </div>
          <p className="text-gray-400 text-sm">
            Coach Kura Balendar Sathyamoorthy | Chennai, India
          </p>
          <p className="text-gray-500 text-sm mt-4">
            © 2026 SafeStride by AKURA. All rights reserved.
          </p>
        </div>
      </footer>
    </div>
  );
}

function FeatureCard({ icon, title, description }) {
  return (
    <div className="p-6 border rounded-lg hover:shadow-lg transition-shadow">
      <div className="mb-4">{icon}</div>
      <h4 className="text-xl font-semibold mb-2">{title}</h4>
      <p className="text-gray-600">{description}</p>
    </div>
  );
}
