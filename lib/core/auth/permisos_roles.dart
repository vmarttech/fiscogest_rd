/// API global de autorización.
/// Nuevos módulos = nuevo código de permiso + asignarlo a roles.
/// Nuevos perfiles = entrada en [permisosPorRol] + [rutaInicioPorRol].
library;

// ─── Códigos de permiso (estables) ─────────────────────────────────────────
class Permiso {
  static const dashboardVer = 'dashboard.ver';
  static const ventasCotizar = 'ventas.cotizar';
  static const ventasHistorial = 'ventas.historial';
  static const cajaCobrar = 'caja.cobrar';
  static const inventarioVer = 'inventario.ver';
  static const inventarioEditar = 'inventario.editar';
  static const clientesVer = 'clientes.ver';
  static const clientesEditar = 'clientes.editar';
  static const catalogoGestionar = 'catalogo.gestionar';
  static const comprasGestionar = 'compras.gestionar';
  static const creditosGestionar = 'creditos.gestionar';
  static const facturacionGestionar = 'facturacion.gestionar';
  static const reportesVer = 'reportes.ver';
  static const configAdmin = 'config.admin';
  static const usuariosGestionar = 'usuarios.gestionar';
  static const fiaoUsar = 'fiao.usar';
  static const kardexVer = 'kardex.ver';

  /// Todos los códigos conocidos (documentación / UI futura).
  static const todos = <String>{
    dashboardVer,
    ventasCotizar,
    ventasHistorial,
    cajaCobrar,
    inventarioVer,
    inventarioEditar,
    clientesVer,
    clientesEditar,
    catalogoGestionar,
    comprasGestionar,
    creditosGestionar,
    facturacionGestionar,
    reportesVer,
    configAdmin,
    usuariosGestionar,
    fiaoUsar,
    kardexVer,
  };
}

/// Roles disponibles al crear usuarios (se puede ampliar sin tocar pantallas).
const rolesDisponibles = <String>[
  'Admin',
  'Vendedor',
  'Cajero',
  'Creditos',
  'Gerente',
  'Compras',
];

/// Matriz rol → permisos. Admin usa comodín '*'.
const Map<String, Set<String>> permisosPorRol = {
  'Admin': {'*'},
  'Vendedor': {
    Permiso.ventasCotizar,
    Permiso.ventasHistorial,
    Permiso.inventarioVer,
    Permiso.clientesVer,
    Permiso.clientesEditar,
  },
  'Cajero': {
    // Solo estación de caja / cobro. Sin cotizar ni inventario.
    Permiso.cajaCobrar,
  },
  'Creditos': {
    Permiso.creditosGestionar,
    Permiso.clientesVer,
    Permiso.dashboardVer,
  },
  'Gerente': {
    Permiso.dashboardVer,
    Permiso.ventasCotizar,
    Permiso.ventasHistorial,
    Permiso.cajaCobrar,
    Permiso.inventarioVer,
    Permiso.clientesVer,
    Permiso.clientesEditar,
    Permiso.reportesVer,
    Permiso.facturacionGestionar,
    // sin compras, sin config, sin usuarios
  },
  'Compras': {
    Permiso.comprasGestionar,
    Permiso.catalogoGestionar,
    Permiso.inventarioVer,
    Permiso.dashboardVer,
  },
};

/// Ruta inicial post-login por rol.
const Map<String, String> rutaInicioPorRol = {
  'Admin': '/',
  'Vendedor': '/ventas',
  'Cajero': '/ventas/cobro',
  'Creditos': '/creditos',
  'Gerente': '/',
  'Compras': '/compras',
};

/// Normaliza nombre de rol de BD ("vendedor", "Administrador", etc.).
String normalizarRol(String rol) {
  final r = rol.trim().toLowerCase();
  if (r == 'admin' || r == 'administrador') return 'Admin';
  if (r.contains('vendedor')) return 'Vendedor';
  if (r.contains('cajero') || r == 'caja') return 'Cajero';
  if (r.contains('credito')) return 'Creditos';
  if (r.contains('gerente')) return 'Gerente';
  if (r.contains('compra')) return 'Compras';
  // Si ya viene exacto
  for (final k in permisosPorRol.keys) {
    if (k.toLowerCase() == r) return k;
  }
  return rol.trim().isEmpty ? 'Vendedor' : rol.trim();
}

bool rolTienePermiso(String rol, String permiso) {
  final key = normalizarRol(rol);
  final set = permisosPorRol[key];
  if (set == null) return false;
  if (set.contains('*')) return true;
  return set.contains(permiso);
}

String rutaInicioParaRol(String rol) {
  final key = normalizarRol(rol);
  return rutaInicioPorRol[key] ?? '/';
}

/// Ruta de la app → permiso mínimo (null = solo autenticado / público controlado).
String? permisoParaRuta(String path) {
  final p = path.split('?').first;
  if (p == '/login' ||
      p == '/splash' ||
      p == '/setup-cuenta' ||
      p == '/recuperar-clave') {
    return null; // público
  }
  if (p == '/') return Permiso.dashboardVer;
  if (p.startsWith('/ventas/cobro')) return Permiso.cajaCobrar;
  if (p.startsWith('/ventas/fios')) return Permiso.fiaoUsar;
  if (p.startsWith('/ventas')) return Permiso.ventasCotizar;
  if (p.startsWith('/inventario') || p.startsWith('/kardex')) {
    return p.startsWith('/kardex') ? Permiso.kardexVer : Permiso.inventarioVer;
  }
  if (p.startsWith('/clientes')) return Permiso.clientesVer;
  if (p.startsWith('/proveedores') ||
      p.startsWith('/categorias') ||
      p.startsWith('/marcas') ||
      p.startsWith('/unidades') ||
      p.startsWith('/presentaciones')) {
    return Permiso.catalogoGestionar;
  }
  if (p.startsWith('/compras')) return Permiso.comprasGestionar;
  if (p.startsWith('/creditos')) return Permiso.creditosGestionar;
  if (p.startsWith('/sales') || p.startsWith('/facturacion')) {
    return Permiso.facturacionGestionar;
  }
  if (p.startsWith('/reports') || p.startsWith('/impuestos')) {
    return Permiso.reportesVer;
  }
  if (p.startsWith('/configuracion') || p.startsWith('/import-export')) {
    return Permiso.configAdmin;
  }
  if (p.startsWith('/usuarios')) return Permiso.usuariosGestionar;
  // Desconocido: solo admin (*) pasará si se usa rolTienePermiso con check admin
  return Permiso.configAdmin;
}
