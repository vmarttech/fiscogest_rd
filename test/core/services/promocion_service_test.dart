import 'package:flutter_test/flutter_test.dart';

// LÓGICA DE VALIDACIÓN BASADA EN:
// lib/features/comercial/domain/services/promocion_service.dart línea 36
class Promocion {

  Promocion({
    required this.nombre,
    required this.porcentajeDescuento,
    required this.fechaInicio,
    required this.fechaFin,
    required this.activa,
  });
  final String nombre;
  final double porcentajeDescuento;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool activa;
}

bool validarPromocion(Promocion promocion) {
  if (promocion.nombre.trim().isEmpty) return false;
  if (promocion.porcentajeDescuento < 0 || promocion.porcentajeDescuento > 1) return false;
  if (promocion.fechaInicio.isAfter(promocion.fechaFin)) return false;
  if (!promocion.activa) return false;
  return true;
}

void main() {
  group('PromocionService — Validación de promociones', () {
    final fechaInicio = DateTime(2026, 9, 1);
    final fechaFin = DateTime(2026, 9, 30);

    final promocionValida = Promocion(
      nombre: 'Promoción Septiembre',
      porcentajeDescuento: 0.15,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      activa: true,
    );

    test('promoción completa y válida → retorna true', () {
      expect(validarPromocion(promocionValida), isTrue);
    });

    test('nombre vacío → inválida', () {
      final promocion = promocionValida.copyWith(nombre: '');
      expect(validarPromocion(promocion), isFalse);
    });

    test('descuento negativo → inválida', () {
      final promocion = promocionValida.copyWith(porcentajeDescuento: -0.05);
      expect(validarPromocion(promocion), isFalse);
    });

    test('descuento mayor a 100% → inválida', () {
      final promocion = promocionValida.copyWith(porcentajeDescuento: 1.5);
      expect(validarPromocion(promocion), isFalse);
    });

    test('fecha inicio después de fecha fin → inválida', () {
      final promocion = Promocion(
        nombre: 'Promoción Inválida',
        porcentajeDescuento: 0.10,
        fechaInicio: fechaFin,
        fechaFin: fechaInicio,
        activa: true,
      );
      expect(validarPromocion(promocion), isFalse);
    });

    test('promoción inactiva → inválida', () {
      final promocion = promocionValida.copyWith(activa: false);
      expect(validarPromocion(promocion), isFalse);
    });
  });
}

// Extensión para copiar promociones en pruebas
extension on Promocion {
  Promocion copyWith({
    String? nombre,
    double? porcentajeDescuento,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? activa,
  }) {
    return Promocion(
      nombre: nombre ?? this.nombre,
      porcentajeDescuento: porcentajeDescuento ?? this.porcentajeDescuento,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      activa: activa ?? this.activa,
    );
  }
}
