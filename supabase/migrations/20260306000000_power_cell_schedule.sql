-- Power Cell scheduling table
create table if not exists public.power_cell_schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  power_cell_code text not null,
  power_cell_name text not null,
  scheduled_date date not null,
  scheduled_time time not null,
  notes text,
  status text not null default 'scheduled' check (status in ('scheduled', 'completed', 'skipped')),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_power_cell_schedules_user_date
  on public.power_cell_schedules(user_id, scheduled_date);

create or replace function public.touch_power_cell_schedule_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_touch_power_cell_schedule on public.power_cell_schedules;
create trigger trg_touch_power_cell_schedule
before update on public.power_cell_schedules
for each row execute function public.touch_power_cell_schedule_updated_at();

alter table public.power_cell_schedules enable row level security;

drop policy if exists "Users can view own schedules" on public.power_cell_schedules;
create policy "Users can view own schedules" on public.power_cell_schedules
for select using (auth.uid() = user_id);

drop policy if exists "Users can insert own schedules" on public.power_cell_schedules;
create policy "Users can insert own schedules" on public.power_cell_schedules
for insert with check (auth.uid() = user_id);

drop policy if exists "Users can update own schedules" on public.power_cell_schedules;
create policy "Users can update own schedules" on public.power_cell_schedules
for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users can delete own schedules" on public.power_cell_schedules;
create policy "Users can delete own schedules" on public.power_cell_schedules
for delete using (auth.uid() = user_id);
