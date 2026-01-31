export default function StatCard({ title, value, icon }) {
  return (
    <div className="bg-white rounded-2xl p-4 shadow">
      <div className="text-3xl mb-2">{icon}</div>
      <div className="text-sm text-gray-600 mb-1">{title}</div>
      <div className="text-xl font-bold text-gray-800">{value}</div>
    </div>
  );
}
