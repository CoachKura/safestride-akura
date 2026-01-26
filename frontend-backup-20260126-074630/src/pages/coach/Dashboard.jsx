import { Link } from 'react-router-dom';

export default function CoachDashboard() {
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-5xl mx-auto space-y-6">
        <header className="flex items-center justify-between">
          <div>
            <p className="text-sm text-gray-500">Coach</p>
            <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
          </div>
          <Link to="/coach/athletes" className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700">
            View Athletes
          </Link>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <StatCard label="Active Athletes" value="--" />
          <StatCard label="Planned Workouts" value="--" />
          <StatCard label="Pending Invites" value="--" />
        </div>

        <div className="bg-white shadow-sm rounded-xl p-6 border border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900 mb-3">Today</h2>
          <p className="text-gray-600">Hook up real data once API is wired. For now, use this screen to navigate the coach flows.</p>
        </div>
      </div>
    </div>
  );
}

function StatCard({ label, value }) {
  return (
    <div className="bg-white border border-gray-200 rounded-xl p-4 shadow-sm">
      <p className="text-sm text-gray-500">{label}</p>
      <p className="text-2xl font-bold text-gray-900 mt-2">{value}</p>
    </div>
  );
}
