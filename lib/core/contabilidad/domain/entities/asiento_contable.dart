import 'package:fiscogest_rd/core/contabilidad/domain/enums/estado_asiento.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/entities/linea_asiento.dart';

/// Entidad de dominio: Asiento contable en partida doble con sus lineas.
class AsientoContable {
  const AsientoContable({
    this.id = 0,
    required this.numeroAsiento,
    required this.fecha,
    required this.concepto,
    required this.estado,
    this.documentoOrigen,
    this.tipoOrigen,
    this.referenciaId,
    this.lineas = const <LineaAsiento>[],
    required this.creadoEn,
    this.actualizadoEn,
  });

  final int id;
  final String numeroAsiento;
  final DateTime fecha;
  final String concepto;
  final EstadoAsiento estado;
  final String? documentoOrigen;
  final String? tipoOrigen;
  final int? referenciaId;
  final List<LineaAsiento> lineas;
  final DateTime creadoEn;
  final DateTime? actualizadoEn;

  double get totalDebe => lineas.fold(0.0, (s, l) => s + l.debe);
  double get totalHaber => lineas.fold(0.0, (s, l) => s + l.haber);

  // Partida doble: total debe = total haber, con tolerancia de centavos.
  // Se exigen ambos lados con movimiento y se redondea a centavos antes de comparar.
  bool get estaCuadrado {
    if (lineas.isEmpty) return false;
    if (totalDebe <= 0 || totalHaber <= 0) return false;
    final debeCents = (totalDebe * 100).roundToDouble() / 100;
    final haberCents = (totalHaber * 100).roundToDouble() / 100;
    return (debeCents - haberCents).abs() < 0.005;
  }

  // Listado de fallos de dominio para validar antes de persistir el asiento.
  List<String> get errores {
    final out = <String>[];
    if (numeroAsiento.trim().isEmpty) out.add('acct_error_number_required');
    if (concepto.trim().isEmpty) out.add('acct_error_concepto_required');
    if (lineas.isEmpty) {
      out.add('acct_error_no_lines');
      return out;
    }
    if (tieneLineasInvalidas) out.add('acct_error_invalid_line');
    if (!estaCuadrado) out.add('acct_error_unbalanced');
    return out;
  }

  bool get esValido => errores.isEmpty;

  bool get esEditable => estado.esEditable;

  bool get tieneLineasInvalidas => lineas.any((l) => !l.esValida);

  AsientoContable copyWith({
    int? id,
    String? numeroAsiento,
    DateTime? fecha,
    String? concepto,
    EstadoAsiento? estado,
    String? documentoOrigen,
    String? tipoOrigen,
    int? referenciaId,
    List<LineaAsiento>? lineas,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return AsientoContable(
      id: id ?? this.id,
      numeroAsiento: numeroAsiento ?? this.numeroAsiento,
      fecha: fecha ?? this.fecha,
      concepto: concepto ?? this.concepto,
      estado: estado ?? this.estado,
      documentoOrigen: documentoOrigen ?? this.documentoOrigen,
      tipoOrigen: tipoOrigen ?? this.tipoOrigen,
      referenciaId: referenciaId ?? this.referenciaId,
      lineas: lineas ?? this.lineas,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
