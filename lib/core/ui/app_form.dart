import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/core/ui/app_spacing.dart';

class AppForm extends StatelessWidget {

  const AppForm({
    super.key,
    required this.fields,
    this.columnsMobile = 1,
    this.columnsTablet = 2,
    this.columnsDesktop = 3,
    this.padding,
  });
  final List<Widget> fields;
  final int columnsMobile;
  final int columnsTablet;
  final int columnsDesktop;
  final EdgeInsetsGeometry? padding;

  int _getColumns(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) return columnsMobile;
    if (AppBreakpoints.isTablet(context)) return columnsTablet;
    return columnsDesktop;
  }

  @override
  Widget build(BuildContext context) {
    final columns = _getColumns(context);

    return Padding(
      padding: padding ?? AppSpacing.allM,
      child: Wrap(
        spacing: AppSpacing.m,
        runSpacing: AppSpacing.m,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: fields.map((field) {
          return SizedBox(
            width: MediaQuery.of(context).size.width / columns - AppSpacing.m * 1.5,
            child: field,
          );
        }).toList(),
      ),
    );
  }
}
