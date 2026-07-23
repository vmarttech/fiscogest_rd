import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'app_top_bar.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AppDrawer(),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(title: 'FiscoGest RD 3.0'),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
