Akura SafeStride Mobile (scaffold)

To run locally:

1. cd "E:/Akura Safe Stride/safestride/mobile"
2. npm install
3. npm run dev

Notes:

- Add your Mapbox token in `src/pages/LiveTracker.tsx` (replace YOUR_MAPBOX_TOKEN_HERE).
- Consider moving the Supabase key to an environment variable for production.
- To build: `npm run build` and deploy to Cloudflare Pages (connect repo and set build command `npm run build`).
