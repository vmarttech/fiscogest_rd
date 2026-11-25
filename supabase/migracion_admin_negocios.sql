
-- =============================================
-- FiscoGest RD — Migración: Administración de Negocios
-- Ejecutar en Supabase → SQL Editor
-- =============================================

-- 1️⃣ Campos adicionales en negocios
alter table public.negocios 
  add column if not exists telefono_contacto text,
  add column if not exists correo_contacto text,
  add column if not exists suspendido_en timestamptz,
  add column if not exists motivo_suspension text,
  add column if not exists beneficio_tipo text,
  add column if not exists beneficio_inicio timestamptz,
  add column if not exists beneficio_fin timestamptz;

-- 2️⃣ Tabla: Bitácora de acciones administrativas
create table if not exists public.bitacora_admin (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references auth.users(id) on delete cascade,
  negocio_id uuid not null references public.negocios(id) on delete cascade,
  accion text not null, -- 'activar', 'suspender', 'renovar', 'modificar_plan', etc.
  valores_anteriores jsonb,
  valores_nuevos jsonb,
  motivo text,
  created_at timestamptz not null default now()
);

create index if not exists idx_bitacora_negocio
  on public.bitacora_admin (negocio_id, created_at desc);

-- 3️⃣ Tabla: Notificaciones de plataforma
create table if not exists public.notificaciones (
  id uuid primary key default gen_random_uuid(),
  tipo text not null, -- 'aviso_vencimiento', 'oferta', 'aviso_servicio'
  titulo text not null,
  mensaje text not null,
  negocio_id uuid references public.negocios(id) on delete cascade, -- null = para todos
  usuario_id uuid references public.usuarios(id) on delete cascade, -- notificacion individual
  leido boolean not null default false,
  leido_en timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists idx_notif_destinatario
  on public.notificaciones (negocio_id, leido, created_at desc);

-- 4️⃣ Función y política para bitácora (solo lectura para el dueño del negocio)
alter table public.bitacora_admin enable row level security;
alter table public.notificaciones enable row level security;

-- Políticas para notificaciones: cada usuario lee las suyas
drop policy if exists notif_propio on public.notificaciones;
create policy notif_propio on public.notificaciones
  for select to authenticated
  using (
    negocio_id::text = coalesce(
      auth.jwt() -> 'app_metadata' ->> 'negocio_id',
      ''
    )
    or usuario_id::text = auth.uid()::text
  );

-- 5️⃣ Función de ayuda: contar usuarios por negocio
create or replace function public.contar_usuarios_negocio(negocio_uuid uuid)
returns integer language sql security definer as $$
  select count(*) from public.usuarios where negocio_id = negocio_uuid;
$$;

-- 6️⃣ Tipo compuesto para listado administrativo
-- Se usará desde la función de listado
