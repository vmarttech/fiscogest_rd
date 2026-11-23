import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeOption {
  teal('Verde azulado', Color(0xFF0F766E)),
  blue('Azul', Color(0xFF0057FF)),
  violet('Violeta', Color(0xFF6D28D9)),
  orange('Naranja', Color(0xFFFF7900)),
  gray('Gris', Color(0xFF374151));

  const AppThemeOption(this.label, this.seedColor);
  final String label;
  final Color seedColor;

  static AppThemeOption fromName(String? value) => AppThemeOption.values
      .firstWhere((theme) => theme.name == value, orElse: () => teal);
}

final appThemeProvider = StateProvider<AppThemeOption>(
  (ref) => AppThemeOption.teal,
);

Future<void> saveAppTheme(AppThemeOption theme) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('app_theme', theme.name);
}
