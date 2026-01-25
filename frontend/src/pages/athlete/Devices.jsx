import { Link } from 'react-router-dom';

export default function AthleteDevices() {
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-4xl mx-auto space-y-4">
        <header className="flex items-center justify-between">
          <div>
            <p className="text-sm text-gray-500">Athlete</p>
            <h1 className="text-3xl font-bold text-gray-900">Connected Devices</h1>
          </div>
          <Link to="/athlete/dashboard" className="text-primary-600 hover:text-primary-700">
            Back to dashboard
          </Link>
        </header>

        <div className="bg-white border border-gray-200 rounded-xl shadow-sm p-6 space-y-4">
          <section className="border border-dashed border-gray-300 rounded-lg p-4">
            <h2 className="text-lg font-semibold text-gray-900 mb-1">Strava</h2>
            <p className="text-gray-600 text-sm mb-3">Connect to sync activities from Strava.</p>
            <button className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700">Connect Strava</button>
          </section>

          <section className="border border-dashed border-gray-300 rounded-lg p-4">
            <h2 className="text-lg font-semibold text-gray-900 mb-1">Garmin</h2>
            <p className="text-gray-600 text-sm mb-3">Connect Garmin to sync workouts and activities.</p>
            <button className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg cursor-not-allowed" disabled>Coming soon</button>
          </section>
        </div>
      </div>
    </div>
  );
}
