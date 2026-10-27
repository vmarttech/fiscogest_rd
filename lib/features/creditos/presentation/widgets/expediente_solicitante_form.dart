import 'package:flutter/material.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/referencia_solicitante.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/solicitud_credito_expediente.dart';

/// Expediente único — layout fiel al mockup HTML (5 secciones).
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
  late final TextEditingController _nacionalidad;
  late final TextEditingController _telefono;
  late final TextEditingController _celular;
  late final TextEditingController _email;
  late final TextEditingController _direccion;
  late final TextEditingController _sector;
  late final TextEditingController _ciudad;
  late final TextEditingController _tiempoRes;
  late final TextEditingController _montoAlquiler;
  late final TextEditingController _empresa;
  late final TextEditingController _cargo;
  late final TextEditingController _ingreso;
  late final TextEditingController _tiempoLab;
  late final TextEditingController _otrosIngresos;
  late final TextEditingController _notas;
  late final TextEditingController _dependientes;

  String _tipoVivienda = 'Alquilada';
  String _frecuenciaPago = 'Mensual';
  String _sexo = 'M';

  late List<TextEditingController> _refNombre;
  late List<TextEditingController> _refRelacion;
  late List<TextEditingController> _refTelefono;
  late List<TextEditingController> _refDireccion;

  bool _guardando = false;

  bool _controllersListos = false;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.inicial);
  }

  @override
  void didUpdateWidget(covariant ExpedienteSolicitanteForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inicial != widget.inicial) {
      _rellenarDesde(widget.inicial);
    }
  }

  /// Crea controllers una sola vez (late final no se reasigna).
  void _initControllers(SolicitudCreditoExpediente e) {
    _nombre = TextEditingController();
    _cedula = TextEditingController();
    _estadoCivil = TextEditingController();
    _nacionalidad = TextEditingController();
    _telefono = TextEditingController();
    _celular = TextEditingController();
    _email = TextEditingController();
    _direccion = TextEditingController();
    _sector = TextEditingController();
    _ciudad = TextEditingController();
    _tiempoRes = TextEditingController();
    _montoAlquiler = TextEditingController();
    _empresa = TextEditingController();
    _cargo = TextEditingController();
    _ingreso = TextEditingController();
    _tiempoLab = TextEditingController();
    _otrosIngresos = TextEditingController();
    _notas = TextEditingController();
    _dependientes = TextEditingController();
    _refNombre = [TextEditingController(), TextEditingController()];
    _refRelacion = [TextEditingController(), TextEditingController()];
    _refTelefono = [TextEditingController(), TextEditingController()];
    _refDireccion = [TextEditingController(), TextEditingController()];
    _controllersListos = true;
    _rellenarDesde(e);
  }

  /// Solo actualiza textos (seguro si el padre reenvía [inicial]).
  void _rellenarDesde(SolicitudCreditoExpediente e) {
    if (!_controllersListos) return;
    _nombre.text = e.nombreCompleto;
    _cedula.text = e.cedula;
    _estadoCivil.text = e.estadoCivil;
    _nacionalidad.text = 'Dominicana';
    _telefono.text = e.telefono;
    _celular.text = e.celular;
    _email.text = e.email;
    _direccion.text = e.direccion;
    _sector.text = e.sector;
    _ciudad.text = e.ciudad;
    _tiempoRes.text = e.tiempoResidencia;
    _empresa.text = e.empresa;
    _cargo.text = e.cargo;
    _ingreso.text =
        e.ingresoMensual > 0 ? e.ingresoMensual.toStringAsFixed(2) : '';
    _tiempoLab.text = e.tiempoLaborando;
    _notas.text = e.notasAnalista;
    _dependientes.text = '${e.dependientes}';
    _tipoVivienda = e.tipoVivienda.isNotEmpty ? e.tipoVivienda : 'Alquilada';
    final refs = e.referencias.isEmpty
        ? const [
            ReferenciaSolicitante(orden: 1),
            ReferenciaSolicitante(orden: 2),
          ]
        : e.referencias;
    for (var i = 0; i < _refNombre.length; i++) {
      if (i < refs.length) {
        _refNombre[i].text = refs[i].nombre;
        _refRelacion[i].text = refs[i].relacion;
        _refTelefono[i].text = refs[i].telefono;
        _refDireccion[i].text = refs[i].direccion;
      } else {
        _refNombre[i].clear();
        _refRelacion[i].clear();
        _refTelefono[i].clear();
        _refDireccion[i].clear();
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _cedula,
      _estadoCivil,
      _nacionalidad,
      _telefono,
      _celular,
      _email,
      _direccion,
      _sector,
      _ciudad,
      _tiempoRes,
      _montoAlquiler,
      _empresa,
      _cargo,
      _ingreso,
      _tiempoLab,
      _otrosIngresos,
      _notas,
      _dependientes,
      ..._refNombre,
      ..._refRelacion,
      ..._refTelefono,
      ..._refDireccion,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  SolicitudCreditoExpediente _leer() {
    final refs = <ReferenciaSolicitante>[];
    for (var i = 0; i < _refNombre.length; i++) {
      refs.add(
        ReferenciaSolicitante(
          id: i < widget.inicial.referencias.length
              ? widget.inicial.referencias[i].id
              : null,
          solicitudId: widget.inicial.id,
          nombre: _refNombre[i].text.trim(),
          relacion: _refRelacion[i].text.trim(),
          telefono: _refTelefono[i].text.trim(),
          direccion: _refDireccion[i].text.trim(),
          orden: i + 1,
        ),
      );
    }
    // Campos UI extra se anexan a notas para no perderlos hasta migrar esquema
    final extra = <String>[];
    if (_nacionalidad.text.trim().isNotEmpty) {
      extra.add('Nacionalidad: ${_nacionalidad.text.trim()}');
    }
    extra.add('Sexo: $_sexo');
    if (_montoAlquiler.text.trim().isNotEmpty) {
      extra.add('Alquiler/Hipoteca: ${_montoAlquiler.text.trim()}');
    }
    extra.add('Frecuencia pago: $_frecuenciaPago');
    if (_otrosIngresos.text.trim().isNotEmpty) {
      extra.add('Otros ingresos: ${_otrosIngresos.text.trim()}');
    }
    final notasUser = _notas.text.trim();
    final notasFinal = [
      if (notasUser.isNotEmpty) notasUser,
      if (extra.isNotEmpty) '---\n${extra.join('\n')}',
    ].join('\n');

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
      ingresoMensual:
          double.tryParse(_ingreso.text.trim().replaceAll(',', '.')) ?? 0,
      tiempoLaborando: _tiempoLab.text.trim(),
      tipoVivienda: _tipoVivienda,
      dependientes: int.tryParse(_dependientes.text.trim()) ?? 0,
      notasAnalista: notasFinal,
      referencias: refs,
    );
  }

  Future<void> _guardar() async {
    if (!widget.editable || _guardando) return;
    setState(() => _guardando = true);
    try {
      await widget.onGuardar(_leer());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Campo estilo floating label del HTML.
  Widget _field(
    String label,
    TextEditingController c, {
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    final enabled = widget.editable;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          TextField(
            controller: c,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF94A3B8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF94A3B8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          Positioned(
            top: -8,
            left: 10,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, {String? trailing, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const Divider(height: 16, color: Color(0xFFF1F5F9)),
          child,
        ],
      ),
    );
  }

  Widget _refCard(int i) {
    final ok = _refNombre[i].text.trim().isNotEmpty &&
        _refTelefono[i].text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Referencia ${i + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              if (ok)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Color(0xFF047857)),
                      SizedBox(width: 4),
                      Text(
                        'Verificado',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          _field('Nombre', _refNombre[i]),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field('Relación / parentesco', _refRelacion[i])),
              const SizedBox(width: 8),
              Expanded(child: _field('Teléfono', _refTelefono[i])),
            ],
          ),
          const SizedBox(height: 8),
          _field('Dirección', _refDireccion[i]),
        ],
      ),
    );
  }

  double get _dtiPct {
    final ing =
        double.tryParse(_ingreso.text.trim().replaceAll(',', '.')) ?? 0;
    if (ing <= 0) return 0;
    // Aprox: si hay monto alquiler + sin otros compromisos documentados
    final alq =
        double.tryParse(_montoAlquiler.text.trim().replaceAll(',', '.')) ?? 0;
    return ((alq / ing) * 100).clamp(0, 99);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── §1 Datos personales ──
        _section(
          'Sección 1: Datos Personales',
          child: wide
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _field('Nombre completo', _nombre)),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Cédula / RNC', _cedula)),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Estado civil', _estadoCivil)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _field('Nacionalidad', _nacionalidad)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Número de Dependientes',
                            _dependientes,
                            keyboard: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Teléfono', _telefono)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _field('Celular', _celular)),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Email', _email)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                const Text(
                                  'Sexo:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // ignore: deprecated_member_use
                                Radio<String>(
                                  value: 'M',
                                  // ignore: deprecated_member_use
                                  groupValue: _sexo,
                                  // ignore: deprecated_member_use
                                  onChanged: widget.editable
                                      ? (v) => setState(() => _sexo = v!)
                                      : null,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Text('M', style: TextStyle(fontSize: 12)),
                                // ignore: deprecated_member_use
                                Radio<String>(
                                  value: 'F',
                                  // ignore: deprecated_member_use
                                  groupValue: _sexo,
                                  // ignore: deprecated_member_use
                                  onChanged: widget.editable
                                      ? (v) => setState(() => _sexo = v!)
                                      : null,
                                  visualDensity: VisualDensity.compact,
                                ),
                                const Text('F', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    _field('Nombre completo', _nombre),
                    const SizedBox(height: 8),
                    _field('Cédula / RNC', _cedula),
                    const SizedBox(height: 8),
                    _field('Estado civil', _estadoCivil),
                    const SizedBox(height: 8),
                    _field('Nacionalidad', _nacionalidad),
                    const SizedBox(height: 8),
                    _field('Número de Dependientes', _dependientes,
                        keyboard: TextInputType.number),
                    const SizedBox(height: 8),
                    _field('Teléfono', _telefono),
                    const SizedBox(height: 8),
                    _field('Celular', _celular),
                    const SizedBox(height: 8),
                    _field('Email', _email),
                  ],
                ),
        ),

        // ── §2 Domicilio ──
        _section(
          'Sección 2: Domicilio y Propiedad',
          child: wide
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _field('Dirección', _direccion)),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Sector', _sector)),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Ciudad / Municipio', _ciudad)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _field('Tiempo residiendo', _tiempoRes)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Monto de Alquiler / Hipoteca',
                            _montoAlquiler,
                            keyboard: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: DropdownButtonFormField<String>(
                              initialValue: _tipoVivienda,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: 'Confirmar vivienda propia/alquilada',
                                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Propia', child: Text('Propia')),
                                DropdownMenuItem(
                                    value: 'Alquilada',
                                    child: Text('Alquilada')),
                                DropdownMenuItem(
                                    value: 'Familiar',
                                    child: Text('Familiar')),
                              ],
                              onChanged: widget.editable
                                  ? (v) =>
                                      setState(() => _tipoVivienda = v ?? 'Alquilada')
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    _field('Dirección', _direccion),
                    const SizedBox(height: 8),
                    _field('Sector', _sector),
                    const SizedBox(height: 8),
                    _field('Ciudad / Municipio', _ciudad),
                    const SizedBox(height: 8),
                    _field('Tiempo residiendo', _tiempoRes),
                    const SizedBox(height: 8),
                    _field('Monto de Alquiler / Hipoteca', _montoAlquiler),
                  ],
                ),
        ),

        // ── §3 Laborales ──
        _section(
          'Sección 3: Datos Laborales y de Ingresos',
          child: wide
              ? Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _field('Empresa', _empresa)),
                        const SizedBox(width: 10),
                        Expanded(child: _field('Cargo', _cargo)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Ingreso mensual',
                            _ingreso,
                            keyboard: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _field('Tiempo laborando', _tiempoLab)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: DropdownButtonFormField<String>(
                              initialValue: _frecuenciaPago,
                              decoration: InputDecoration(
                                isDense: true,
                                labelText: 'Frecuencia de pago',
                                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'Semanal', child: Text('Semanal')),
                                DropdownMenuItem(
                                    value: 'Quincenal',
                                    child: Text('Quincenal')),
                                DropdownMenuItem(
                                    value: 'Mensual', child: Text('Mensual')),
                              ],
                              onChanged: widget.editable
                                  ? (v) => setState(
                                        () => _frecuenciaPago = v ?? 'Mensual',
                                      )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            'Otros Ingresos / Fuente',
                            _otrosIngresos,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  children: [
                    _field('Empresa', _empresa),
                    const SizedBox(height: 8),
                    _field('Cargo', _cargo),
                    const SizedBox(height: 8),
                    _field('Ingreso mensual', _ingreso,
                        keyboard: TextInputType.number),
                    const SizedBox(height: 8),
                    _field('Tiempo laborando', _tiempoLab),
                    const SizedBox(height: 8),
                    _field('Otros Ingresos / Fuente', _otrosIngresos),
                  ],
                ),
        ),

        // ── §4 Referencias ──
        _section(
          'Sección 4: Referencias',
          trailing: 'Mínimo dos referencias requeridas',
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _refCard(0)),
                    const SizedBox(width: 10),
                    Expanded(child: _refCard(1)),
                  ],
                )
              : Column(
                  children: [
                    _refCard(0),
                    const SizedBox(height: 10),
                    _refCard(1),
                  ],
                ),
        ),

        // ── §5 Análisis ──
        _section(
          'Sección 5: Análisis Financiero y Notas',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Notas del analista',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _notas,
                enabled: widget.editable,
                maxLines: 3,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText:
                      'Escriba sus observaciones de evaluación crediticia...',
                  hintStyle: const TextStyle(fontSize: 12),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DTI (Relación Deuda-Ingreso) %',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF78350F),
                            ),
                          ),
                          Text(
                            'Calculado sobre ingresos y compromisos declarados.',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_dtiPct.toStringAsFixed(0)}% · ${_dtiPct >= 70 ? 'ALTO' : _dtiPct >= 40 ? 'MEDIO' : 'BAJO'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (widget.editable) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_guardando ? 'Guardando…' : 'Guardar expediente'),
            ),
          ),
        ],
      ],
    );
  }
}
