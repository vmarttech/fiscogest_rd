import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.body,
    this.backgroundColor,
    this.actions,
    this.leading,
    this.appBar,
    this.padding,
    this.floatingActionButton,
  });

  final String? title;
  final Widget? body;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? appBar;
  final EdgeInsetsGeometry? padding;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final Widget? contenido = padding != null && body != null
        ? Padding(padding: padding!, child: body!)
        : body;

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar ?? _buildAppBar(),
      body: contenido,
      floatingActionButton: floatingActionButton,
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (title == null) {
      return null;
    }

    return AppBar(
      toolbarHeight: 68,
      automaticallyImplyLeading: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      titleSpacing: 4,
      leading: leading,
      title: Text(
        title!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.h4.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      actions: actions
          ?.map(
            (action) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: action,
            ),
          )
          .toList(),
      iconTheme: const IconThemeData(color: Colors.white, size: 24),
      actionsIconTheme: const IconThemeData(color: Colors.white, size: 23),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
