import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

class AppHubHero extends StatelessWidget {
  const AppHubHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isMobile = AppBreakpoints.isMobile(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 12 : 22,
        isMobile ? 16 : 24,
        isMobile ? 12 : 22,
      ),
        decoration: BoxDecoration(
          color: scheme.surface,
        borderRadius: BorderRadius.circular(isMobile ? 14 : 20),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
              color: const Color(0x140F172A),
              blurRadius: isMobile ? 12 : 18,
              offset: Offset(0, isMobile ? 4 : 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
            ),
            child: Icon(icon, color: scheme.primary, size: isMobile ? 20 : 28),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: (isMobile ? AppTypography.bodyLarge : AppTypography.h4)
                      .copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (!isMobile) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.25,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
