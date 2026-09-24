-- Бондоолой: friends + leaderboard schema.
-- Paste this whole file into Supabase Dashboard -> SQL Editor -> Run.
-- Also enable: Authentication -> Sign In / Providers -> "Allow anonymous sign-ins".

create table if not exists public.profiles (
  id uuid primary key references auth.users on delete cascade,
  name text not null check (char_length(name) between 1 and 30),
  friend_code text unique not null,
  created_at timestamptz not null default now()
);

create table if not exists public.friendships (
  user_id uuid not null references public.profiles(id) on delete cascade,
  friend_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id)
);

create table if not exists public.daily_steps (
  user_id uuid not null references public.profiles(id) on delete cascade,
  day date not null,
  steps integer not null default 0 check (steps >= 0 and steps < 200000),
  primary key (user_id, day)
);

alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.daily_steps enable row level security;

drop policy if exists "profiles: read own" on public.profiles;
create policy "profiles: read own" on public.profiles
  for select to authenticated using (id = auth.uid());
drop policy if exists "profiles: insert own" on public.profiles;
create policy "profiles: insert own" on public.profiles
  for insert to authenticated with check (id = auth.uid());
drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: update own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "friendships: read own" on public.friendships;
create policy "friendships: read own" on public.friendships
  for select to authenticated using (user_id = auth.uid());

drop policy if exists "steps: read own" on public.daily_steps;
create policy "steps: read own" on public.daily_steps
  for select to authenticated using (user_id = auth.uid());
drop policy if exists "steps: insert own" on public.daily_steps;
create policy "steps: insert own" on public.daily_steps
  for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "steps: update own" on public.daily_steps;
create policy "steps: update own" on public.daily_steps
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Add a friend by their code. Creates the friendship in both directions.
create or replace function public.add_friend(code text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  f public.profiles;
begin
  if auth.uid() is null then
    raise exception 'not_signed_in';
  end if;
  select * into f from public.profiles where friend_code = upper(trim(code));
  if f.id is null then
    raise exception 'not_found';
  end if;
  if f.id = auth.uid() then
    raise exception 'self';
  end if;
  insert into public.friendships (user_id, friend_id)
  values (auth.uid(), f.id), (f.id, auth.uid())
  on conflict do nothing;
  return json_build_object('id', f.id, 'name', f.name);
end;
$$;

-- Total steps since `since` (inclusive) for the caller and their friends.
create or replace function public.leaderboard(since date)
returns table (user_id uuid, name text, steps bigint)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.name, coalesce(sum(d.steps), 0)::bigint as steps
  from public.profiles p
  left join public.daily_steps d on d.user_id = p.id and d.day >= since
  where p.id = auth.uid()
     or p.id in (select friend_id from public.friendships where user_id = auth.uid())
  group by p.id, p.name
  order by steps desc, p.name;
$$;

revoke all on function public.add_friend(text) from public, anon;
grant execute on function public.add_friend(text) to authenticated;
revoke all on function public.leaderboard(date) from public, anon;
grant execute on function public.leaderboard(date) to authenticated;
