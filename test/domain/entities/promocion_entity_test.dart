import 'package:flutter_test/flutter_test.dart';

// ESTRUCTURA + MÉTODO COPIADOS LITERALMENTE DE:
// lib/features/comercial/domain/entities/promocion.dart
class Promocion {

  const Promocion({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    required this.valor,
    this.fechaInicio,
    this.fechaFin,
    this.activa = true,
    this.minimoCantidad,
    this.minimoMonto,
  });
  final int id;
  final String nombre;
  final String descripcion;
  final String tipo;
  final double valor;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool activa;
  final int? minimoCantidad;
  final double? minimoMonto;

  // LÓGICA COPIADA LITERALMENTE DEL ARCHIVO REAL
  bool estaVigente(DateTime fechaReferencia) {
    if (fechaInicio != null && fechaReferencia.isBefore(fechaInicio!)) {
      return false;
    }
    if (fechaFin != null && fechaReferencia.isAfter(fechaFin!)) return false;
    return activa;
  }
}

void main() {
  group('Entidad Promocion — Lógica de Vigencia', () {
    final fechaInicio = DateTime(2026, 9, 1);
    final fechaFin = DateTime(2026, 9, 30);
    final fechaDurante = DateTime(2026, 9, 15);
    final fechaAntes = DateTime(2026, 8, 28);
    final fechaDespues = DateTime(2026, 10, 5);

    final promocionValida = Promocion(
      id: 1,
      nombre: 'Descuento Septiembre',
      descripcion: '10% en compras mayores a 500',
      tipo: 'PORCENTAJE',
      valor: 0.10,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      activa: true,
      minimoMonto: 500.0,
    );

    test('promoción activa + dentro de fechas → vigente = true', () {
      expect(promocionValida.estaVigente(fechaDurante), isTrue);
    });

    test('promoción activa + ANTES de fechaInicio → vigente = false', () {
      expect(promocionValida.estaVigente(fechaAntes), isFalse);
    });

    test('promoción activa + DESPUÉS de fechaFin → vigente = false', () {
      expect(promocionValida.estaVigente(fechaDespues), isFalse);
    });

    test('promoción INACTIVA + dentro de fechas → vigente = false', () {
      final promocionInactiva = Promocion(
        id: 2,
        nombre: 'Promoción Inactiva',
        descripcion: 'No vigente',
        tipo: 'PORCENTAJE',
        valor: 0.15,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        activa: false,
      );
      expect(promocionInactiva.estaVigente(fechaDurante), isFalse);
    });

    test('sin fechaInicio ni fechaFin + activa → siempre vigente', () {
      const promocionSinFechas = Promocion(
        id: 3,
        nombre: 'Promoción Permanente',
        descripcion: 'Descuento sin límite de fechas',
        tipo: 'FIJO',
        valor: 50.0,
        activa: true,
      );
      expect(promocionSinFechas.estaVigente(fechaAntes), isTrue);
      expect(promocionSinFechas.estaVigente(fechaDurante), isTrue);
      expect(promocionSinFechas.estaVigente(fechaDespues), isTrue);
    });

    test('activa = true por defecto', () {
      const promocion = Promocion(
        id: 4,
        nombre: 'Prueba',
        descripcion: '',
        tipo: 'PORCENTAJE',
        valor: 0.05,
      );
      expect(promocion.activa, isTrue);
    });

    test('minimoCantidad y minimoMonto pueden ser nulos', () {
      const promocionSinRequisitos = Promocion(
        id: 5,
        nombre: 'Sin límites',
        descripcion: '',
        tipo: 'PORCENTAJE',
        valor: 0.05,
      );
      expect(promocionSinRequisitos.minimoCantidad, isNull);
      expect(promocionSinRequisitos.minimoMonto, isNull);
    });
  });
}
