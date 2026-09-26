import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

void safeBack(BuildContext context, {String fallback = '/'}) {
  final router = GoRouter.of(context);
  if (router.canPop()) {
    router.pop();
    return;
  }
  final path = router.routerDelegate.currentConfiguration.uri.path;
  if (path == fallback || path == '/' || path.isEmpty) return;
  context.go(fallback);
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
    context.go('/');
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
