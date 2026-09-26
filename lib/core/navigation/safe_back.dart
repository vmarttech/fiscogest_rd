import 'package:flutter/material.dart';
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
