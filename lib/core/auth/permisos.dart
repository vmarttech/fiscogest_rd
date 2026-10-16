import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/auth/permisos_roles.dart';

bool rutaPermitida(String path, UsuarioSesion? sesion) {
  if (sesion == null) return false;
  final p = path.split('?').first;

  if (p == '/login' ||
      p == '/splash' ||
      p == '/setup-cuenta' ||
      p == '/recuperar-clave') {
    return true;
  }

  final rol = normalizarRol(sesion.rol);

  // Cajero: estación de caja + cobro + cuentas por cobrar
  if (rol == 'Cajero') {
    return p == '/ventas/cobro' ||
        p.startsWith('/ventas/cobro/') ||
        p == '/ventas/cobrar' ||
        p.startsWith('/ventas/cobrar/');
  }

  final required = permisoParaRuta(p);
  if (required == null) return true;
  return sesion.puede(required);
}

String rutaFallback(UsuarioSesion sesion) => sesion.rutaInicio;
