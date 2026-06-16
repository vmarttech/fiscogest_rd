import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fiscogestrd/main.dart';

void main() {
  testWidgets('La aplicación se inicia y muestra el título principal', (WidgetTester tester) async {
    // Cargamos la aplicación con el ProviderScope necesario
    await tester.pumpWidget(
      const ProviderScope(
        child: FiscoGestApp(),
      ),
    );

    // Verificamos que el título de la app aparezca en pantalla
    expect(find.text('FiscoGest RD - Sistema Fiscal'), findsOneWidget);

    // Verificamos que los botones principales del menú estén presentes
    expect(find.text('Productos'), findsOneWidget);
    expect(find.text('Existencias'), findsOneWidget);
    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Facturación'), findsOneWidget);
  });
}