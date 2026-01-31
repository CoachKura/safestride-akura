 (async function(){
  const { createClient } = await import('@supabase/supabase-js');

  const SUPABASE_URL = process.env.SUPABASE_URL;
  const SERVICE_ROLE = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!SUPABASE_URL || !SERVICE_ROLE) {
    console.error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY env vars');
    process.exit(1);
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE, { auth: { persistSession: false } });

  const delay = (ms) => new Promise((r) => setTimeout(r, ms));
  const DRY_RUN = process.env.DRY_RUN === '1' || process.argv.includes('--dry-run');
  const PER_PAGE = Number(process.env.PER_PAGE) || 100;

  async function safeUpdateUser(userId) {
    const maxRetries = 3;
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        const { data, error } = await supabase.auth.admin.updateUserById(userId, {
          email_confirm: true,
        });
        if (error) throw error;
        return data;
      } catch (err) {
        const wait = 200 * attempt;
        console.warn(`Attempt ${attempt} failed for ${userId}: ${err?.message || err}. Retrying in ${wait}ms`);
        await delay(wait);
      }
    }
    throw new Error(`Failed to update user ${userId} after retries`);
  }

  async function confirmAllUnconfirmed(batchDelayMs = 200) {
    console.log('Starting user enumeration... DRY_RUN=', DRY_RUN ? 'true' : 'false');
    let page = 1;
    let totalUpdated = 0;

    while (true) {
      const { data: users, error } = await supabase.auth.admin.listUsers({ perPage: PER_PAGE, page });
      if (error) {
        console.error('Error listing users:', error);
        throw error;
      }
      if (!users || users.length === 0) break;

      console.log(`Fetched page ${page}, ${users.length} users`);

      for (const u of users) {
        const emailConfirmed = !!u.email_confirmed_at || u.email_confirm === true;
        if (emailConfirmed) continue;

        if (DRY_RUN) {
          console.log(`[dry-run] would confirm ${u.id} (${u.email})`);
          continue;
        }

        try {
          await safeUpdateUser(u.id);
          totalUpdated++;
          console.log(`Confirmed user ${u.id} (${u.email})`);
        } catch (e) {
          console.error(`Failed to confirm ${u.id} (${u.email}):`, e);
        }

        await delay(batchDelayMs);
      }

      if (users.length < PER_PAGE) break;
      page++;
    }

    console.log(`Done. Total users confirmed: ${totalUpdated}`);
  }

  if (typeof module !== 'undefined' && require.main === module) {
    confirmAllUnconfirmed().catch((err) => {
      console.error('Script failed:', err);
      process.exit(1);
    });
  }

  // export for programmatic usage
  if (typeof module !== 'undefined') module.exports = { confirmAllUnconfirmed };

})();
