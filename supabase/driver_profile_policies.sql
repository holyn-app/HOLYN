-- HOLYN: permisos para la solicitud de conductor
-- Permite al usuario autenticado crear y actualizar únicamente su propio registro.

alter table public.driver_profiles enable row level security;

drop policy if exists "holyn driver own select" on public.driver_profiles;
create policy "holyn driver own select"
on public.driver_profiles
for select
to authenticated
using (user_id = auth.uid());

drop policy if exists "holyn driver own insert" on public.driver_profiles;
create policy "holyn driver own insert"
on public.driver_profiles
for insert
to authenticated
with check (user_id = auth.uid());

drop policy if exists "holyn driver own update" on public.driver_profiles;
create policy "holyn driver own update"
on public.driver_profiles
for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

select 'HOLYN - permisos de solicitud de conductor preparados correctamente' as resultado;
