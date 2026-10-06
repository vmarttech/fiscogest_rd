import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

String _rutaAnterior(String path, String fallback) {
  if (path.startsWith('/compras/detalle/')) return '/compras/lista';
  if (path.startsWith('/compras/historial-costos/')) return '/compras';
  if (path.startsWith('/inventario/entrada/') ||
      path.startsWith('/inventario/salida/')) {
    return '/inventario';
  }
  if (path.startsWith('/diferencias-conteo-fisico/')) {
    return '/inventario-fisico/listar';
  }
  if (path.startsWith('/recepcion/')) return '/compras';
  if (path.startsWith('/reports/detalle/')) return '/reports/hub';
  if (path.startsWith('/ventas/cotizaciones/')) return '/ventas';
  if (path.startsWith('/compras/cuentas-pagar/')) {
    return '/compras/cuentas-pagar';
  }

  const rutasAnteriores = <String, String>{
    '/productos/nuevo': '/inventario',
    '/registrar-ajuste': '/lista-ajustes',
    '/lista-ajustes': '/inventario',
    '/transferencias/registrar': '/inventario',
    '/presentaciones': '/inventario',
    '/ventas/simulador-credito': '/ventas',
    '/usuarios': '/configuracion',
    '/licencia': '/configuracion',
    '/licencia/comprar': '/licencia',
    '/licencia/activar': '/licencia',
    '/licencia/admin': '/licencia',
  };
  final explicit = rutasAnteriores[path];
  if (explicit != null) return explicit;

  final slash = path.lastIndexOf('/');
  if (slash > 0) return path.substring(0, slash);
  return fallback;
}

void safeBack(BuildContext context, {String fallback = '/'}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  final path = router.routerDelegate.currentConfiguration.uri.path;
  if (path == '/' || path.isEmpty) return;
  final previous = _rutaAnterior(path, fallback);
  if (path != previous) context.go(previous);
}

/// Botón atrás del sistema (Android):
/// - Si hay historial → pop
/// - Si no está en dashboard → ir a /
/// - Si está en / → preguntar salir
Future<void> handleSystemBack(
  BuildContext context, {
  required String currentPath,
}) async {
  final router = GoRouter.of(context);

  if (router.canPop()) {
    router.pop();
    return;
  }

  if (currentPath != '/' && currentPath.isNotEmpty) {
    final previous = _rutaAnterior(currentPath, '/');
    if (previous != currentPath) context.go(previous);
    return;
  }

  final salir = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Salir'),
      content: const Text('¿Quieres salir de la app?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('No'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sí'),
        ),
      ],
    ),
  );

  if (salir == true) {
    await SystemNavigator.pop();
  }
}
