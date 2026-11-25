
-- =============================================
-- Función: admin_listar_negocios
-- Ejecutar en Supabase → SQL Editor
-- =============================================

create or replace function public.admin_listar_negocios(
  busqueda text default null,
  filtro_estado text default null,
  limite integer default 50,
  desplazamiento integer default 0
)
returns table (
  id uuid,
  nombre text,
  rnc text,
  telefono_contacto text,
  correo_contacto text,
  plan text,
  estado text,
  vigencia_tipo text,
  fecha_inicio timestamptz,
  fecha_fin timestamptz,
  created_at timestamptz,
  usuarios_activos integer,
  es_prueba boolean,
  dias_restantes integer
)
language plpgsql
security definer
as $$
declare
  es_admin boolean;
begin
  -- ✅ Validar que sea administrador/dueño de plataforma
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'es_dueno')::boolean, false) into es_admin;
  if es_admin is not true then
    raise exception 'Acceso denegado: solo administradores de plataforma';
  end if;

  return query
  select
    n.id,
    n.nombre,
    n.rnc,
    n.telefono_contacto,
    n.correo_contacto,
    n.plan,
    n.estado,
    n.vigencia_tipo,
    n.fecha_inicio,
    n.fecha_fin,
    n.created_at,
    (select count(*) from public.usuarios u where u.negocio_id = n.id and u.activo = true) as usuarios_activos,
    case when n.beneficio_tipo = 'prueba' then true else false end as es_prueba,
    case 
      when n.fecha_fin is null then null
      then extract(day from n.fecha_fin - now())::integer
    end as dias_restantes
  from public.negocios n
  where 1=1
    and (busqueda is null or busqueda = ''
         or n.nombre ilike '%' || busqueda || '%'
         or n.rnc ilike '%' || busqueda || '%'
         or n.telefono_contacto ilike '%' || busqueda || '%')
    and (filtro_estado is null or filtro_estado = '' or n.estado = filtro_estado)
  order by n.created_at desc
  limit limite
  offset desplazamiento;
end;
$$;

-- =============================================
-- Funciones de acción protegidas
-- =============================================

create or replace function public.admin_renovar_licencia(
  negocio_uuid uuid,
  nuevo_plan text,
  nueva_vigencia_tipo text,
  nueva_fecha_fin timestamptz,
  motivo text default null
) returns boolean
language plpgsql
security definer
as $$
declare
  es_admin boolean;
  datos_anteriores jsonb;
begin
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'es_dueno')::boolean, false) into es_admin;
  if es_admin is not true then
    raise exception 'Acceso denegado';
  end if;

  -- Guardar estado anterior
  select jsonb_build_object(
    'plan', plan,
    'estado', estado,
    'vigencia_tipo', vigencia_tipo,
    'fecha_fin', fecha_fin
  ) into datos_anteriores
  from public.negocios where id = negocio_uuid;

  -- Actualizar
  update public.negocios
  set plan = nuevo_plan,
      vigencia_tipo = nueva_vigencia_tipo,
      fecha_fin = nueva_fecha_fin,
      updated_at = now()
  where id = negocio_uuid;

  -- Registrar en bitácora
  insert into public.bitacora_admin
    (actor_id, negocio_id, accion, valores_anteriores, valores_nuevos, motivo)
  values
    (auth.uid(), negocio_uuid, 'renovar', datos_anteriores,
     jsonb_build_object(
       'plan', nuevo_plan,
       'vigencia_tipo', nueva_vigencia_tipo,
       'fecha_fin', nueva_fecha_fin
     ), motivo);

  return true;
end;
$$;

create or replace function public.admin_cambiar_estado_negocio(
  negocio_uuid uuid,
  nuevo_estado text,
  motivo text default null
) returns boolean
language plpgsql
security definer
as $$
declare
  es_admin boolean;
  datos_anteriores jsonb;
begin
  select coalesce((auth.jwt() -> 'app_metadata' ->> 'es_dueno')::boolean, false) into es_admin;
  if es_admin is not true then
    raise exception 'Acceso denegado';
  end if;

  select jsonb_build_object('estado', estado) into datos_anteriores
  from public.negocios where id = negocio_uuid;

  update public.negocios
  set estado = nuevo_estado,
      suspendido_en = case when nuevo_estado = 'suspendida' then now() else null end,
      motivo_suspension = case when nuevo_estado = 'suspendida' then motivo else null end,
      updated_at = now()
  where id = negocio_uuid;

  insert into public.bitacora_admin
    (actor_id, negocio_id, accion, valores_anteriores, valores_nuevos, motivo)
  values
    (auth.uid(), negocio_uuid, 'cambiar_estado', datos_anteriores,
     jsonb_build_object('estado', nuevo_estado), motivo);

  return true;
end;
$$;
