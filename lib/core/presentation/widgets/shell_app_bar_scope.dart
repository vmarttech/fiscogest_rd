import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/core/presentation/providers/shell_app_bar_provider.dart';

/// Publica acciones en la AppBar del shell (si se usa).
class ShellAppBarScope extends ConsumerStatefulWidget {
  const ShellAppBarScope({
    super.key,
    required this.child,
    this.actions = const [],
    this.titleOverride,
  });

  final Widget child;
  final List<Widget> actions;
  final String? titleOverride;

  @override
  ConsumerState<ShellAppBarScope> createState() => _ShellAppBarScopeState();
}

class _ShellAppBarScopeState extends ConsumerState<ShellAppBarScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
  }

  @override
  void didUpdateWidget(covariant ShellAppBarScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actions != widget.actions ||
        oldWidget.titleOverride != widget.titleOverride) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _publish());
    }
  }

  void _publish() {
    if (!mounted) return;
    try {
      ref
          .read(shellAppBarProvider.notifier)
          .set(actions: widget.actions, titleOverride: widget.titleOverride);
    } catch (_) {
      // Widget desmontado o provider no disponible
    }
  }

  @override
  void dispose() {
    // NUNCA usar ref ni context aquí → Bad state: Cannot use "ref" after disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
