-- FiscoGest RD · Supabase schema FASE 1
-- Todo en snake_case minúsculas (sin comillas en nombres)

create extension if not exists "pgcrypto";

create table if not exists public.negocios (
  id uuid primary key default gen_random_uuid(),
  codigo text unique,
  nombre text not null default 'Mi negocio',
  rnc text,
  plan text not null default 'demo',
  max_dispositivos int not null default 1,
  max_cajas int not null default 1,
  ecf_habilitado boolean not null default false,
  vitalicia boolean not null default false,
  estado text not null default 'activa',
  vigencia_tipo text,
  fecha_inicio timestamptz,
  fecha_fin timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.dispositivos_licencia (
  id uuid primary key default gen_random_uuid(),
  negocio_id uuid not null references public.negocios(id) on delete cascade,
  fingerprint text not null,
  alias text not null default 'Este equipo',
  plataforma text not null,
  tipo text not null default 'pc',
  activo boolean not null default true,
  registrado_en timestamptz not null default now(),
  ultimo_uso timestamptz not null default now(),
  unique (negocio_id, fingerprint)
);

create index if not exists idx_dispositivos_negocio
  on public.dispositivos_licencia (negocio_id);

create table if not exists public.pedidos_licencia (
  id uuid primary key default gen_random_uuid(),
  negocio_id uuid references public.negocios(id) on delete set null,
  referencia text not null unique,
  plan text not null,
  vigencia_tipo text not null,
  monto numeric(12,2) not null default 0,
  estado text not null default 'pendiente',
  created_at timestamptz not null default now(),
  expires_at timestamptz
);

create table if not exists public.usuarios (
  id uuid primary key default gen_random_uuid(),
  negocio_id uuid not null references public.negocios(id) on delete cascade,
  id_local int,
  username text not null,
  nombre text,
  rol text not null default 'vendedor',
  activo boolean not null default true,
  updated_at timestamptz not null default now(),
  unique (negocio_id, username)
);

alter table public.negocios enable row level security;
alter table public.dispositivos_licencia enable row level security;
alter table public.pedidos_licencia enable row level security;
alter table public.usuarios enable row level security;

create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_negocios_updated on public.negocios;
create trigger trg_negocios_updated
  before update on public.negocios
  for each row execute function public.set_updated_at();
