import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/features/comercial/data/dao/cuentas_cobrar_dao.dart';
import 'package:fiscogest_rd/features/creditos/data/dao/parametros_credito_dao.dart';
import 'package:fiscogest_rd/features/creditos/data/repositories/cuenta_por_cobrar_repository_impl.dart';
import 'package:fiscogest_rd/features/creditos/domain/entities/abono_credito.dart';

void main() {
  late AppDatabase db;
  late CuentasCobrarDao dao;
  late CuentaPorCobrarRepositoryImpl repository;
  late int cuentaId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    dao = CuentasCobrarDao(db);
    repository = CuentaPorCobrarRepositoryImpl(dao);
    await ParametrosCreditoDao(db).guardar(
      tasaMensualDefault: 0,
      cuotasDefault: 1,
      plazoMaxMeses: 12,
      diasGracia: 2,
      moraPorcentaje: 0.03,
      plantillaSolicitud: '',
      plantillaContrato: '',
    );

    final ahora = DateTime.now();
    final clienteId = await db
        .into(db.clientesTable)
        .insert(
          ClientesTableCompanion.insert(
            codigo: 'TEST-MORA',
            nombre: 'Cliente Mora',
            rncCedula: '000000000',
            telefono: '0000000000',
            correo: '',
            direccion: '',
          ),
        );
    final ventaId = await db
        .into(db.ventasTable)
        .insert(
          VentasTableCompanion.insert(
            clienteId: clienteId,
            fecha: ahora,
            formaPago: 'credito',
            numeroCotizacion: 'TEST-MORA-001',
            estadoDocumento: 'enCredito',
            usuarioId: 1,
            fechaRegistro: ahora,
          ),
        );
    cuentaId = await dao.crearCuentaPorVenta(
      clienteId: clienteId,
      ventaId: ventaId,
      montoOriginal: 900,
      fechaVencimiento: ahora.subtract(const Duration(days: 40)),
    );
    await dao.insertarCuotasPlan(
      cuentaCobrarId: cuentaId,
      cuotas: [
        (
          numero: 1,
          fechaVencimiento: ahora.subtract(const Duration(days: 12)),
          monto: 1000.0,
          montoCapital: 900.0,
          montoInteres: 100.0,
        ),
      ],
    );
  });

  tearDown(() async => db.close());

  test('Caja recibe cuota e interés más mora, sin duplicar el corte', () async {
    final primeraLectura = await repository.obtenerPorId(cuentaId);
    expect(primeraLectura, isNotNull);
    expect(primeraLectura!.saldoCuotasPendiente, closeTo(1000, 0.01));
    expect(primeraLectura.moraCalculada, closeTo(10, 0.01));
    expect(primeraLectura.saldoPendiente, closeTo(1010, 0.01));

    final segundaLectura = await repository.obtenerPorId(cuentaId);
    expect(segundaLectura!.moraCalculada, closeTo(10, 0.01));
    expect(segundaLectura.saldoPendiente, closeTo(1010, 0.01));

    await repository.registrarAbono(
      AbonoCredito(
        cuentaId: cuentaId,
        monto: 10,
        metodoPago: 'efectivo',
        fecha: DateTime.now(),
      ),
    );

    final despuesDeMora = await repository.obtenerPorId(cuentaId);
    expect(despuesDeMora!.moraCalculada, closeTo(0, 0.01));
    expect(despuesDeMora.saldoCuotasPendiente, closeTo(1000, 0.01));
    expect(despuesDeMora.saldoPendiente, closeTo(1000, 0.01));

    await repository.registrarAbono(
      AbonoCredito(
        cuentaId: cuentaId,
        monto: 1000,
        metodoPago: 'efectivo',
        fecha: DateTime.now(),
      ),
    );
    final saldada = await repository.obtenerPorId(cuentaId);
    expect(saldada!.estaPagada, isTrue);
    expect(saldada.totalAbonado, closeTo(1010, 0.01));
  });
}
