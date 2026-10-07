import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_radius.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    required this.actions,
    this.content,
  });
  final String title;
  final String? message;
  final List<Widget> actions;
  final Widget? content;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    String? message,
    List<Widget> actions = const [],
    Widget? content,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: title,
        message: message,
        actions: actions,
        content: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cuerpo =
        content ??
        (message != null
            ? Text(message!, style: AppTypography.bodyMedium)
            : null);
    final altoMaximo = MediaQuery.sizeOf(context).height * 0.85;

    // Dialog evita el RenderIntrinsicWidth de AlertDialog. Es importante para
    // acciones personalizadas que usan LayoutBuilder, como AppButton.
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.allL),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: altoMaximo),
        child: Padding(
          padding: AppSpacing.allM,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.h3),
              if (cuerpo != null) ...[
                const SizedBox(height: AppSpacing.m),
                Flexible(
                  child: SingleChildScrollView(
                    padding: AppSpacing.hM.copyWith(
                      bottom: AppSpacing.m,
                      left: 0,
                      right: 0,
                    ),
                    child: cuerpo,
                  ),
                ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: AppSpacing.s,
                  overflowSpacing: AppSpacing.xs,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
