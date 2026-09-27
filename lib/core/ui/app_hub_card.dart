import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

/// Tarjeta de hub con acento de color y sensación premium / futurista.
class AppHubCard extends StatefulWidget {
  const AppHubCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<AppHubCard> createState() => _AppHubCardState();
}

class _AppHubCardState extends State<AppHubCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Color.lerp(Colors.white, c, 0.04)!,
                  ],
                ),
                border: Border.all(
                  color: _hover
                      ? c.withValues(alpha: 0.45)
                      : AppColors.border,
                  width: _hover ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: c.withValues(alpha: _hover ? 0.18 : 0.08),
                    blurRadius: _hover ? 22 : 14,
                    offset: Offset(0, _hover ? 10 : 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // Acento superior
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              c,
                              c.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Brillo suave de fondo
                    Positioned(
                      right: -24,
                      bottom: -24,
                      child: IgnorePointer(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                c.withValues(alpha: 0.10),
                                c.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icono con “glow”
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  c.withValues(alpha: 0.18),
                                  c.withValues(alpha: 0.08),
                                ],
                              ),
                              border: Border.all(
                                color: c.withValues(alpha: 0.22),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(widget.icon, color: c, size: 28),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.title,
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              widget.subtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.35,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _hover
                                    ? c.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: _hover ? c : AppColors.grey400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
