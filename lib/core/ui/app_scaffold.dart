import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

class AppScaffold extends StatelessWidget {

  const AppScaffold({
    super.key,
    this.title,
    this.body,
    this.appBar,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.padding,
  });
  final String? title;
  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar ?? (title != null ? AppBar(title: Text(title!)) : null),
      drawer: drawer,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Padding(
          padding: padding ?? AppSpacing.allM,
          child: body,
        ),
      ),
    );
  }
}
