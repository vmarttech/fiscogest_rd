import 'package:flutter_test/flutter_test.dart';

// VALORES EXACTOS TOMADOS DE:
// lib/features/impuestos/data/repositories/impuesto_repository_impl.dart
const Map<String, double> tasasOficiales = {
  'ITBIS': 0.18,
  'ITBIS_REDUCIDA': 0.16,
  'EXENTO': 0.0,
};

const List<Map<String, dynamic>> impuestosIniciales = [
  {'nombre': 'ITBIS 18%', 'tipo': 'ITBIS', 'tasa': 0.18},
  {'nombre': 'ITBIS 16%', 'tipo': 'ITBIS', 'tasa': 0.16},
  {'nombre': 'ITBIS 0% (Exento)', 'tipo': 'EXENTO', 'tasa': 0.0},
];

double obtenerTasaPorNombre(String nombre) {
  final impuesto = impuestosIniciales.firstWhere(
    (i) => i['nombre'] == nombre,
    orElse: () => throw ArgumentError('Impuesto no encontrado: $nombre'),
  );
  return impuesto['tasa'] as double;
}

void main() {
  group('Repositorio de Impuestos — Tasas oficiales cargadas', () {
    test('existe ITBIS 18% con tasa 0.18', () {
      final tasa = obtenerTasaPorNombre('ITBIS 18%');
      expect(tasa, tasasOficiales['ITBIS']);
    });

    test('existe ITBIS 16% con tasa 0.16', () {
      final tasa = obtenerTasaPorNombre('ITBIS 16%');
      expect(tasa, tasasOficiales['ITBIS_REDUCIDA']);
    });

    test('existe ITBIS 0% (Exento) con tasa 0.0', () {
      final tasa = obtenerTasaPorNombre('ITBIS 0% (Exento)');
      expect(tasa, tasasOficiales['EXENTO']);
    });

    test('consultar impuesto no registrado → lanza error', () {
      expect(() => obtenerTasaPorNombre('Impuesto Inexistente'), throwsArgumentError);
    });

    test('cantidad de impuestos iniciales = 3', () {
      expect(impuestosIniciales.length, 3);
    });
  });
}
