import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.body,
    this.backgroundColor,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.appBar,
    this.bottom,
    this.padding,
    this.floatingActionButton,
    this.centerTitle = false,
  });
  final String? title;
  final String? subtitle;
  final Widget? body;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final PreferredSizeWidget? appBar;
  final PreferredSizeWidget? bottom;
  final EdgeInsetsGeometry? padding;
  final Widget? floatingActionButton;
  final bool centerTitle;
  @override
  Widget build(BuildContext context) {
    final Widget? contenido = padding != null && body != null
        ? Padding(padding: padding!, child: body!)
        : body;
    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar ?? _buildAppBar(context),
      body: contenido,
      floatingActionButton: floatingActionButton,
    );
  }
  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (title == null && bottom == null) return null;
    return AppBar(
      toolbarHeight: subtitle != null ? 56 : 48,
      automaticallyImplyLeading: showBackButton && leading == null,
      leading: leading,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      titleSpacing: 4,
      centerTitle: centerTitle,
      title: title == null
          ? null
          : Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h4.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
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
      bottom: bottom ??
          PreferredSize(
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
