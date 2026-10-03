import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

class AppAccessGrid extends StatelessWidget {
  const AppAccessGrid({
    super.key,
    required this.children,
    this.minTileWidth = 220,
    this.maxColumns = 4,
    this.mobileColumns = 1,
    this.spacing = 16,
    this.runSpacing = 16,
    this.tileHeight = 200,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;
  final int mobileColumns;
  final double spacing;
  final double runSpacing;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      if (children.isEmpty) return const SizedBox.shrink();
      final columns = mobileColumns.clamp(1, children.length).toInt();
      if (columns > 1) {
        return Column(
          children: [
            for (var start = 0; start < children.length; start += columns) ...[
              if (start > 0) SizedBox(height: runSpacing),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var column = 0; column < columns; column++) ...[
                      if (column > 0) SizedBox(width: spacing),
                      Expanded(
                        child: start + column < children.length
                            ? children[start + column]
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      }

      // Sin altura fija: evita overflow del AppHubCard en pantallas bajas
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: runSpacing),
            children[i],
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (!maxW.isFinite || maxW <= 0) {
          return Column(children: children);
        }
        var cols = (maxW / minTileWidth).floor().clamp(1, maxColumns);
        cols = cols.clamp(1, children.length);
        final totalGap = spacing * (cols - 1);
        final tileW = (maxW - totalGap) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: tileW, height: tileHeight, child: child),
          ],
        );
      },
    );
  }
}
