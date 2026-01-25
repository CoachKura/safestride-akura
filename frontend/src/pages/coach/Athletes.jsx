import { Link } from 'react-router-dom';

export default function CoachAthletes() {
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-5xl mx-auto space-y-4">
        <header className="flex items-center justify-between">
          <div>
            <p className="text-sm text-gray-500">Coach</p>
            <h1 className="text-3xl font-bold text-gray-900">Athletes</h1>
          </div>
          <Link to="/coach/invite" className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700">
            Send Invite
          </Link>
        </header>

        <div className="bg-white border border-gray-200 rounded-xl shadow-sm p-6">
          <p className="text-gray-600">Athlete list will appear here once connected to the backend. Use the invite flow to onboard athletes.</p>
        </div>
      </div>
    </div>
  );
}
