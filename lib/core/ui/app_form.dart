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
    if (AppBreakpoints.isMobile(context)) {
      return columnsMobile.clamp(1, columnsMobile);
    }

    if (AppBreakpoints.isTablet(context)) {
      return columnsTablet.clamp(1, columnsTablet);
    }

    return columnsDesktop.clamp(1, columnsDesktop);
  }

  @override
  Widget build(BuildContext context) {
    final columns = _getColumns(context);

    final rows = <Widget>[];

    for (var i = 0; i < fields.length; i += columns) {
      final rowFields = <Widget>[];

      for (var column = 0; column < columns; column++) {
        final fieldIndex = i + column;

        if (column > 0) {
          rowFields.add(const SizedBox(width: AppSpacing.m));
        }

        if (fieldIndex < fields.length) {
          rowFields.add(Expanded(child: fields[fieldIndex]));
        } else {
          rowFields.add(const Expanded(child: SizedBox()));
        }
      }

      rows.add(
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowFields),
      );

      if (i + columns < fields.length) {
        rows.add(const SizedBox(height: AppSpacing.m));
      }
    }

    return Padding(
      padding: padding ?? AppSpacing.allM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
    );
  }
}
