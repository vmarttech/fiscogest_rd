
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';

/// Rutas permitidas. Admin = todo. Vendedor/Cajero = su área.
bool rutaPermitida(String path, UsuarioSesion? sesion) {
  if (sesion == null) return false;
  if (sesion.esAdmin) return true;

  final p = path.split('?').first;
  final rol = sesion.rol.toLowerCase();

  // Rutas públicas de auth
  if (p == '/login' || p == '/splash' || p == '/setup-cuenta' || p == '/recuperar-clave') {
    return true;
  }

  if (rol.contains('vendedor')) {
    // Sin dashboard: home no permitido (router manda a /ventas)
    if (p == '/') return false;
    if (p == '/clientes' || p.startsWith('/clientes/')) return true;
    if (p == '/inventario' || p.startsWith('/inventario')) return true;
    if (p == '/ventas' || p.startsWith('/ventas/')) {
      if (p.startsWith('/ventas/cobro')) return false;
      if (p.startsWith('/ventas/fios')) return false;
      return true;
    }
    return false;
  }

  if (rol.contains('cajero')) {
    // Sin dashboard; foco en caja
    if (p == '/') return false;
    if (p == '/ventas' || p.startsWith('/ventas/')) return true;
    return false;
  }

  return false;
}
