enum TipoMedioCobro { cuentaBancaria, toke }

class MedioCobro {
  const MedioCobro({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.dato,
    required this.etiquetaDato,
    required this.titular,
    required this.instruccionCorta,
  });

  final String id;
  final String nombre;
  final TipoMedioCobro tipo;
  final String dato;
  final String etiquetaDato;
  final String titular;
  final String instruccionCorta;
}

/// Cuentas MartTech / Martin Pascual — fijas en la app (v1).
const kMediosCobroMartTech = <MedioCobro>[
  MedioCobro(
    id: 'toke',
    nombre: 'Toke',
    tipo: TipoMedioCobro.toke,
    dato: '829-652-0452',
    etiquetaDato: 'Celular Toke',
    titular: 'Martin Pascual',
    instruccionCorta:
        'En la app Popular elige Toke, envía al 829-652-0452 el monto exacto '
        'e incluye la referencia FG-XXXXX en el concepto.',
  ),
  MedioCobro(
    id: 'banreservas',
    nombre: 'Banreservas',
    tipo: TipoMedioCobro.cuentaBancaria,
    dato: '4289343070',
    etiquetaDato: 'Cuenta corriente',
    titular: 'Martin Pascual',
    instruccionCorta:
        'Transferir a cuenta corriente Banreservas e incluir la referencia FG-XXXXX.',
  ),
  MedioCobro(
    id: 'bhd',
    nombre: 'BHD León',
    tipo: TipoMedioCobro.cuentaBancaria,
    dato: '09631070067',
    etiquetaDato: 'Cuenta de ahorros',
    titular: 'Martin Pascual',
    instruccionCorta:
        'Transferir a cuenta de ahorros BHD e incluir la referencia FG-XXXXX.',
  ),
  MedioCobro(
    id: 'apap',
    nombre: 'Asociación Popular',
    tipo: TipoMedioCobro.cuentaBancaria,
    dato: '10276886028',
    etiquetaDato: 'Cuenta de ahorro',
    titular: 'Martin Pascual',
    instruccionCorta:
        'Transferir a Asociación Popular e incluir la referencia FG-XXXXX.',
  ),
];
