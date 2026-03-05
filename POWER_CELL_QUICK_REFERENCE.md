# Power Cell Quick Reference

## Commits
- Root: `b7fce26` (`main`)
- Frontend: `37ff246` (`production`)

## Production URLs
- App: `https://safestride-akura.vercel.app/power-cells.html`
- API: `https://bdisppaxbvygsspcuymb.supabase.co/functions/v1/power-cells-get`

## Console Smoke Test
```javascript
const raw = sessionStorage.getItem('safestride_session');
const token = raw?.includes('.') ? raw : JSON.parse(raw || '{}')?.access_token;
const uid = raw?.includes('.') ? JSON.parse(atob(raw.split('.')[1]))?.sub : JSON.parse(raw || '{}')?.user?.id;

fetch(`${window.SAFESTRIDE_CONFIG.api.functionsUrl}/power-cells-get`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  },
  body: JSON.stringify({ user_id: uid }),
}).then(r => r.json()).then(console.log);
```

## Local Commands
```powershell
cd C:\safestride\supabase
supabase start
supabase functions serve power-cells-get

cd C:\safestride\webapp\public
python -m http.server 8080
```
