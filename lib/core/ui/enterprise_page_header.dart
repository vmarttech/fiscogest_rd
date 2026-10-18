import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

/// Título + subtítulo estilo Dashboard / hub.
/// [showBack]: flecha "Volver" visible en desktop (AppBar suele estar oculto).
class EnterprisePageHeader extends StatelessWidget {
  const EnterprisePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onlyDesktop = true,
    this.showBack = false,
    this.backFallbackRoute,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool onlyDesktop;
  final bool showBack;
  /// Si no hay stack, navega aquí (ej. '/sales').
  final String? backFallbackRoute;
  final VoidCallback? onBack;

  void _back(BuildContext context) {
    if (onBack != null) {
      onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else if (backFallbackRoute != null) {
      context.go(backFallbackRoute!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (onlyDesktop && !AppBreakpoints.isDesktop(context)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBack) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _back(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text(
                  'Volver',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ],
      ),
    );
  }
}
