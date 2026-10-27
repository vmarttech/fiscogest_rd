import 'dart:async';

import 'package:flutter/material.dart';

class FiscoGestNotifications {
  FiscoGestNotifications._();

  static final ValueNotifier<List<FiscoGestNotificationEntry>> notifications =
      ValueNotifier<List<FiscoGestNotificationEntry>>(
        <FiscoGestNotificationEntry>[],
      );

  static int _nextId = 0;

  static void show(SnackBar snackBar) {
    final entry = FiscoGestNotificationEntry(
      id: _nextId++,
      snackBar: snackBar,
    );

    final current = List<FiscoGestNotificationEntry>.from(notifications.value);
    current.add(entry);
    notifications.value = current;

    snackBar.onVisible?.call();

    final duration = snackBar.duration;

    Timer(duration, () {
      dismiss(entry.id);
    });
  }

  static void dismiss(int id) {
    final current = List<FiscoGestNotificationEntry>.from(notifications.value);
    current.removeWhere((entry) => entry.id == id);
    notifications.value = current;
  }

  static void clear() {
    notifications.value = <FiscoGestNotificationEntry>[];
  }
}

class FiscoGestNotificationEntry {
  const FiscoGestNotificationEntry({required this.id, required this.snackBar});

  final int id;
  final SnackBar snackBar;
}

class FiscoGestNotificationOverlay extends StatelessWidget {
  const FiscoGestNotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<FiscoGestNotificationEntry>>(
      valueListenable: FiscoGestNotifications.notifications,
      builder: (context, entries, _) {
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }

        return IgnorePointer(
          ignoring: false,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 12, left: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final entry in entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CompactNotification(
                            key: ValueKey(entry.id),
                            entry: entry,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompactNotification extends StatefulWidget {
  const _CompactNotification({super.key, required this.entry});

  final FiscoGestNotificationEntry entry;

  @override
  State<_CompactNotification> createState() => _CompactNotificationState();
}

class _CompactNotificationState extends State<_CompactNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  SnackBar get snackBar => widget.entry.snackBar;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        FiscoGestNotifications.dismiss(widget.entry.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor =
        snackBar.backgroundColor ?? theme.colorScheme.inverseSurface;

    final content = snackBar.content;

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          elevation: 6,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          clipBehavior: Clip.antiAlias,
          child: Container(
            constraints: const BoxConstraints(minHeight: 42, maxWidth: 380),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: DefaultTextStyle(
                    style:
                        theme.textTheme.bodySmall?.copyWith(
                          color: snackBar.backgroundColor == null
                              ? theme.colorScheme.onInverseSurface
                              : Colors.white,
                          fontSize: 12,
                          height: 1.25,
                        ) ??
                        TextStyle(
                          color: snackBar.backgroundColor == null
                              ? theme.colorScheme.onInverseSurface
                              : Colors.white,
                          fontSize: 12,
                          height: 1.25,
                        ),
                    child: content,
                  ),
                ),
                if (snackBar.action != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      snackBar.action!.onPressed();
                      _dismiss();
                    },
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor:
                          snackBar.action!.textColor ?? Colors.white,
                    ),
                    child: Text(
                      snackBar.action!.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 2),
                InkWell(
                  onTap: _dismiss,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.close, size: 15, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
