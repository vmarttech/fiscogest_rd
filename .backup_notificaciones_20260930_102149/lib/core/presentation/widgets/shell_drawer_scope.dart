import 'package:flutter/material.dart';

class ShellDrawerScope extends InheritedWidget {
  const ShellDrawerScope({
    super.key,
    required this.openDrawer,
    required super.child,
  });

  final VoidCallback openDrawer;

  static ShellDrawerScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellDrawerScope>();

  static void open(BuildContext context) => maybeOf(context)?.openDrawer();

  @override
  bool updateShouldNotify(ShellDrawerScope oldWidget) =>
      openDrawer != oldWidget.openDrawer;
}
