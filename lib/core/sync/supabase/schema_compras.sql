-- Tablas de compras para sync (negocio_id + id_local)
-- Ejecutar UNA vez en Supabase → SQL Editor

create table if not exists public.compras (
  negocio_id uuid not null,
  id_local bigint not null,
  proveedor_id_local integer,
  nombre_proveedor text,
  numero_comprobante text,
  tipo_comprobante text,
  ncf text,
  forma_pago text,
  condicion_pago text,
  dias_credito integer default 0,
  fecha_emision timestamptz,
  fecha_confirmacion timestamptz,
  fecha_vencimiento timestamptz,
  fecha_recepcion timestamptz,
  fecha_pago timestamptz,
  subtotal_sin_impuestos double precision default 0,
  monto_descuento_global double precision default 0,
  tasa_impuesto double precision default 0,
  monto_impuesto double precision default 0,
  total_compra double precision default 0,
  estado text,
  observaciones text,
  creado_en timestamptz,
  actualizado_en timestamptz,
  updated_at timestamptz default now(),
  primary key (negocio_id, id_local)
);

create table if not exists public.compras_detalle (
  negocio_id uuid not null,
  id_local text not null,
  compra_id_local bigint not null,
  producto_id_local integer,
  nombre_producto text,
  cantidad double precision default 0,
  costo_unitario double precision default 0,
  flete_unitario double precision default 0,
  seguro_unitario double precision default 0,
  aranceles_unitario double precision default 0,
  gastos_unitario double precision default 0,
  descuento_porcentaje double precision default 0,
  monto_descuento_linea double precision default 0,
  subtotal_linea double precision default 0,
  base_imponible_linea double precision default 0,
  itbis_linea double precision default 0,
  total_linea double precision default 0,
  costo_adquisicion double precision default 0,
  updated_at timestamptz default now(),
  primary key (negocio_id, id_local)
);

create index if not exists idx_compras_negocio on public.compras (negocio_id);
create index if not exists idx_compras_detalle_compra
  on public.compras_detalle (negocio_id, compra_id_local);
