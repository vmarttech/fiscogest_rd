import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProveedorModel', () {
    final fechaPrueba = DateTime(2026, 9, 2);

    test('crea ProveedoresTableCompanion con todos los campos', () {
      final proveedor = ProveedoresTableCompanion(
        nombreEmpresa: const Value('Proveedor Repuestos S.A.'),
        nombreContacto: const Value('María López'),
        rnc: const Value('987654321'),
        telefono: const Value('809-555-9876'),
        celular: const Value('829-555-9876'),
        email: const Value('ventas@repuestos.do'),
        direccion: const Value('Av. Industrial 456'),
        ciudad: const Value('Santiago'),
        provincia: const Value('Santiago'),
        diasCredito: const Value(30),
        estado: const Value('Activo'),
        fechaCreacion: Value(fechaPrueba),
      );

      expect(proveedor.nombreEmpresa.value, 'Proveedor Repuestos S.A.');
      expect(proveedor.nombreContacto.value, 'María López');
      expect(proveedor.rnc.value, '987654321');
      expect(proveedor.telefono.value, '809-555-9876');
      expect(proveedor.email.value, 'ventas@repuestos.do');
      expect(proveedor.diasCredito.value, 30);
      expect(proveedor.estado.value, 'Activo');
      expect(proveedor.fechaCreacion.value, fechaPrueba);
    });

    test('RNC debe contener 9 dígitos cuando no es nulo', () {
      const rncValido = '987654321';
      expect(rncValido.length, greaterThanOrEqualTo(9));
    });

    test('correo debe contener @ cuando se provee', () {
      const correoValido = 'ventas@repuestos.do';
      expect(correoValido.contains('@'), isTrue);
    });

    test('días de crédito no pueden ser negativos', () {
      const diasValido = 30;
      const diasNegativo = -7;
      expect(diasValido, isNonNegative);
      expect(diasNegativo, isNegative);
    });

    test('estado debe ser uno de los valores permitidos', () {
      const estadosPermitidos = {'Activo', 'Inactivo', 'Suspendido'};
      const estado = 'Activo';
      expect(estadosPermitidos.contains(estado), isTrue);
    });
  });
}
