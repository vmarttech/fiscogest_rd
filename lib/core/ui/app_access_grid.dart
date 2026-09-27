import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';

class AppAccessGrid extends StatelessWidget {
  const AppAccessGrid({
    super.key,
    required this.children,
    this.minTileWidth = 220,
    this.maxColumns = 4,
    this.spacing = 16,
    this.runSpacing = 16,
    this.tileHeight = 200,
  });

  final List<Widget> children;
  final double minTileWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;
  final double tileHeight;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: runSpacing),
            SizedBox(height: tileHeight, child: children[i]),
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
              SizedBox(
                width: tileW,
                height: tileHeight,
                child: child,
              ),
          ],
        );
      },
    );
  }
}
