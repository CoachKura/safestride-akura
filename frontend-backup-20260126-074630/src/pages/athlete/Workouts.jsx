export default function AthleteWorkouts() {
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-5xl mx-auto space-y-4">
        <header>
          <p className="text-sm text-gray-500">Athlete</p>
          <h1 className="text-3xl font-bold text-gray-900">Workouts</h1>
        </header>

        <div className="bg-white border border-gray-200 rounded-xl shadow-sm p-6">
          <p className="text-gray-600">Your planned workouts will appear here once assigned by your coach.</p>
        </div>
      </div>
    </div>
  );
}
