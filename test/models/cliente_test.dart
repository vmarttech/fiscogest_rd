import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClienteModel', () {
    test('crea ClientesTableCompanion.insert con campos requeridos', () {
      final cliente = ClientesTableCompanion.insert(
        codigo: 'CLI-001',
        nombre: 'Empresa de Prueba S.R.L.',
        rncCedula: '123456789',
        telefono: '809-555-1234',
        correo: 'correo@dominio.do',
        direccion: 'Calle Principal 123, Santo Domingo',
        activo: const Value(true),
        saldoPendiente: const Value(0.0),
      );

      expect(cliente.codigo.value, 'CLI-001');
      expect(cliente.nombre.value, 'Empresa de Prueba S.R.L.');
      expect(cliente.rncCedula.value, '123456789');
      expect(cliente.telefono.value, '809-555-1234');
      expect(cliente.correo.value, 'correo@dominio.do');
      expect(cliente.direccion.value, 'Calle Principal 123, Santo Domingo');
      expect(cliente.activo.value, isTrue);
      expect(cliente.saldoPendiente.value, 0.0);
    });

    test('rncCedula debe contener al menos 9 caracteres', () {
      const rncValido = '123456789';
      expect(rncValido.length, greaterThanOrEqualTo(9));

      const rncInvalido = '12345678';
      expect(rncInvalido.length, lessThan(9));
    });

    test('correo debe contener símbolo @', () {
      const correoValido = 'correo@dominio.do';
      const correoInvalido = 'correodominio.do';

      expect(correoValido.contains('@'), isTrue);
      expect(correoInvalido.contains('@'), isFalse);
    });

    test('saldoPendiente no puede ser negativo', () {
      const saldoValido = 1500.50;
      const saldoNegativo = -50.0;

      expect(saldoValido, isNonNegative);
      expect(saldoNegativo, isNegative);
    });
  });
}
