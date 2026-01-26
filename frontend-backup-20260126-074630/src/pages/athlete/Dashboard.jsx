export default function AthleteDashboard() {
  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-5xl mx-auto space-y-4">
        <header>
          <p className="text-sm text-gray-500">Athlete</p>
          <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Card title="Next Workout" body="No workout assigned yet." />
          <Card title="This Week" body="0 sessions" />
          <Card title="Status" body="Sync devices to see stats." />
        </div>
      </div>
    </div>
  );
}

function Card({ title, body }) {
  return (
    <div className="bg-white border border-gray-200 rounded-xl p-4 shadow-sm">
      <p className="text-sm text-gray-500">{title}</p>
      <p className="text-gray-800 mt-2">{body}</p>
    </div>
  );
}
