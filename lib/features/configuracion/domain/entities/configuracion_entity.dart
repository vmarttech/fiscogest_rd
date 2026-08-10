import 'package:equatable/equatable.dart';

class ConfiguracionEmpresa extends Equatable {

  const ConfiguracionEmpresa({
    this.id,
    required this.nombreComercial,
    required this.razonSocial,
    required this.rnc,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.logoUrl,
    required this.moneda,
    required this.zonaHoraria,
    required this.formatoImpresion,
    required this.formatoFecha,
    required this.impuestoPorcentaje,
    required this.idioma,
  });
  final int? id;
  final String nombreComercial;
  final String razonSocial;
  final String rnc;
  final String direccion;
  final String telefono;
  final String correo;
  final String logoUrl;
  final String moneda;
  final String zonaHoraria;
  final String formatoImpresion;
  final String formatoFecha;
  final double impuestoPorcentaje;
  final String idioma;

  @override
  List<Object?> get props => [
        id,
        nombreComercial,
        razonSocial,
        rnc,
        direccion,
        telefono,
        correo,
        logoUrl,
        moneda,
        zonaHoraria,
        formatoImpresion,
        formatoFecha,
        impuestoPorcentaje,
        idioma,
      ];
}
