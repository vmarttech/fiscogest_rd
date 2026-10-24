import 'package:drift/drift.dart';
import 'package:fiscogest_rd/features/configuracion/domain/entities/configuracion_entity.dart';
import 'package:fiscogest_rd/features/configuracion/domain/interfaces/i_configuracion_repository.dart';
import 'package:fiscogest_rd/features/configuracion/data/dao/configuracion_dao.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';

class ConfiguracionRepositoryImpl implements IConfiguracionRepository {
  ConfiguracionRepositoryImpl(this._configuracionDao);
  final ConfiguracionDao _configuracionDao;

  static const _defaults = ConfiguracionEntity(
    id: '1',
    nombreComercial: 'FiscoGest RD',
    razonSocial: '',
    rnc: '',
    direccion: '',
    telefono: '',
    correo: '',
    logoUrl: '',
    moneda: 'DOP',
    zonaHoraria: 'America/Santo_Domingo',
    formatoImpresion: 'Ticket 80mm',
    formatoFecha: 'DD/MM/YYYY',
    impuestoPorcentaje: 18.0,
    idioma: 'Español',
    docMostrarLogo: true,
    docMostrarRnc: true,
    docMostrarDireccion: true,
    docMostrarTelefono: true,
    docMostrarCorreo: true,
    docMostrarNcf: true,
    docMostrarCliente: true,
    docMostrarItbisDesglose: true,
    docPiePagina: 'Gracias por su preferencia',
    prefijoContado: 'C',
    prefijoCredito: 'CR',
    cajaFormaPagoDefault: 'efectivo',
    cajaPermitirTarjeta: true,
    cajaPermitirTransferencia: true,
    cajaPermitirCheque: false,
    cajaExigirSesion: false,
    modoSimplificado: true,
    transfImprimirManifiesto: true,
    transfTituloManifiesto: 'MANIFIESTO DE TRANSFERENCIA INTER-ALMACÉN',
    transfSubtituloManifiesto: 'PACKING LIST / BATCH LIST (LISTA DE LOTES)',
    transfTransportistaDefault: '',
    transfObservacionesDefault:
        'Verificar cantidades y estado del producto al momento de la recepción en el Almacén Destino. Reportar cualquier discrepancia de inmediato.',
    transfMostrarFirmas: true,
  );

  @override
  Future<ConfiguracionEntity> obtenerConfiguracion() async {
    final model = await _configuracionDao.obtenerConfiguracion();
    if (model == null) return _defaults;
    return ConfiguracionEntity(
      id: model.id.toString(),
      nombreComercial: model.nombreNegocio,
      razonSocial: model.razonSocial,
      rnc: model.rncCedula,
      direccion: model.direccion,
      telefono: model.telefono,
      correo: model.correo,
      logoUrl: model.logoUrl,
      moneda: model.moneda,
      zonaHoraria: model.zonaHoraria,
      formatoImpresion: model.formatoImpresion,
      formatoFecha: model.formatoFecha,
      impuestoPorcentaje: model.impuestoPorcentaje,
      idioma: model.idioma,
      docMostrarLogo: model.docMostrarLogo,
      docMostrarRnc: model.docMostrarRnc,
      docMostrarDireccion: model.docMostrarDireccion,
      docMostrarTelefono: model.docMostrarTelefono,
      docMostrarCorreo: model.docMostrarCorreo,
      docMostrarNcf: model.docMostrarNcf,
      docMostrarCliente: model.docMostrarCliente,
      docMostrarItbisDesglose: model.docMostrarItbisDesglose,
      docPiePagina: model.docPiePagina,
      prefijoContado: model.prefijoContado,
      prefijoCredito: model.prefijoCredito,
      cajaFormaPagoDefault: model.cajaFormaPagoDefault,
      cajaPermitirTarjeta: model.cajaPermitirTarjeta,
      cajaPermitirTransferencia: model.cajaPermitirTransferencia,
      cajaPermitirCheque: model.cajaPermitirCheque,
      cajaExigirSesion: model.cajaExigirSesion,
      modoSimplificado: model.modoSimplificado,
      transfImprimirManifiesto: model.transfImprimirManifiesto,
      transfTituloManifiesto: model.transfTituloManifiesto,
      transfSubtituloManifiesto: model.transfSubtituloManifiesto,
      transfTransportistaDefault: model.transfTransportistaDefault,
      transfObservacionesDefault: model.transfObservacionesDefault,
      transfMostrarFirmas: model.transfMostrarFirmas,
    );
  }

  @override
  Future<void> guardarConfiguracion(ConfiguracionEntity c) async {
    final id = int.tryParse(c.id) ?? 1;
    await _configuracionDao.guardarConfiguracion(
      ConfiguracionTableCompanion(
        id: Value(id),
        nombreNegocio: Value(c.nombreComercial),
        razonSocial: Value(c.razonSocial),
        rncCedula: Value(c.rnc),
        direccion: Value(c.direccion),
        telefono: Value(c.telefono),
        correo: Value(c.correo),
        logoUrl: Value(c.logoUrl),
        moneda: Value(c.moneda),
        zonaHoraria: Value(c.zonaHoraria),
        formatoImpresion: Value(c.formatoImpresion),
        formatoFecha: Value(c.formatoFecha),
        impuestoPorcentaje: Value(c.impuestoPorcentaje),
        idioma: Value(c.idioma),
        docMostrarLogo: Value(c.docMostrarLogo),
        docMostrarRnc: Value(c.docMostrarRnc),
        docMostrarDireccion: Value(c.docMostrarDireccion),
        docMostrarTelefono: Value(c.docMostrarTelefono),
        docMostrarCorreo: Value(c.docMostrarCorreo),
        docMostrarNcf: Value(c.docMostrarNcf),
        docMostrarCliente: Value(c.docMostrarCliente),
        docMostrarItbisDesglose: Value(c.docMostrarItbisDesglose),
        docPiePagina: Value(c.docPiePagina),
        prefijoContado: Value(c.prefijoContado),
        prefijoCredito: Value(c.prefijoCredito),
        cajaFormaPagoDefault: Value(c.cajaFormaPagoDefault),
        cajaPermitirTarjeta: Value(c.cajaPermitirTarjeta),
        cajaPermitirTransferencia: Value(c.cajaPermitirTransferencia),
        cajaPermitirCheque: Value(c.cajaPermitirCheque),
        cajaExigirSesion: Value(c.cajaExigirSesion),
        modoSimplificado: Value(c.modoSimplificado),
        transfImprimirManifiesto: Value(c.transfImprimirManifiesto),
        transfTituloManifiesto: Value(c.transfTituloManifiesto),
        transfSubtituloManifiesto: Value(c.transfSubtituloManifiesto),
        transfTransportistaDefault: Value(c.transfTransportistaDefault),
        transfObservacionesDefault: Value(c.transfObservacionesDefault),
        transfMostrarFirmas: Value(c.transfMostrarFirmas),
      ),
    );
  }
}
