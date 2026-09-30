import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';

/// Fondo de “producto premium”: gradiente frío + glow suave del acento.
class AppAtmosphere extends StatelessWidget {
  const AppAtmosphere({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Base
        const ColoredBox(color: Color(0xFFEEF2F6)),
        // Glow superior-izquierda (teal)
        Positioned(
          top: -120,
          left: -80,
          child: IgnorePointer(
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Glow inferior-derecha (slate)
        Positioned(
          bottom: -100,
          right: -60,
          child: IgnorePointer(
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF64748B).withValues(alpha: 0.08),
                    const Color(0xFF64748B).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
