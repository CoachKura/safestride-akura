# Deployment & Supabase configuration

This repository includes templates and CI workflows to help configure Supabase, Render and Vercel deployments.

Quick overview
- Use the `.env.example` file as a starting point for environment variables.
- The devcontainer will install the Supabase CLI (`supabase`) in the container for local workflows.
- GitHub Actions are provided to trigger Render and Vercel deployments; set the required secrets in GitHub.

Required secrets (set these in GitHub repository Settings → Secrets):
- `SUPABASE_URL` — your Supabase project URL
- `SUPABASE_ANON_KEY` — Supabase anon public key (for client use)
- `SUPABASE_SERVICE_ROLE_KEY` — Supabase service role key (for server migrations / upserts)
- `DATABASE_URL` — Postgres connection string (optional; used for local db tooling)
- `RENDER_API_KEY` — Render API key with deploy permission
- `RENDER_SERVICE_ID` — Render service id to trigger deploys for
- `VERCEL_TOKEN` — Vercel personal token
- `VERCEL_ORG_ID` — Vercel organization id
- `VERCEL_PROJECT_ID` — Vercel project id

Devcontainer
- The `.devcontainer/devcontainer.json` file will install the Supabase CLI automatically after the container is created.
- After the container is ready, run:

```bash
supabase login
```

Local Supabase & migrations
- If you use Supabase migrations, use the Supabase CLI inside the devcontainer to run them:

```bash
# Example: push migrations to your project
supabase db push --project-ref $SUPABASE_PROJECT_REF
```

Backfill missing profiles (SQL)
- To create missing `profiles` rows from `auth.users` run the SQL in the Supabase SQL editor:

```sql
INSERT INTO public.profiles (id, full_name, email, role, created_at, updated_at)
SELECT u.id,
       (COALESCE(s.name, CONCAT(u.raw_user_meta->>'fullName')) ) AS full_name,
       u.email,
       'athlete',
       NOW(),
       NOW()
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
LEFT JOIN auth.users_metadata s ON s.user_id = u.id
WHERE p.id IS NULL;
```

CI / GitHub Actions
- `/.github/workflows/deploy-render.yml` — triggers Render deploy via the Render API. Requires `RENDER_API_KEY` and `RENDER_SERVICE_ID` secrets.
- `/.github/workflows/deploy-vercel.yml` — uses `amondnet/vercel-action` to deploy `./frontend` to Vercel. Requires `VERCEL_TOKEN`, `VERCEL_ORG_ID`, and `VERCEL_PROJECT_ID`.

Notes & security
- Never store service keys in source control. Use GitHub Secrets, Render Secrets, or Vercel environment variables.
- The `SUPABASE_SERVICE_ROLE_KEY` is powerful — only use it in server-side contexts (GitHub Actions or server code), not in frontend bundles.
