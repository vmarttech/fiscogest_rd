-- Ejecutar en Supabase cuando conectemos la nube.
-- Table: dispositivos_licencia

create table if not exists public.dispositivos_licencia (
  id uuid primary key default gen_random_uuid(),
  negocio_id uuid references public.negocios(id) on delete cascade,
  fingerprint text not null,
  alias text not null default 'Este equipo',
  plataforma text not null,
  tipo text not null default 'pc', -- pc | movil | tablet | otro
  activo boolean not null default true,
  registrado_en timestamptz not null default now(),
  ultimo_uso timestamptz not null default now(),
  unique (negocio_id, fingerprint)
);

create index if not exists idx_dispositivos_negocio
  on public.dispositivos_licencia (negocio_id);

alter table public.dispositivos_licencia enable row level security;
-- Policies: usuario autenticado solo ve filas de su negocio_id
