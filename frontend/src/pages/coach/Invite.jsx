import { useState } from 'react';

export default function CoachInvite() {
  const [email, setEmail] = useState('');
  const [sending, setSending] = useState(false);
  const [message, setMessage] = useState('');

  async function handleSend(e) {
    e.preventDefault();
    setSending(true);
    setMessage('');
    try {
      // TODO: replace with real API call
      await new Promise((resolve) => setTimeout(resolve, 600));
      setMessage('Invite sent (mock). Wire to backend later.');
      setEmail('');
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-3xl mx-auto space-y-4">
        <header>
          <p className="text-sm text-gray-500">Coach</p>
          <h1 className="text-3xl font-bold text-gray-900">Invite Athlete</h1>
        </header>

        <form onSubmit={handleSend} className="bg-white border border-gray-200 rounded-xl shadow-sm p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Athlete Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 focus:ring-2 focus:ring-primary-500 focus:border-transparent"
              placeholder="athlete@example.com"
              required
            />
          </div>
          <button
            type="submit"
            disabled={sending}
            className="px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700 disabled:opacity-50"
          >
            {sending ? 'Sending...' : 'Send Invite'}
          </button>
          {message && <p className="text-sm text-green-600">{message}</p>}
        </form>
      </div>
    </div>
  );
}
