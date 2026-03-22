create table if not exists public.site_likes (
  slug text primary key,
  count integer not null default 0 check (count >= 0),
  updated_at timestamptz not null default timezone('utc', now())
);

insert into public.site_likes (slug, count)
values ('homepage', 0)
on conflict (slug) do nothing;

alter table public.site_likes enable row level security;

drop policy if exists "Public read access for site likes" on public.site_likes;
create policy "Public read access for site likes"
on public.site_likes
for select
to anon, authenticated
using (true);

create or replace function public.increment_site_like(p_slug text)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  new_count integer;
begin
  insert into public.site_likes (slug, count)
  values (p_slug, 1)
  on conflict (slug)
  do update set
    count = public.site_likes.count + 1,
    updated_at = timezone('utc', now())
  returning count into new_count;

  return new_count;
end;
$$;

grant execute on function public.increment_site_like(text) to anon, authenticated;
