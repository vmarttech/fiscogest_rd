import 'package:flutter/material.dart';
import 'package:fiscogest_rd/core/ui/ui.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/referencia_solicitante.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/solicitud_credito_expediente.dart';

/// Formulario de datos del solicitante + referencias (expediente de crédito).
class ExpedienteSolicitanteForm extends StatefulWidget {
  const ExpedienteSolicitanteForm({
    super.key,
    required this.inicial,
    required this.editable,
    required this.onGuardar,
  });

  final SolicitudCreditoExpediente inicial;
  final bool editable;
  final Future<void> Function(SolicitudCreditoExpediente) onGuardar;

  @override
  State<ExpedienteSolicitanteForm> createState() =>
      _ExpedienteSolicitanteFormState();
}

class _ExpedienteSolicitanteFormState extends State<ExpedienteSolicitanteForm> {
  late final TextEditingController _nombre;
  late final TextEditingController _cedula;
  late final TextEditingController _estadoCivil;
  late final TextEditingController _telefono;
  late final TextEditingController _celular;
  late final TextEditingController _email;
  late final TextEditingController _direccion;
  late final TextEditingController _sector;
  late final TextEditingController _ciudad;
  late final TextEditingController _tiempoRes;
  late final TextEditingController _empresa;
  late final TextEditingController _cargo;
  late final TextEditingController _telTrabajo;
  late final TextEditingController _ingreso;
  late final TextEditingController _tiempoLab;
  late final TextEditingController _vivienda;
  late final TextEditingController _dependientes;
  late final TextEditingController _notas;

  late List<TextEditingController> _refNombre;
  late List<TextEditingController> _refRelacion;
  late List<TextEditingController> _refTelefono;
  late List<TextEditingController> _refDireccion;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.inicial;
    _nombre = TextEditingController(text: e.nombreCompleto);
    _cedula = TextEditingController(text: e.cedula);
    _estadoCivil = TextEditingController(text: e.estadoCivil);
    _telefono = TextEditingController(text: e.telefono);
    _celular = TextEditingController(text: e.celular);
    _email = TextEditingController(text: e.email);
    _direccion = TextEditingController(text: e.direccion);
    _sector = TextEditingController(text: e.sector);
    _ciudad = TextEditingController(text: e.ciudad);
    _tiempoRes = TextEditingController(text: e.tiempoResidencia);
    _empresa = TextEditingController(text: e.empresa);
    _cargo = TextEditingController(text: e.cargo);
    _telTrabajo = TextEditingController(text: e.telefonoTrabajo);
    _ingreso = TextEditingController(
      text: e.ingresoMensual > 0 ? e.ingresoMensual.toStringAsFixed(2) : '',
    );
    _tiempoLab = TextEditingController(text: e.tiempoLaborando);
    _vivienda = TextEditingController(text: e.tipoVivienda);
    _dependientes = TextEditingController(text: '${e.dependientes}');
    _notas = TextEditingController(text: e.notasAnalista);

    final refs = e.referencias.isEmpty
        ? const [ReferenciaSolicitante(orden: 1), ReferenciaSolicitante(orden: 2)]
        : e.referencias;
    _refNombre = refs.map((r) => TextEditingController(text: r.nombre)).toList();
    _refRelacion =
        refs.map((r) => TextEditingController(text: r.relacion)).toList();
    _refTelefono =
        refs.map((r) => TextEditingController(text: r.telefono)).toList();
    _refDireccion =
        refs.map((r) => TextEditingController(text: r.direccion)).toList();
    while (_refNombre.length < 2) {
      _refNombre.add(TextEditingController());
      _refRelacion.add(TextEditingController());
      _refTelefono.add(TextEditingController());
      _refDireccion.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nombre, _cedula, _estadoCivil, _telefono, _celular, _email,
      _direccion, _sector, _ciudad, _tiempoRes, _empresa, _cargo,
      _telTrabajo, _ingreso, _tiempoLab, _vivienda, _dependientes, _notas,
      ..._refNombre, ..._refRelacion, ..._refTelefono, ..._refDireccion,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        enabled: widget.editable,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  SolicitudCreditoExpediente _leer() {
    return widget.inicial.copyWith(
      nombreCompleto: _nombre.text.trim(),
      cedula: _cedula.text.trim(),
      estadoCivil: _estadoCivil.text.trim(),
      telefono: _telefono.text.trim(),
      celular: _celular.text.trim(),
      email: _email.text.trim(),
      direccion: _direccion.text.trim(),
      sector: _sector.text.trim(),
      ciudad: _ciudad.text.trim(),
      tiempoResidencia: _tiempoRes.text.trim(),
      empresa: _empresa.text.trim(),
      cargo: _cargo.text.trim(),
      telefonoTrabajo: _telTrabajo.text.trim(),
      ingresoMensual:
          double.tryParse(_ingreso.text.trim().replaceAll(',', '.')) ?? 0,
      tiempoLaborando: _tiempoLab.text.trim(),
      tipoVivienda: _vivienda.text.trim(),
      dependientes: int.tryParse(_dependientes.text.trim()) ?? 0,
      notasAnalista: _notas.text.trim(),
      referencias: [
        for (var i = 0; i < _refNombre.length; i++)
          ReferenciaSolicitante(
            orden: i + 1,
            nombre: _refNombre[i].text.trim(),
            relacion: _refRelacion[i].text.trim(),
            telefono: _refTelefono[i].text.trim(),
            direccion: _refDireccion[i].text.trim(),
          ),
      ],
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(_leer());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Datos del solicitante',
          subtitle: 'Identificación, contacto y domicilio',
        ),
        AppCard(
          borderColor: AppColors.border,
          child: Column(
            children: [
              _campo(_nombre, 'Nombre completo'),
              _campo(_cedula, 'Cédula / RNC'),
              _campo(_estadoCivil, 'Estado civil'),
              _campo(_telefono, 'Teléfono', keyboard: TextInputType.phone),
              _campo(_celular, 'Celular', keyboard: TextInputType.phone),
              _campo(_email, 'Email', keyboard: TextInputType.emailAddress),
              _campo(_direccion, 'Dirección', maxLines: 2),
              _campo(_sector, 'Sector'),
              _campo(_ciudad, 'Ciudad / Municipio'),
              _campo(_tiempoRes, 'Tiempo residiendo'),
            ],
          ),
        ),
        AppLayout.vM,
        const SectionHeader(
          title: 'Datos laborales',
          subtitle: 'Empleo e ingresos',
        ),
        AppCard(
          borderColor: AppColors.border,
          child: Column(
            children: [
              _campo(_empresa, 'Empresa'),
              _campo(_cargo, 'Cargo'),
              _campo(_telTrabajo, 'Teléfono trabajo',
                  keyboard: TextInputType.phone),
              _campo(_ingreso, 'Ingreso mensual',
                  keyboard: const TextInputType.numberWithOptions(decimal: true)),
              _campo(_tiempoLab, 'Tiempo laborando'),
              _campo(_vivienda, 'Tipo de vivienda (propia/alquilada)'),
              _campo(_dependientes, 'Dependientes',
                  keyboard: TextInputType.number),
              _campo(_notas, 'Notas del analista', maxLines: 3),
            ],
          ),
        ),
        AppLayout.vM,
        const SectionHeader(
          title: 'Referencias personales',
          subtitle: 'Mínimo dos referencias',
        ),
        for (var i = 0; i < _refNombre.length; i++) ...[
          AppCard(
            borderColor: AppColors.border,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Referencia ${i + 1}',
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                AppLayout.vS,
                _campo(_refNombre[i], 'Nombre'),
                _campo(_refRelacion[i], 'Relación / parentesco'),
                _campo(_refTelefono[i], 'Teléfono',
                    keyboard: TextInputType.phone),
                _campo(_refDireccion[i], 'Dirección'),
              ],
            ),
          ),
          AppLayout.vS,
        ],
        if (widget.editable)
          AppButton(
            text: 'GUARDAR EXPEDIENTE',
            icon: Icons.save_outlined,
            onPressed: _guardando ? null : _guardar,
            isDisabled: _guardando,
            isLoading: _guardando,
            width: double.infinity,
          ),
      ],
    );
  }
}
