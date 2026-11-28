import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/core/contabilidad/data/config/plantilla_json_loader.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/cuenta_rol.dart';
import 'package:fiscogest_rd/core/contabilidad/domain/config/plantilla_contrapartida.dart';

void main() {
  test('fromMap DO roles → códigos', () {
    final p = PlantillaJsonLoader.fromMap({
      'paisCodigo': 'DO',
      'nombre': 'República Dominicana',
      'etiquetaImpuesto': 'ITBIS',
      'roles': {
        'caja': '1101',
        'cxc': '1103',
        'impuestoCredito': '1105',
        'inventario': '1201',
        'cxp': '2101',
        'impuestoPorPagar': '2104',
        'ingresosVentas': '4101',
        'costoVentas': '5101',
      },
    });
    expect(p.paisCodigo, 'DO');
    expect(p.etiquetaImpuesto, 'ITBIS');
    expect(p.codigo(CuentaRol.caja), '1101');
    expect(p.codigo(CuentaRol.costoVentas), '5101');
  });

  test('fromMap acepta impuestoCodigo como etiqueta', () {
    final p = PlantillaJsonLoader.fromMap({
      'paisCodigo': 'MX',
      'nombre': 'México',
      'impuestoCodigo': 'IVA',
      'roles': {'caja': '101.01', 'ingresosVentas': '401.01'},
    });
    expect(p.etiquetaImpuesto, 'IVA');
    expect(p.codigo(CuentaRol.caja), '101.01');
  });

  test('porPais fallback catálogo', () {
    final p = PlantillasContrapartida.porPais('PR');
    expect(p.paisCodigo, 'PR');
    expect(p.codigo(CuentaRol.inventario), isNotEmpty);
  });
}
