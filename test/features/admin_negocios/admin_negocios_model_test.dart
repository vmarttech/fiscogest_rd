
// [ADMIN_FASE2]
import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/features/admin_negocios/data/admin_negocios_remote.dart';

void main() {
  group('AdminNegocioRow.fromMap', () {
    test('mapea campos del listado', () {
      final row = AdminNegocioRow.fromMap(const {
        'id': 'a1b2',
        'nombre': 'Cafetería X',
        'rnc': '123456789',
        'telefono_contacto': '809-555-0001',
        'correo_contacto': 'a@b.com',
        'plan': 'pro',
        'estado_bruto': 'activa',
        'estado_derivado': 'activa',
        'vitalicia': false,
        'vigencia_tipo': 'mensual',
        'usuarios_totales': 4,
        'usuarios_activos': 3,
        'concesion_activa': 'free_six_months',
        'dias_restantes': 12,
      });
      expect(row.nombre, 'Cafetería X');
      expect(row.usuariosActivos, 3);
      expect(row.diasRestantes, 12);
      expect(row.concesionActiva, 'free_six_months');
    });

    test('valores nulos no rompen', () {
      final row = AdminNegocioRow.fromMap(const {'id': 'x', 'nombre': 'N'});
      expect(row.plan, '');
      expect(row.vitalicia, false);
      expect(row.usuariosTotales, 0);
    });
  });

  group('AdminNegocioDetalle.fromJson', () {
    test('arma listas y estado derivado', () {
      final d = AdminNegocioDetalle.fromJson(const {
        'negocio': {'id': 'x', 'nombre': 'Negocio N'},
        'estado_derivado': 'gracia',
        'usuarios': [
          {'id': 'u1', 'username': 'ana', 'nombre': 'Ana', 'rol': 'admin', 'activo': true},
        ],
        'concesiones': [
          {'id': 'c1', 'tipo': 'trial_30d', 'fecha_inicio': '2026-11-01', 'fecha_fin': '2026-11-30', 'origen': 'prueba'},
        ],
        'bitacora': [
          {'accion': 'renovar', 'motivo': 'pago', 'created_at': '2026-11-23T10:00:00Z'},
        ],
      });
      expect(d.estadoDerivado, 'gracia');
      expect(d.nombre, 'Negocio N');
      expect(d.usuarios.length, 1);
      expect(d.concesiones.first.tipo, 'trial_30d');
      expect(d.bitacora.first.accion, 'renovar');
    });
  });
}
