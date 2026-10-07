import 'package:fiscogest_rd/features/impuestos/domain/entities/impuesto_entity.dart';
import 'package:fiscogest_rd/features/inventario/domain/entities/categoria.dart';

/// Fracción (0.18). Prioridad: producto → categoría → default global.
/// Si [tasaGlobal] es 0 (modo simplificado) no se cobra ITBIS.
double resolverTasaItbisProducto({
  required int? impuestoId,
  required int categoriaId,
  required List<ImpuestoEntity> impuestos,
  required List<Categoria> categorias,
  required double tasaGlobal,
}) {
  if (tasaGlobal <= 0) return 0;
  if (impuestoId != null) {
    for (final i in impuestos) {
      if (i.id == impuestoId) {
        if (!i.activo) break;
        if (i.esExento) return 0;
        return i.porcentaje / 100.0;
      }
    }
  }
  for (final c in categorias) {
    if (c.id == categoriaId) {
      final pct = c.itbisPorCiento;
      if (pct != null) return pct / 100.0;
      break;
    }
  }
  return tasaGlobal;
}

double itbisDeLineas({
  required Iterable<double> subtotales,
  required Iterable<double> tasas,
  double descuentoGeneral = 0,
}) {
  final subs = subtotales.toList();
  final tas = tasas.toList();
  final n = subs.length < tas.length ? subs.length : tas.length;
  var subtotal = 0.0;
  for (var i = 0; i < n; i++) {
    subtotal += subs[i];
  }
  final factor =
      subtotal > 0 ? (1 - (descuentoGeneral / subtotal).clamp(0.0, 1.0)) : 1.0;
  var itbis = 0.0;
  for (var i = 0; i < n; i++) {
    itbis += subs[i] * factor * tas[i];
  }
  return itbis;
}
