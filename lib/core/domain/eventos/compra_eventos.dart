import 'package:fiscogest_rd/core/domain/eventos/evento_negocio.dart';

class CompraConfirmada extends EventoNegocio {
  CompraConfirmada({required this.compraId, required super.usuarioResponsable})
    : super(
        fecha: DateTime.now(),
        tipo: 'CompraConfirmada',
        entidadId: compraId,
      );
  final String compraId;
}
