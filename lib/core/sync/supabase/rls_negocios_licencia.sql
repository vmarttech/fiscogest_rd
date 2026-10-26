-- Lectura/actualización del propio negocio (JWT app_metadata.negocio_id)
-- Ejecutar en Supabase → SQL Editor

drop policy if exists negocios_select_own on public.negocios;
drop policy if exists negocios_update_own on public.negocios;
drop policy if exists negocios_insert_authenticated on public.negocios;

create policy negocios_select_own on public.negocios
  for select to authenticated
  using (
    id::text = coalesce(
      auth.jwt() -> 'app_metadata' ->> 'negocio_id',
      ''
    )
  );

create policy negocios_update_own on public.negocios
  for update to authenticated
  using (
    id::text = coalesce(
      auth.jwt() -> 'app_metadata' ->> 'negocio_id',
      ''
    )
  )
  with check (
    id::text = coalesce(
      auth.jwt() -> 'app_metadata' ->> 'negocio_id',
      ''
    )
  );

-- Alta de negocio (registro). Ajusta si solo quieres service_role.
create policy negocios_insert_authenticated on public.negocios
  for insert to authenticated
  with check (true);

-- Opcional: anon solo si NegocioRemote.crear usa anonKey sin JWT
-- create policy negocios_insert_anon on public.negocios
--   for insert to anon with check (true);
