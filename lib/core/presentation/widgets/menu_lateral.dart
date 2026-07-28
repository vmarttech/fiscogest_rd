import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

// Elemento individual del menú
Widget menuLateral({
  required IconData icono,
  required String texto,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icono, color: AppColors.textSecondary),
    title: Text(texto, style: AppTypography.labelMedium),
    onTap: onTap,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.allM),
    contentPadding: AppSpacing.hM.copyWith(top: AppSpacing.xs, bottom: AppSpacing.xs),
  );
}

// Contenedor adaptable del menú lateral
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final drawerWidth = AppBreakpoints.isMobile(context) ? 260.0 : 320.0;

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        child: child,
      ),
    );
  }
}
