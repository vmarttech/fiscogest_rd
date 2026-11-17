-- Bucket publico de fotos del catalogo gastronomico. Supabase > SQL Editor.
-- Idempotente (puede correrse varias veces).

insert into storage.buckets (id, name, public)
values ('catalogo', 'catalogo', true)
on conflict (id) do update set public = excluded.public;

drop policy if exists "catalogo_public_read" on storage.objects;
drop policy if exists "catalogo_anon_insert" on storage.objects;
drop policy if exists "catalogo_anon_update" on storage.objects;

create policy "catalogo_public_read" on storage.objects
  for select using (bucket_id = 'catalogo');

create policy "catalogo_anon_insert" on storage.objects
  for insert to anon
  with check (bucket_id = 'catalogo');

create policy "catalogo_anon_update" on storage.objects
  for update to anon
  using (bucket_id = 'catalogo')
  with check (bucket_id = 'catalogo');

alter table if exists public.gastro_productos_meta
  add column if not exists foto_remota_key text;
alter table if exists public.gastro_productos_meta
  add column if not exists foto_sincronizado boolean not null default false;
