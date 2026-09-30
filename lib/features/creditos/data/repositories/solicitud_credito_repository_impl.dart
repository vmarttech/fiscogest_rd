import 'package:drift/drift.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/clientes/domain/interfaces/i_cliente_repository.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/solicitud_credito_dao.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/referencia_solicitante.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/solicitud_credito_expediente.dart';
import 'package:fiscogest_rd/features/creditos/domain/repositories/i_solicitud_credito_repository.dart';

class SolicitudCreditoRepositoryImpl implements ISolicitudCreditoRepository {
  SolicitudCreditoRepositoryImpl(this._dao, this._clienteRepo);

  final SolicitudCreditoDao _dao;
  final IClienteRepository _clienteRepo;

  SolicitudCreditoExpediente _map(
    SolicitudCreditoData row,
    List<ReferenciaCreditoData> refs,
  ) {
    return SolicitudCreditoExpediente(
      id: row.id,
      ventaId: row.ventaId,
      nombreCompleto: row.nombreCompleto,
      cedula: row.cedula,
      fechaNacimiento: row.fechaNacimiento,
      estadoCivil: row.estadoCivil,
      telefono: row.telefono,
      celular: row.celular,
      email: row.email,
      direccion: row.direccion,
      sector: row.sector,
      ciudad: row.ciudad,
      tiempoResidencia: row.tiempoResidencia,
      empresa: row.empresa,
      cargo: row.cargo,
      telefonoTrabajo: row.telefonoTrabajo,
      ingresoMensual: row.ingresoMensual,
      tiempoLaborando: row.tiempoLaborando,
      tipoVivienda: row.tipoVivienda,
      dependientes: row.dependientes,
      notasAnalista: row.notasAnalista,
      usuarioId: row.usuarioId,
      referencias: [
        for (final r in refs)
          ReferenciaSolicitante(
            id: r.id,
            solicitudId: r.solicitudId,
            nombre: r.nombre,
            relacion: r.relacion,
            telefono: r.telefono,
            direccion: r.direccion,
            orden: r.orden,
          ),
      ],
    );
  }

  Future<SolicitudCreditoExpediente> _precargarDesdeCliente(
    SolicitudCreditoExpediente exp,
    int? clienteId,
    String nombreInicial,
  ) async {
    if (clienteId == null || clienteId <= 0) {
      if (exp.nombreCompleto.trim().isEmpty && nombreInicial.isNotEmpty) {
        return exp.copyWith(nombreCompleto: nombreInicial);
      }
      return exp;
    }

    final c = await _clienteRepo.obtenerClientePorId(clienteId);
    if (c == null) {
      if (exp.nombreCompleto.trim().isEmpty && nombreInicial.isNotEmpty) {
        return exp.copyWith(nombreCompleto: nombreInicial);
      }
      return exp;
    }

    // Solo rellena vacíos: no pisa datos ya guardados por el analista
    final actualizado = exp.copyWith(
      nombreCompleto: exp.nombreCompleto.trim().isEmpty
          ? (c.nombre.trim().isNotEmpty ? c.nombre : nombreInicial)
          : exp.nombreCompleto,
      cedula: exp.cedula.trim().isEmpty ? c.rncCedula : exp.cedula,
      telefono: exp.telefono.trim().isEmpty ? c.telefono : exp.telefono,
      celular: exp.celular.trim().isEmpty ? c.telefono : exp.celular,
      email: exp.email.trim().isEmpty ? c.correo : exp.email,
      direccion: exp.direccion.trim().isEmpty ? c.direccion : exp.direccion,
    );

    final huboCambio =
        actualizado.nombreCompleto != exp.nombreCompleto ||
        actualizado.cedula != exp.cedula ||
        actualizado.telefono != exp.telefono ||
        actualizado.celular != exp.celular ||
        actualizado.email != exp.email ||
        actualizado.direccion != exp.direccion;

    if (actualizado.id != null && huboCambio) {
      await guardar(actualizado);
    }
    return actualizado;
  }

  @override
  Future<SolicitudCreditoExpediente> obtenerOCrearPorVenta({
    required int ventaId,
    String nombreInicial = '',
    int? clienteId,
    int usuarioId = 1,
  }) async {
    final row = await _dao.obtenerOCrearPorVenta(
      ventaId: ventaId,
      nombreInicial: nombreInicial,
      usuarioId: usuarioId,
    );
    final refs = await _dao.listarReferencias(row.id);
    var exp = _map(row, refs);

    if (exp.referencias.isEmpty) {
      exp = exp.copyWith(
        referencias: const [
          ReferenciaSolicitante(orden: 1),
          ReferenciaSolicitante(orden: 2),
        ],
      );
    } else if (exp.referencias.length == 1) {
      exp = exp.copyWith(
        referencias: [
          ...exp.referencias,
          const ReferenciaSolicitante(orden: 2),
        ],
      );
    }

    return _precargarDesdeCliente(exp, clienteId, nombreInicial);
  }

  @override
  Future<void> guardar(SolicitudCreditoExpediente e) async {
    if (e.id == null) {
      throw Exception('Expediente sin id');
    }
    await _dao.actualizarSolicitud(
      SolicitudesCreditoTableCompanion(
        id: Value(e.id!),
        nombreCompleto: Value(e.nombreCompleto),
        cedula: Value(e.cedula),
        fechaNacimiento: Value(e.fechaNacimiento),
        estadoCivil: Value(e.estadoCivil),
        telefono: Value(e.telefono),
        celular: Value(e.celular),
        email: Value(e.email),
        direccion: Value(e.direccion),
        sector: Value(e.sector),
        ciudad: Value(e.ciudad),
        tiempoResidencia: Value(e.tiempoResidencia),
        empresa: Value(e.empresa),
        cargo: Value(e.cargo),
        telefonoTrabajo: Value(e.telefonoTrabajo),
        ingresoMensual: Value(e.ingresoMensual),
        tiempoLaborando: Value(e.tiempoLaborando),
        tipoVivienda: Value(e.tipoVivienda),
        dependientes: Value(e.dependientes),
        notasAnalista: Value(e.notasAnalista),
        usuarioId: Value(e.usuarioId),
      ),
    );
    await _dao.reemplazarReferencias(
      solicitudId: e.id!,
      refs: [
        for (final r in e.referencias)
          ReferenciasCreditoTableCompanion.insert(
            solicitudId: e.id!,
            nombre: Value(r.nombre),
            relacion: Value(r.relacion),
            telefono: Value(r.telefono),
            direccion: Value(r.direccion),
            orden: Value(r.orden),
          ),
      ],
    );
  }
}
