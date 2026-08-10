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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.allL),
      titlePadding: AppSpacing.allM,
      contentPadding: AppSpacing.hM.copyWith(bottom: AppSpacing.m),
      actionsPadding: AppSpacing.allM,
      title: Text(title, style: AppTypography.h3),
      content: content ?? (message != null ? Text(message!, style: AppTypography.bodyMedium) : null),
      actions: actions,
    );
  }
}
