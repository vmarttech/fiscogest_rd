import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogest_rd/main.dart';

void main() {
  testWidgets('FiscoGestRD smoke test', (WidgetTester tester) async {
    // Establecer un tamaño de pantalla de escritorio estándar para evitar desbordamientos en pruebas
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(
        child: FiscoGestApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);

    // Restaurar el tamaño de la vista al finalizar
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
