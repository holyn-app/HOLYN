-- HOLYN: verificación documental de conductores
-- Ejecutar en Supabase > SQL Editor.
-- Este script NO aprueba conductores automáticamente.

create table if not exists public.driver_verification_documents (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.driver_profiles(user_id) on delete cascade,
  document_type text not null check (document_type in (
    'driver_face',
    'license_front',
    'license_back',
    'vehicle_card_front',
    'vehicle_card_back'
  )),
  storage_path text not null,
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  rejection_reason text,
  reviewed_by uuid references public.profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  unique(driver_id, document_type)
);

alter table public.driver_verification_documents enable row level security;

-- El conductor puede ver/gestionar únicamente sus propios documentos.
drop policy if exists "driver documents own select" on public.driver_verification_documents;
create policy "driver documents own select"
on public.driver_verification_documents
for select
to authenticated
using (driver_id = auth.uid());

drop policy if exists "driver documents own insert" on public.driver_verification_documents;
create policy "driver documents own insert"
on public.driver_verification_documents
for insert
to authenticated
with check (driver_id = auth.uid());

drop policy if exists "driver documents own update" on public.driver_verification_documents;
create policy "driver documents own update"
on public.driver_verification_documents
for update
to authenticated
using (driver_id = auth.uid())
with check (driver_id = auth.uid());

-- Administración puede revisar todos los documentos.
drop policy if exists "admin documents select" on public.driver_verification_documents;
create policy "admin documents select"
on public.driver_verification_documents
for select
to authenticated
using (public.is_admin());

drop policy if exists "admin documents update" on public.driver_verification_documents;
create policy "admin documents update"
on public.driver_verification_documents
for update
to authenticated
using (public.is_admin())
with check (public.is_admin());

-- Bucket privado para documentación sensible.
insert into storage.buckets (id, name, public)
values ('driver-documents', 'driver-documents', false)
on conflict (id) do update set public = false;

-- Archivos privados: el conductor solo puede operar dentro de su propia carpeta.
drop policy if exists "driver documents storage insert" on storage.objects;
create policy "driver documents storage insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'driver-documents'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "driver documents storage select own" on storage.objects;
create policy "driver documents storage select own"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'driver-documents'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
  )
);

drop policy if exists "driver documents storage update own" on storage.objects;
create policy "driver documents storage update own"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'driver-documents'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
  )
)
with check (
  bucket_id = 'driver-documents'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
  )
);

drop policy if exists "driver documents storage delete own" on storage.objects;
create policy "driver documents storage delete own"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'driver-documents'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
  )
);

select 'HOLYN - documentos de conductores preparados correctamente' as resultado;
