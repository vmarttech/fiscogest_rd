import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShellAppBarState {
  const ShellAppBarState({this.actions = const [], this.titleOverride});
  final List<Widget> actions;
  final String? titleOverride;
  static const empty = ShellAppBarState();
}

class ShellAppBarNotifier extends Notifier<ShellAppBarState> {
  @override
  ShellAppBarState build() => ShellAppBarState.empty;

  void set({
    List<Widget>? actions,
    String? titleOverride,
    bool clearTitle = false,
  }) {
    state = ShellAppBarState(
      actions: actions != null
          ? List<Widget>.unmodifiable(actions)
          : state.actions,
      titleOverride: clearTitle ? null : (titleOverride ?? state.titleOverride),
    );
  }

  void clear() => state = ShellAppBarState.empty;
}

final shellAppBarProvider =
    NotifierProvider<ShellAppBarNotifier, ShellAppBarState>(
      ShellAppBarNotifier.new,
    );
