-- Tablas remotas del modulo Gastronomia RD (Supabase).
-- Ejecutar una sola vez en el SQL Editor de Supabase.
create table if not exists public.gastro_extras (
  negocio_id text not null, id_local int not null,
  nombre text, precio numeric, activo boolean, creado_en timestamptz,
  primary key (negocio_id, id_local)
);
create table if not exists public.gastro_producto_extras (
  negocio_id text not null, id_local int not null,
  producto_id_local int, extra_id_local int, activo boolean,
  primary key (negocio_id, id_local)
);
create table if not exists public.gastro_sectores (
  negocio_id text not null, id_local int not null,
  nombre text, tarifa_envio numeric, monto_minimo_envio_gratis numeric,
  orden int, activo boolean, creado_en timestamptz,
  primary key (negocio_id, id_local)
);
create table if not exists public.gastro_repartidores (
  negocio_id text not null, id_local int not null,
  nombre text, telefono text, activo boolean, creado_en timestamptz,
  primary key (negocio_id, id_local)
);
create table if not exists public.gastro_productos_meta (
  negocio_id text not null, id_local int not null,
  producto_id_local int, foto_path text, es_gastronomico boolean,
  destacado boolean, disponible_menu boolean, actualizado_en timestamptz,
  primary key (negocio_id, id_local)
);
create table if not exists public.gastro_categorias_meta (
  negocio_id text not null, id_local int not null,
  categoria_id_local int, visible_en_menu boolean, orden_menu int,
  primary key (negocio_id, id_local)
);
create table if not exists public.gastro_pedidos (
  negocio_id text not null, id_local int not null,
  uuid text, tipo text, estado text, cliente_id_local int,
  nombre_cliente text, telefono text, sector_id_local int,
  direccion_referencia text, costo_envio numeric, subtotal numeric,
  itbis numeric, descuento numeric, total numeric, forma_pago text,
  venta_id_local int, repartidor_id_local int, estado_entrega text,
  notas text, usuario_id_local int, fecha timestamptz, sincronizado boolean,
  primary key (negocio_id, id_local)
);
create index if not exists gastro_pedidos_uuid_idx on public.gastro_pedidos (uuid);
create table if not exists public.gastro_pedido_lineas (
  negocio_id text not null, id_local int not null,
  pedido_id_local int, producto_id_local int, nombre_snapshot text,
  cantidad numeric, precio_unitario numeric, subtotal numeric, notas text,
  primary key (negocio_id, id_local)
);
create table if not exists public.gastro_pedido_linea_extras (
  negocio_id text not null, id_local int not null,
  linea_id_local int, extra_id_local int, nombre_snapshot text,
  precio_snapshot numeric,
  primary key (negocio_id, id_local)
);
create table if not exists public.gastro_pedidos_web (
  uuid text not null primary key, negocio_id text not null,
  tipo text, estado text, nombre_cliente text, telefono text,
  direccion_referencia text, costo_envio numeric, subtotal numeric,
  itbis numeric, descuento numeric, total numeric, forma_pago text,
  notas text, creado_en timestamptz default now()
);
do $$
declare t text;
begin
  foreach t in array array[
    'gastro_extras','gastro_producto_extras','gastro_sectores','gastro_repartidores',
    'gastro_productos_meta','gastro_categorias_meta','gastro_pedidos',
    'gastro_pedido_lineas','gastro_pedido_linea_extras','gastro_pedidos_web'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "auth_full" on public.%I', t);
    execute format('create policy "auth_full" on public.%I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;
