-- EDUCATIONAL MATERIALS: Supabase schema
-- Run this entire file in Supabase Dashboard > SQL Editor.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role text not null default 'student' check (role in ('student','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.resources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  kind text not null check (kind in ('Kitabu','Mtihani','Nyenzo nyingine')),
  subject text,
  level text,
  year integer,
  is_paid boolean not null default false,
  price_tzs integer not null default 500 check (price_tzs >= 0),
  file_path text,
  published boolean not null default false,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists public.payment_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  resource_id uuid not null references public.resources(id) on delete cascade,
  payer_name text not null,
  phone text not null,
  transaction_reference text not null,
  notes text,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique (transaction_reference)
);

create index if not exists resources_catalog_idx on public.resources (published, kind, level, subject);
create index if not exists payment_user_resource_idx on public.payment_submissions (user_id, resource_id, status);

create or replace function public.is_admin()
returns boolean language sql stable security definer
set search_path = public
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

alter table public.profiles enable row level security;
alter table public.resources enable row level security;
alter table public.payment_submissions enable row level security;

drop policy if exists "profiles read self or admin" on public.profiles;
create policy "profiles read self or admin" on public.profiles for select to authenticated
using (id = auth.uid() or public.is_admin());
drop policy if exists "profiles update self or admin" on public.profiles;
create policy "profiles update self or admin" on public.profiles for update to authenticated
using (id = auth.uid() or public.is_admin())
with check (id = auth.uid() or public.is_admin());

drop policy if exists "published resources visible" on public.resources;
create policy "published resources visible" on public.resources for select
using (published = true or public.is_admin());
drop policy if exists "admins manage resources" on public.resources;
create policy "admins manage resources" on public.resources for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "users create own payment submissions" on public.payment_submissions;
create policy "users create own payment submissions" on public.payment_submissions for insert to authenticated
with check (user_id = auth.uid() and status = 'pending');
drop policy if exists "users read own submissions or admin" on public.payment_submissions;
create policy "users read own submissions or admin" on public.payment_submissions for select to authenticated
using (user_id = auth.uid() or public.is_admin());
drop policy if exists "admins review submissions" on public.payment_submissions;
create policy "admins review submissions" on public.payment_submissions for update to authenticated
using (public.is_admin()) with check (public.is_admin());

-- Create a PRIVATE Storage bucket named "materials" in Storage, or run:
insert into storage.buckets (id, name, public)
values ('materials', 'materials', false)
on conflict (id) do update set public = false;

drop policy if exists "admins upload materials" on storage.objects;
create policy "admins upload materials" on storage.objects for insert to authenticated
with check (bucket_id = 'materials' and public.is_admin());
drop policy if exists "admins update materials" on storage.objects;
create policy "admins update materials" on storage.objects for update to authenticated
using (bucket_id = 'materials' and public.is_admin())
with check (bucket_id = 'materials' and public.is_admin());
drop policy if exists "admins delete materials" on storage.objects;
create policy "admins delete materials" on storage.objects for delete to authenticated
using (bucket_id = 'materials' and public.is_admin());
drop policy if exists "users read free or approved materials" on storage.objects;
create policy "users read free or approved materials" on storage.objects for select to authenticated
using (
  bucket_id = 'materials' and exists (
    select 1 from public.resources r
    where r.file_path = storage.objects.name
      and r.published = true
      and (
        r.is_paid = false
        or exists (
          select 1 from public.payment_submissions p
          where p.resource_id = r.id and p.user_id = auth.uid() and p.status = 'approved'
        )
      )
  )
);

-- IMPORTANT: after registering your own account, promote it to admin manually:
-- update public.profiles set role = 'admin' where id = 'YOUR-AUTH-USER-UUID';
-- Get the UUID from Authentication > Users. Never expose a service_role key in the website.
