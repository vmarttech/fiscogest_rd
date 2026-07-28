# AUDITORÍA ETAPA 3.4 - KARDEX

Fecha: lun 27 jul 2026 13:01:10 AST

- Entidad Kardex : OK
- Tabla Drift Kardex : OK
- DAO Kardex : FALTA
- Repository Kardex : OK
- Repository Impl : OK
- Service Kardex : FALTA
- Provider Kardex : OK
- Pantalla Kardex : OK
- Registrar Entrada : OK
- Registrar Salida : OK
- Registrar Ajuste : OK
- Registrar Transferencia : FALTA
- Consultar Historial : OK
- Saldo Movimiento : OK

## Rutas
lib/features/ajustes_inventario/data/models/movimiento_kardex_model.dart:1:import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/movimiento_kardex.dart';
lib/features/ajustes_inventario/data/models/movimiento_kardex_model.dart:3:class MovimientoKardexModel {
lib/features/ajustes_inventario/data/models/movimiento_kardex_model.dart:5:  const MovimientoKardexModel({
lib/features/ajustes_inventario/data/models/movimiento_kardex_model.dart:17:  factory MovimientoKardexModel.fromEntity(MovimientoKardex entity) {
lib/features/ajustes_inventario/data/models/movimiento_kardex_model.dart:18:    return MovimientoKardexModel(
lib/features/ajustes_inventario/data/models/movimiento_kardex_model.dart:40:  MovimientoKardex toEntity() {
lib/features/ajustes_inventario/data/models/movimiento_kardex_model.dart:41:    return MovimientoKardex(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.dart:20:class KardexTable extends Table {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.dart:32:@DriftDatabase(tables: [AjusteInventarioTable, KardexTable])
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:539:class $KardexTableTable extends KardexTable
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:540:    with TableInfo<$KardexTableTable, KardexTableData> {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:544:  $KardexTableTable(this.attachedDatabase, [this._alias]);
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:662:  static const String $name = 'kardex_table';
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:665:    Insertable<KardexTableData> instance, {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:751:  KardexTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:753:    return KardexTableData(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:794:  $KardexTableTable createAlias(String alias) {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:795:    return $KardexTableTable(attachedDatabase, alias);
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:799:class KardexTableData extends DataClass implements Insertable<KardexTableData> {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:809:  const KardexTableData({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:839:  KardexTableCompanion toCompanion(bool nullToAbsent) {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:840:    return KardexTableCompanion(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:857:  factory KardexTableData.fromJson(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:862:    return KardexTableData(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:890:  KardexTableData copyWith({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:900:  }) => KardexTableData(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:913:  KardexTableData copyWithCompanion(KardexTableCompanion data) {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:914:    return KardexTableData(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:939:    return (StringBuffer('KardexTableData(')
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:968:      (other is KardexTableData &&
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:980:class KardexTableCompanion extends UpdateCompanion<KardexTableData> {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:990:  const KardexTableCompanion({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1001:  KardexTableCompanion.insert({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1017:  static Insertable<KardexTableData> custom({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1041:  KardexTableCompanion copyWith({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1052:    return KardexTableCompanion(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1100:    return (StringBuffer('KardexTableCompanion(')
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1121:  late final $KardexTableTable kardexTable = $KardexTableTable(this);
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1128:    kardexTable,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1410:typedef $$KardexTableTableCreateCompanionBuilder =
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1411:    KardexTableCompanion Function({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1422:typedef $$KardexTableTableUpdateCompanionBuilder =
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1423:    KardexTableCompanion Function({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1435:class $$KardexTableTableFilterComposer
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1436:    extends Composer<_$AjusteInventarioDatabase, $KardexTableTable> {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1437:  $$KardexTableTableFilterComposer({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1490:class $$KardexTableTableOrderingComposer
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1491:    extends Composer<_$AjusteInventarioDatabase, $KardexTableTable> {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1492:  $$KardexTableTableOrderingComposer({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1545:class $$KardexTableTableAnnotationComposer
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1546:    extends Composer<_$AjusteInventarioDatabase, $KardexTableTable> {
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1547:  $$KardexTableTableAnnotationComposer({
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1592:class $$KardexTableTableTableManager
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1596:          $KardexTableTable,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1597:          KardexTableData,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1598:          $$KardexTableTableFilterComposer,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1599:          $$KardexTableTableOrderingComposer,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1600:          $$KardexTableTableAnnotationComposer,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1601:          $$KardexTableTableCreateCompanionBuilder,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1602:          $$KardexTableTableUpdateCompanionBuilder,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1604:            KardexTableData,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1607:              $KardexTableTable,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1608:              KardexTableData
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1611:          KardexTableData,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1614:  $$KardexTableTableTableManager(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1616:    $KardexTableTable table,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1622:              $$KardexTableTableFilterComposer($db: db, $table: table),
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1624:              $$KardexTableTableOrderingComposer($db: db, $table: table),
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1626:              $$KardexTableTableAnnotationComposer($db: db, $table: table),
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1638:              }) => KardexTableCompanion(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1660:              }) => KardexTableCompanion.insert(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1679:typedef $$KardexTableTableProcessedTableManager =
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1682:      $KardexTableTable,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1683:      KardexTableData,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1684:      $$KardexTableTableFilterComposer,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1685:      $$KardexTableTableOrderingComposer,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1686:      $$KardexTableTableAnnotationComposer,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1687:      $$KardexTableTableCreateCompanionBuilder,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1688:      $$KardexTableTableUpdateCompanionBuilder,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1690:        KardexTableData,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1693:          $KardexTableTable,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1694:          KardexTableData
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1697:      KardexTableData,
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1706:  $$KardexTableTableTableManager get kardexTable =>
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.g.dart:1707:      $$KardexTableTableTableManager(_db, _db.kardexTable);
lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:64:  Future<void> registrarEnKardex(dynamic movimiento) async {}
lib/features/ajustes_inventario/domain/repositories/ajuste_inventario_repository.dart:2:import 'package:fiscogest_rd/features/ajustes_inventario/domain/entities/movimiento_kardex.dart';
lib/features/ajustes_inventario/domain/repositories/ajuste_inventario_repository.dart:8:  Future<void> registrarEnKardex(MovimientoKardex movimiento);
lib/features/ajustes_inventario/domain/entities/movimiento_kardex.dart:1:class MovimientoKardex {
lib/features/ajustes_inventario/domain/entities/movimiento_kardex.dart:3:  const MovimientoKardex({
lib/features/inventario/presentation/providers/kardex_provider.dart:2:import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
lib/features/inventario/presentation/providers/kardex_provider.dart:3:import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
lib/features/inventario/presentation/providers/kardex_provider.dart:4:import 'package:fiscogest_rd/features/inventario/domain/usecases/registrar_movimiento_kardex.dart';
lib/features/inventario/presentation/providers/kardex_provider.dart:5:import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';
lib/features/inventario/presentation/providers/kardex_provider.dart:6:import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
lib/features/inventario/presentation/providers/kardex_provider.dart:13:final driftKardexDatasourceProvider = Provider<DriftKardexDatasource>((ref) {
lib/features/inventario/presentation/providers/kardex_provider.dart:14:  return DriftKardexDatasource(ref.watch(databaseProvider));
lib/features/inventario/presentation/providers/kardex_provider.dart:18:final kardexRepositoryProvider = Provider<IKardexRepository>((ref) {
lib/features/inventario/presentation/providers/kardex_provider.dart:19:  return KardexRepositoryImpl(ref.watch(driftKardexDatasourceProvider));
lib/features/inventario/presentation/providers/kardex_provider.dart:23:final registrarMovimientoKardexProvider = Provider<RegistrarMovimientoKardex>((ref) {
lib/features/inventario/presentation/providers/kardex_provider.dart:24:  return RegistrarMovimientoKardex(ref.watch(kardexRepositoryProvider));
lib/features/inventario/presentation/providers/kardex_provider.dart:27:// Estado del Kardex para la UI
lib/features/inventario/presentation/providers/kardex_provider.dart:28:final kardexPorProductoProvider = FutureProvider.family<List<Kardex>, String>((ref, productoId) async {
lib/features/inventario/presentation/providers/kardex_provider.dart:29:  final repo = ref.watch(kardexRepositoryProvider);
lib/features/inventario/presentation/providers/producto_providers.dart:3:import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
lib/features/inventario/presentation/providers/producto_providers.dart:5:import 'package:fiscogest_rd/features/inventario/data/repositories/kardex_repository_impl.dart';
lib/features/inventario/presentation/providers/producto_providers.dart:8:import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
lib/features/inventario/presentation/providers/producto_providers.dart:10:final driftKardexDatasourceProvider = Provider<DriftKardexDatasource>((ref) {
lib/features/inventario/presentation/providers/producto_providers.dart:11:  return DriftKardexDatasource(ref.watch(databaseProvider));
lib/features/inventario/presentation/providers/producto_providers.dart:14:final kardexRepositoryProvider = Provider<IKardexRepository>((ref) {
lib/features/inventario/presentation/providers/producto_providers.dart:15:  return KardexRepositoryImpl(ref.watch(driftKardexDatasourceProvider));
lib/features/inventario/presentation/providers/producto_providers.dart:20:  final kardexRepo = ref.watch(kardexRepositoryProvider);
lib/features/inventario/presentation/providers/producto_providers.dart:21:  return ProductoRepositoryImpl(db, kardexRepo);
lib/features/inventario/presentation/pages/kardex_page.dart:3:import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
lib/features/inventario/presentation/pages/kardex_page.dart:4:import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
lib/features/inventario/presentation/pages/kardex_page.dart:6:class KardexPage extends ConsumerStatefulWidget {
lib/features/inventario/presentation/pages/kardex_page.dart:7:  const KardexPage({super.key, this.productoId});
lib/features/inventario/presentation/pages/kardex_page.dart:11:  ConsumerState<KardexPage> createState() => _KardexPageState();
lib/features/inventario/presentation/pages/kardex_page.dart:14:class _KardexPageState extends ConsumerState<KardexPage> {
lib/features/inventario/presentation/pages/kardex_page.dart:20:    final AsyncValue<List<Kardex>> movimientosAsync = ref.watch(
lib/features/inventario/presentation/pages/kardex_page.dart:21:      kardexPorProductoProvider(widget.productoId ?? ''),
lib/features/inventario/presentation/pages/kardex_page.dart:105:                    data: (List<Kardex> movimientos) {
lib/features/inventario/presentation/pages/kardex_page.dart:106:                      final List<Kardex> filtrados = movimientos.where((Kardex m) {
lib/features/inventario/presentation/pages/kardex_page.dart:131:                          final Kardex mov = filtrados[i];
lib/features/inventario/presentation/pages/productos_page.dart:5:import 'package:fiscogest_rd/features/inventario/presentation/providers/kardex_provider.dart';
lib/features/inventario/presentation/pages/productos_page.dart:7:import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
lib/features/inventario/presentation/pages/productos_page.dart:23:  String _filtroKardex = '';
lib/features/inventario/presentation/pages/productos_page.dart:24:  TipoMovimiento? _filtroTipoKardex;
lib/features/inventario/presentation/pages/productos_page.dart:64:            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Kardex'),
lib/features/inventario/presentation/pages/productos_page.dart:75:          _buildSeccionKardex(context),
lib/features/inventario/presentation/pages/productos_page.dart:276:  Widget _buildSeccionKardex(BuildContext context) {
lib/features/inventario/presentation/pages/productos_page.dart:277:    final AsyncValue<List<Kardex>> movimientosAsync = ref.watch(kardexPorProductoProvider(''));
lib/features/inventario/presentation/pages/productos_page.dart:285:            'Historial de Movimientos (Kardex)',
lib/features/inventario/presentation/pages/productos_page.dart:297:                  onChanged: (String v) => setState(() => _filtroKardex = v.toLowerCase()),
lib/features/inventario/presentation/pages/productos_page.dart:319:                  initialValue: _filtroTipoKardex,
lib/features/inventario/presentation/pages/productos_page.dart:346:                  onChanged: (TipoMovimiento? v) => setState(() => _filtroTipoKardex = v),
lib/features/inventario/presentation/pages/productos_page.dart:358:              data: (List<Kardex> movimientos) {
lib/features/inventario/presentation/pages/productos_page.dart:359:                final List<Kardex> filtrados = movimientos.where((Kardex m) {
lib/features/inventario/presentation/pages/productos_page.dart:360:                  final bool coincideTexto = m.productoId.toLowerCase().contains(_filtroKardex) ||
lib/features/inventario/presentation/pages/productos_page.dart:361:                      (m.documentoReferencia?.toLowerCase().contains(_filtroKardex) ?? false);
lib/features/inventario/presentation/pages/productos_page.dart:362:                  final bool coincideTipo = _filtroTipoKardex == null ||
lib/features/inventario/presentation/pages/productos_page.dart:363:                      m.tipoMovimiento == _filtroTipoKardex;
lib/features/inventario/presentation/pages/productos_page.dart:382:                    final Kardex mov = filtrados[i];
lib/features/inventario/presentation/pages/nuevo_producto_page.dart:365:                      const SnackBar(content: Text('¡Producto registrado y movimiento en Kardex creado!')),
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:4:class DriftKardexDatasource {
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:5:  DriftKardexDatasource(this._db);
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:8:  Future<void> insertar(KardexTableCompanion companion) async {
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:9:    await _db.into(_db.kardexTable).insert(companion);
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:12:  Future<List<KardexData>> obtenerHistorialPorProducto(String productoId) async {
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:13:    return await (_db.select(_db.kardexTable)
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:19:  Future<List<KardexData>> obtenerTodoElHistorial({DateTime? desde, DateTime? hasta}) async {
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:20:    final query = _db.select(_db.kardexTable);
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:31:  Future<KardexData?> obtenerUltimo(String productoId) async {
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:32:    return await (_db.select(_db.kardexTable)
lib/features/inventario/data/database/tables/kardex_table.dart:3:@DataClassName('KardexData')
lib/features/inventario/data/database/tables/kardex_table.dart:4:class KardexTable extends Table {
lib/features/inventario/data/repositories/producto_repository_impl.dart:3:import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
lib/features/inventario/data/repositories/producto_repository_impl.dart:5:import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
lib/features/inventario/data/repositories/producto_repository_impl.dart:9:  ProductoRepositoryImpl(this._db, this._kardexRepo);
lib/features/inventario/data/repositories/producto_repository_impl.dart:11:  final IKardexRepository _kardexRepo;
lib/features/inventario/data/repositories/producto_repository_impl.dart:34:      await _kardexRepo.registrarMovimiento(Kardex(
lib/features/inventario/data/repositories/kardex_repository_impl.dart:3:import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
lib/features/inventario/data/repositories/kardex_repository_impl.dart:4:import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
lib/features/inventario/data/repositories/kardex_repository_impl.dart:5:import 'package:fiscogest_rd/features/inventario/data/datasources/drift_kardex_datasource.dart';
lib/features/inventario/data/repositories/kardex_repository_impl.dart:7:class KardexRepositoryImpl implements IKardexRepository {
lib/features/inventario/data/repositories/kardex_repository_impl.dart:8:  KardexRepositoryImpl(this._datasource);
lib/features/inventario/data/repositories/kardex_repository_impl.dart:9:  final DriftKardexDatasource _datasource;
lib/features/inventario/data/repositories/kardex_repository_impl.dart:12:  Future<void> registrarMovimiento(Kardex kardex) async {
lib/features/inventario/data/repositories/kardex_repository_impl.dart:13:    final companion = KardexTableCompanion(
lib/features/inventario/data/repositories/kardex_repository_impl.dart:14:      id: Value(kardex.id!),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:15:      productoId: Value(kardex.productoId),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:16:      tipoMovimiento: Value(kardex.tipoMovimiento.name),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:17:      cantidad: Value(kardex.cantidad),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:18:      saldoAnterior: Value(kardex.saldoAnterior),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:19:      saldoNuevo: Value(kardex.saldoNuevo),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:20:      costoUnitario: Value(kardex.costoUnitario),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:21:      totalMovimiento: Value(kardex.totalMovimiento),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:22:      fechaMovimiento: Value(kardex.fechaMovimiento),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:23:      documentoReferencia: Value(kardex.documentoReferencia),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:24:      observacion: Value(kardex.observacion),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:25:      creadoEn: Value(kardex.creadoEn),
lib/features/inventario/data/repositories/kardex_repository_impl.dart:31:  Future<List<Kardex>> obtenerHistorialPorProducto(String productoId) async {
lib/features/inventario/data/repositories/kardex_repository_impl.dart:32:    final List<KardexData> datos = await _datasource.obtenerHistorialPorProducto(productoId);
lib/features/inventario/data/repositories/kardex_repository_impl.dart:33:    return datos.map((d) => Kardex(
lib/features/inventario/data/repositories/kardex_repository_impl.dart:50:  Future<List<Kardex>> obtenerTodoElHistorial({DateTime? desde, DateTime? hasta}) async {
lib/features/inventario/data/repositories/kardex_repository_impl.dart:51:    final List<KardexData> datos = await _datasource.obtenerTodoElHistorial(desde: desde, hasta: hasta);
lib/features/inventario/data/repositories/kardex_repository_impl.dart:52:    return datos.map((d) => Kardex(
lib/features/inventario/data/repositories/kardex_repository_impl.dart:70:    final KardexData? ultimo = await _datasource.obtenerUltimo(productoId);
lib/features/inventario/domain/interfaces/ikardex_repository.dart:1:import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
lib/features/inventario/domain/interfaces/ikardex_repository.dart:3:abstract class IKardexRepository {
lib/features/inventario/domain/interfaces/ikardex_repository.dart:4:  Future<void> registrarMovimiento(Kardex movimiento);
lib/features/inventario/domain/interfaces/ikardex_repository.dart:5:  Future<List<Kardex>> obtenerHistorialPorProducto(String productoId);
lib/features/inventario/domain/interfaces/ikardex_repository.dart:6:  Future<List<Kardex>> obtenerTodoElHistorial({DateTime? desde, DateTime? hasta});
lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart:1:import 'package:fiscogest_rd/features/inventario/domain/entities/kardex.dart';
lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart:2:import 'package:fiscogest_rd/features/inventario/domain/interfaces/ikardex_repository.dart';
lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart:4:class RegistrarMovimientoKardex {
lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart:6:  RegistrarMovimientoKardex(this._repo);
lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart:7:  final IKardexRepository _repo;
lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart:9:  Future<Kardex> ejecutar({
lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart:25:    final movimiento = Kardex(
lib/features/inventario/domain/entities/kardex.dart:3:part 'kardex.freezed.dart';
lib/features/inventario/domain/entities/kardex.dart:15:class Kardex with _$Kardex {
lib/features/inventario/domain/entities/kardex.dart:16:  const factory Kardex({
lib/features/inventario/domain/entities/kardex.dart:29:  }) = _Kardex;
lib/features/inventario/domain/entities/kardex.freezed.dart:6:part of 'kardex.dart';
lib/features/inventario/domain/entities/kardex.freezed.dart:19:mixin _$Kardex {
lib/features/inventario/domain/entities/kardex.freezed.dart:33:  /// Create a copy of Kardex
lib/features/inventario/domain/entities/kardex.freezed.dart:36:  $KardexCopyWith<Kardex> get copyWith => throw _privateConstructorUsedError;
lib/features/inventario/domain/entities/kardex.freezed.dart:40:abstract class $KardexCopyWith<$Res> {
lib/features/inventario/domain/entities/kardex.freezed.dart:41:  factory $KardexCopyWith(Kardex value, $Res Function(Kardex) then) =
lib/features/inventario/domain/entities/kardex.freezed.dart:42:      _$KardexCopyWithImpl<$Res, Kardex>;
lib/features/inventario/domain/entities/kardex.freezed.dart:61:class _$KardexCopyWithImpl<$Res, $Val extends Kardex>
lib/features/inventario/domain/entities/kardex.freezed.dart:62:    implements $KardexCopyWith<$Res> {
lib/features/inventario/domain/entities/kardex.freezed.dart:63:  _$KardexCopyWithImpl(this._value, this._then);
lib/features/inventario/domain/entities/kardex.freezed.dart:70:  /// Create a copy of Kardex
lib/features/inventario/domain/entities/kardex.freezed.dart:145:abstract class _$$KardexImplCopyWith<$Res> implements $KardexCopyWith<$Res> {
lib/features/inventario/domain/entities/kardex.freezed.dart:146:  factory _$$KardexImplCopyWith(
lib/features/inventario/domain/entities/kardex.freezed.dart:147:    _$KardexImpl value,
lib/features/inventario/domain/entities/kardex.freezed.dart:148:    $Res Function(_$KardexImpl) then,
lib/features/inventario/domain/entities/kardex.freezed.dart:149:  ) = __$$KardexImplCopyWithImpl<$Res>;
lib/features/inventario/domain/entities/kardex.freezed.dart:169:class __$$KardexImplCopyWithImpl<$Res>
lib/features/inventario/domain/entities/kardex.freezed.dart:170:    extends _$KardexCopyWithImpl<$Res, _$KardexImpl>
lib/features/inventario/domain/entities/kardex.freezed.dart:171:    implements _$$KardexImplCopyWith<$Res> {
lib/features/inventario/domain/entities/kardex.freezed.dart:172:  __$$KardexImplCopyWithImpl(
lib/features/inventario/domain/entities/kardex.freezed.dart:173:    _$KardexImpl _value,
lib/features/inventario/domain/entities/kardex.freezed.dart:174:    $Res Function(_$KardexImpl) _then,
lib/features/inventario/domain/entities/kardex.freezed.dart:177:  /// Create a copy of Kardex
lib/features/inventario/domain/entities/kardex.freezed.dart:196:      _$KardexImpl(
lib/features/inventario/domain/entities/kardex.freezed.dart:252:class _$KardexImpl implements _Kardex {
lib/features/inventario/domain/entities/kardex.freezed.dart:253:  const _$KardexImpl({
lib/features/inventario/domain/entities/kardex.freezed.dart:295:    return 'Kardex(id: $id, productoId: $productoId, tipoMovimiento: $tipoMovimiento, cantidad: $cantidad, saldoAnterior: $saldoAnterior, saldoNuevo: $saldoNuevo, costoUnitario: $costoUnitario, totalMovimiento: $totalMovimiento, fechaMovimiento: $fechaMovimiento, documentoReferencia: $documentoReferencia, observacion: $observacion, creadoEn: $creadoEn)';
lib/features/inventario/domain/entities/kardex.freezed.dart:302:            other is _$KardexImpl &&
lib/features/inventario/domain/entities/kardex.freezed.dart:345:  /// Create a copy of Kardex
lib/features/inventario/domain/entities/kardex.freezed.dart:350:  _$$KardexImplCopyWith<_$KardexImpl> get copyWith =>
lib/features/inventario/domain/entities/kardex.freezed.dart:351:      __$$KardexImplCopyWithImpl<_$KardexImpl>(this, _$identity);
lib/features/inventario/domain/entities/kardex.freezed.dart:354:abstract class _Kardex implements Kardex {
lib/features/inventario/domain/entities/kardex.freezed.dart:355:  const factory _Kardex({
lib/features/inventario/domain/entities/kardex.freezed.dart:368:  }) = _$KardexImpl;
lib/features/inventario/domain/entities/kardex.freezed.dart:395:  /// Create a copy of Kardex
lib/features/inventario/domain/entities/kardex.freezed.dart:399:  _$$KardexImplCopyWith<_$KardexImpl> get copyWith =>
lib/core/database/app_database.dart:15:import 'package:fiscogest_rd/features/inventario/data/database/tables/kardex_table.dart';
lib/core/database/app_database.dart:28:  KardexTable,    // ✅ CORRECTO
lib/core/database/app_database.dart:50:            await m.createTable(kardexTable);
lib/core/database/app_database.g.dart:3717:class $KardexTableTable extends KardexTable
lib/core/database/app_database.g.dart:3718:    with TableInfo<$KardexTableTable, KardexData> {
lib/core/database/app_database.g.dart:3722:  $KardexTableTable(this.attachedDatabase, [this._alias]);
lib/core/database/app_database.g.dart:3873:  static const String $name = 'kardex_table';
lib/core/database/app_database.g.dart:3876:    Insertable<KardexData> instance, {
lib/core/database/app_database.g.dart:3997:  KardexData map(Map<String, dynamic> data, {String? tablePrefix}) {
lib/core/database/app_database.g.dart:3999:    return KardexData(
lib/core/database/app_database.g.dart:4052:  $KardexTableTable createAlias(String alias) {
lib/core/database/app_database.g.dart:4053:    return $KardexTableTable(attachedDatabase, alias);
lib/core/database/app_database.g.dart:4057:class KardexData extends DataClass implements Insertable<KardexData> {
lib/core/database/app_database.g.dart:4070:  const KardexData({
lib/core/database/app_database.g.dart:4106:  KardexTableCompanion toCompanion(bool nullToAbsent) {
lib/core/database/app_database.g.dart:4107:    return KardexTableCompanion(
lib/core/database/app_database.g.dart:4127:  factory KardexData.fromJson(
lib/core/database/app_database.g.dart:4132:    return KardexData(
lib/core/database/app_database.g.dart:4168:  KardexData copyWith({
lib/core/database/app_database.g.dart:4181:  }) => KardexData(
lib/core/database/app_database.g.dart:4197:  KardexData copyWithCompanion(KardexTableCompanion data) {
lib/core/database/app_database.g.dart:4198:    return KardexData(
lib/core/database/app_database.g.dart:4234:    return (StringBuffer('KardexData(')
lib/core/database/app_database.g.dart:4269:      (other is KardexData &&
lib/core/database/app_database.g.dart:4284:class KardexTableCompanion extends UpdateCompanion<KardexData> {
lib/core/database/app_database.g.dart:4298:  const KardexTableCompanion({
lib/core/database/app_database.g.dart:4313:  KardexTableCompanion.insert({
lib/core/database/app_database.g.dart:4337:  static Insertable<KardexData> custom({
lib/core/database/app_database.g.dart:4370:  KardexTableCompanion copyWith({
lib/core/database/app_database.g.dart:4385:    return KardexTableCompanion(
lib/core/database/app_database.g.dart:4449:    return (StringBuffer('KardexTableCompanion(')
lib/core/database/app_database.g.dart:4480:  late final $KardexTableTable kardexTable = $KardexTableTable(this);
lib/core/database/app_database.g.dart:4494:    kardexTable,
lib/core/database/app_database.g.dart:6419:typedef $$KardexTableTableCreateCompanionBuilder =
lib/core/database/app_database.g.dart:6420:    KardexTableCompanion Function({
lib/core/database/app_database.g.dart:6435:typedef $$KardexTableTableUpdateCompanionBuilder =
lib/core/database/app_database.g.dart:6436:    KardexTableCompanion Function({
lib/core/database/app_database.g.dart:6452:class $$KardexTableTableFilterComposer
lib/core/database/app_database.g.dart:6453:    extends Composer<_$AppDatabase, $KardexTableTable> {
lib/core/database/app_database.g.dart:6454:  $$KardexTableTableFilterComposer({
lib/core/database/app_database.g.dart:6522:class $$KardexTableTableOrderingComposer
lib/core/database/app_database.g.dart:6523:    extends Composer<_$AppDatabase, $KardexTableTable> {
lib/core/database/app_database.g.dart:6524:  $$KardexTableTableOrderingComposer({
lib/core/database/app_database.g.dart:6592:class $$KardexTableTableAnnotationComposer
lib/core/database/app_database.g.dart:6593:    extends Composer<_$AppDatabase, $KardexTableTable> {
lib/core/database/app_database.g.dart:6594:  $$KardexTableTableAnnotationComposer({
lib/core/database/app_database.g.dart:6656:class $$KardexTableTableTableManager
lib/core/database/app_database.g.dart:6660:          $KardexTableTable,
lib/core/database/app_database.g.dart:6661:          KardexData,
lib/core/database/app_database.g.dart:6662:          $$KardexTableTableFilterComposer,
lib/core/database/app_database.g.dart:6663:          $$KardexTableTableOrderingComposer,
lib/core/database/app_database.g.dart:6664:          $$KardexTableTableAnnotationComposer,
lib/core/database/app_database.g.dart:6665:          $$KardexTableTableCreateCompanionBuilder,
lib/core/database/app_database.g.dart:6666:          $$KardexTableTableUpdateCompanionBuilder,
lib/core/database/app_database.g.dart:6668:            KardexData,
lib/core/database/app_database.g.dart:6669:            BaseReferences<_$AppDatabase, $KardexTableTable, KardexData>,
lib/core/database/app_database.g.dart:6671:          KardexData,
lib/core/database/app_database.g.dart:6674:  $$KardexTableTableTableManager(_$AppDatabase db, $KardexTableTable table)
lib/core/database/app_database.g.dart:6680:              $$KardexTableTableFilterComposer($db: db, $table: table),
lib/core/database/app_database.g.dart:6682:              $$KardexTableTableOrderingComposer($db: db, $table: table),
lib/core/database/app_database.g.dart:6684:              $$KardexTableTableAnnotationComposer($db: db, $table: table),
lib/core/database/app_database.g.dart:6700:              }) => KardexTableCompanion(
lib/core/database/app_database.g.dart:6730:              }) => KardexTableCompanion.insert(
lib/core/database/app_database.g.dart:6753:typedef $$KardexTableTableProcessedTableManager =
lib/core/database/app_database.g.dart:6756:      $KardexTableTable,
lib/core/database/app_database.g.dart:6757:      KardexData,
lib/core/database/app_database.g.dart:6758:      $$KardexTableTableFilterComposer,
lib/core/database/app_database.g.dart:6759:      $$KardexTableTableOrderingComposer,
lib/core/database/app_database.g.dart:6760:      $$KardexTableTableAnnotationComposer,
lib/core/database/app_database.g.dart:6761:      $$KardexTableTableCreateCompanionBuilder,
lib/core/database/app_database.g.dart:6762:      $$KardexTableTableUpdateCompanionBuilder,
lib/core/database/app_database.g.dart:6764:        KardexData,
lib/core/database/app_database.g.dart:6765:        BaseReferences<_$AppDatabase, $KardexTableTable, KardexData>,
lib/core/database/app_database.g.dart:6767:      KardexData,
lib/core/database/app_database.g.dart:6790:  $$KardexTableTableTableManager get kardexTable =>
lib/core/database/app_database.g.dart:6791:      $$KardexTableTableTableManager(_db, _db.kardexTable);

## Archivos Kardex
lib/features/ajustes_inventario/data/models/movimiento_kardex_model.dart
lib/features/ajustes_inventario/domain/entities/movimiento_kardex.dart
lib/features/inventario/presentation/providers/kardex_provider.dart
lib/features/inventario/presentation/pages/kardex_page.dart
lib/features/inventario/data/datasources/drift_kardex_datasource.dart
lib/features/inventario/data/database/tables/kardex_table.dart
lib/features/inventario/data/repositories/kardex_repository_impl.dart
lib/features/inventario/domain/interfaces/ikardex_repository.dart
lib/features/inventario/domain/usecases/registrar_movimiento_kardex.dart
lib/features/inventario/domain/entities/kardex.dart
lib/features/inventario/domain/entities/kardex.freezed.dart

## Pendientes
lib/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart:41:  void _abrirBuscador(List<Producto> todos) {
lib/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart:46:        productos: todos,
lib/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart:63:        data: (todos) => SingleChildScrollView(
lib/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart:98:                      onPressed: () => _abrirBuscador(todos),
lib/features/ajustes_inventario/presentation/pages/registrar_ajuste_page.dart:156:                      final producto = _productoSeleccionado ?? todos.firstWhere(
lib/features/ajustes_inventario/data/datasources/ajuste_inventario_database.dart:44:  Future<List<AjusteInventarioTableData>> listarTodosAjustes() {
lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:16:    // ✅ Usa método existente en la interfaz oficial
lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:17:    final List<Producto> todos = await _inventarioRepo.listarProductos();
lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:18:    final Producto? producto = todos.firstWhere(
lib/features/clientes/data/dao/cliente_dao.dart:11:  Future<List<ClientesTableData>> obtenerTodos() => select(clientesTable).get();
lib/features/clientes/data/repositories/cliente_repository_impl.dart:14:    final resultados = await _clienteDao.obtenerTodos();
lib/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart:21:// ✅ Casos de uso: todos reciben la interfaz, funcionan sin errores
lib/features/inventario/presentation/providers/unidad_medida_providers.dart:21:    return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/unidad_medida_providers.dart:28:      return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/unidad_medida_providers.dart:36:      return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/unidad_medida_providers.dart:44:      return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/unidadmedida_providers.dart:6:import 'package:fiscogest_rd/features/inventario/domain/usecases/obtener_todos_unidadmedida_usecase.dart';
lib/features/inventario/presentation/providers/unidadmedida_providers.dart:21:final obtenerTodosUnidadMedidaUseCaseProvider = Provider<ObtenerTodosUnidadMedidaUseCase>((ref) {
lib/features/inventario/presentation/providers/unidadmedida_providers.dart:23:  return ObtenerTodosUnidadMedidaUseCase(repo);
lib/features/inventario/presentation/providers/categoria_providers.dart:21:    return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/categoria_providers.dart:28:      return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/categoria_providers.dart:36:      return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/categoria_providers.dart:44:      return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/marca_providers.dart:21:    return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/marca_providers.dart:28:      return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/marca_providers.dart:36:      return _repo.obtenerTodos();
lib/features/inventario/presentation/providers/marca_providers.dart:44:      return _repo.obtenerTodos();
lib/features/inventario/presentation/pages/registrar_salida_page.dart:55:      cantidad: cantidad.toInt(), // ✅ Convertimos a int como espera el método
lib/features/inventario/data/mappers/producto_mapper.dart:6:  static Producto toDomain(ProductosTableData row) {
lib/features/inventario/data/datasources/drift_kardex_datasource.dart:19:  Future<List<KardexData>> obtenerTodoElHistorial({DateTime? desde, DateTime? hasta}) async {
lib/features/inventario/data/dao/unidadmedida_dao.dart:8:  Future<List<UnidadMedida>> obtenerTodos() async => [];
lib/features/inventario/data/dao/marca_dao.dart:8:  Future<List<Marca>> obtenerTodos() async => [];
lib/features/inventario/data/dao/categoria_dao.dart:8:  Future<List<Categoria>> obtenerTodos() async => [];
lib/features/inventario/data/repositories/marca_repository_impl.dart:12:  Future<List<Marca>> obtenerTodos() async {
lib/features/inventario/data/repositories/categoria_repository_impl.dart:12:  Future<List<Categoria>> obtenerTodos() async {
lib/features/inventario/data/repositories/unidad_medida_repository_impl.dart:12:  Future<List<UnidadMedida>> obtenerTodos() async {
lib/features/inventario/data/repositories/producto_repository_impl.dart:16:    return results.map(ProductoDataMapper.toDomain).toList();
lib/features/inventario/data/repositories/producto_repository_impl.dart:24:    return ProductoDataMapper.toDomain(row);
lib/features/inventario/data/repositories/kardex_repository_impl.dart:50:  Future<List<Kardex>> obtenerTodoElHistorial({DateTime? desde, DateTime? hasta}) async {
lib/features/inventario/data/repositories/kardex_repository_impl.dart:51:    final List<KardexData> datos = await _datasource.obtenerTodoElHistorial(desde: desde, hasta: hasta);
lib/features/inventario/data/repositories/unidadmedida_repository_impl.dart:9:  @override Future<List<UnidadMedida>> obtenerTodos() async => _dao.obtenerTodos();
lib/features/inventario/domain/interfaces/i_categoria_repository.dart:4:  Future<List<Categoria>> obtenerTodos();
lib/features/inventario/domain/interfaces/ikardex_repository.dart:6:  Future<List<Kardex>> obtenerTodoElHistorial({DateTime? desde, DateTime? hasta});
lib/features/inventario/domain/interfaces/i_unidadmedida_repository.dart:4:  Future<List<UnidadMedida>> obtenerTodos();
lib/features/inventario/domain/interfaces/i_marca_repository.dart:4:  Future<List<Marca>> obtenerTodos();
lib/features/inventario/domain/usecases/obtener_todos_unidadmedida_usecase.dart:4:class ObtenerTodosUnidadMedidaUseCase {
lib/features/inventario/domain/usecases/obtener_todos_unidadmedida_usecase.dart:5:  ObtenerTodosUnidadMedidaUseCase(this._repo);
lib/features/inventario/domain/usecases/obtener_todos_unidadmedida_usecase.dart:8:  Future<List<UnidadMedida>> ejecutar() async => _repo.obtenerTodos();
lib/features/inventario/domain/usecases/obtener_todos_categoria_usecase.dart:4:class ObtenerTodosCategoriaUseCase {
lib/features/inventario/domain/usecases/obtener_todos_categoria_usecase.dart:5:  ObtenerTodosCategoriaUseCase(this._repo);
lib/features/inventario/domain/usecases/obtener_todos_categoria_usecase.dart:8:  Future<List<Categoria>> ejecutar() async => _repo.obtenerTodos();
lib/features/inventario/domain/usecases/obtener_todos_marca_usecase.dart:4:class ObtenerTodosMarcaUseCase {
lib/features/inventario/domain/usecases/obtener_todos_marca_usecase.dart:5:  ObtenerTodosMarcaUseCase(this._repo);
lib/features/inventario/domain/usecases/obtener_todos_marca_usecase.dart:8:  Future<List<Marca>> ejecutar() async => _repo.obtenerTodos();
lib/features/inventario/domain/repositories/marca_repository.dart:4:  Future<List<Marca>> obtenerTodos();
lib/features/inventario/domain/repositories/unidad_medida_repository.dart:4:  Future<List<UnidadMedida>> obtenerTodos();
lib/features/inventario/domain/repositories/categoria_repository.dart:4:  Future<List<Categoria>> obtenerTodos();
lib/features/inventario/domain/entities/entrada.dart:16:      cantidad: (map['cantidad'] as num).toDouble(),
lib/core/servicios_transversales/operaciones_entrada_service.dart:30:      // 1. Crear la entidad de entrada (ÚNICO lugar válido para crearla en todo el flujo)
lib/core/services/base_service.dart:5:  // Métodos transversales o utilitarios comunes para servicios de negocio

## Duplicados
No encontrados.

## Violaciones Arquitectónicas

## Flutter Analyze
Analyzing fiscogest_rd...                                       

   info • Constructor declarations should be before non-constructor declarations. Try moving the constructor declaration before all other members • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:12:3 • sort_constructors_first
  error • The property 'stock' can't be unconditionally accessed because the receiver can be 'null'. Try making the access conditional (using '?.') or adding a null check to the target ('!') • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:24:20 • unchecked_use_of_nullable_value
  error • The property 'stock' can't be unconditionally accessed because the receiver can be 'null'. Try making the access conditional (using '?.') or adding a null check to the target ('!') • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:25:20 • unchecked_use_of_nullable_value
  error • The property 'id' can't be unconditionally accessed because the receiver can be 'null'. Try making the access conditional (using '?.') or adding a null check to the target ('!') • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:29:52 • unchecked_use_of_nullable_value
  error • The method 'AjusteInventarioTableCompanion' isn't defined for the type 'AjusteInventarioRepositoryImpl'. Try correcting the name to the name of an existing method, or defining a method named 'AjusteInventarioTableCompanion' • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:32:23 • undefined_method
warning • The type argument(s) of the constructor 'Value.absent' can't be inferred. Use explicit type argument(s) for 'Value.absent' • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:33:57 • inference_failure_on_instance_creation
  error • The property 'id' can't be unconditionally accessed because the receiver can be 'null'. Try making the access conditional (using '?.') or adding a null check to the target ('!') • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:34:34 • unchecked_use_of_nullable_value
warning • The type argument(s) of the function 'into' can't be inferred. Use explicit type argument(s) for 'into' • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:41:15 • inference_failure_on_function_invocation
  error • The getter 'ajusteInventarioTable' isn't defined for the type 'AppDatabase'. Try importing the library that defines 'ajusteInventarioTable', correcting the name to the name of an existing getter, or defining a getter or field named 'ajusteInventarioTable' • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:41:24 • undefined_getter
warning • The type argument(s) of the function 'select' can't be inferred. Use explicit type argument(s) for 'select' • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:46:29 • inference_failure_on_function_invocation
  error • The getter 'ajusteInventarioTable' isn't defined for the type 'AppDatabase'. Try importing the library that defines 'ajusteInventarioTable', correcting the name to the name of an existing getter, or defining a getter or field named 'ajusteInventarioTable' • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:46:40 • undefined_getter
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int?'.  • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:48:11 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int'.  • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:49:19 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:50:19 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:51:17 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:52:15 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int'.  • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:53:18 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'DateTime'.  • lib/features/ajustes_inventario/data/repositories/ajuste_inventario_repository_impl.dart:54:22 • argument_type_not_assignable
  error • Undefined name 'databaseProvider'. Try correcting the name to one that is defined, or defining the name • lib/features/ajustes_inventario/presentation/providers/ajuste_inventario_provider.dart:16:38 • undefined_identifier
  error • Missing concrete implementation of 'InventarioRepositoryInterface.obtenerProductoPorCodigo'. Try implementing the missing method, or make the class abstract • lib/features/inventario/data/repositories/inventario_repository_impl.dart:6:7 • non_abstract_class_inherits_abstract_member
   info • Constructor declarations should be before non-constructor declarations. Try moving the constructor declaration before all other members • lib/features/inventario/data/repositories/inventario_repository_impl.dart:9:3 • sort_constructors_first
  error • The argument type 'int?' can't be assigned to the parameter type 'int'.  • lib/features/inventario/data/repositories/inventario_repository_impl.dart:73:34 • argument_type_not_assignable
   info • Constructor declarations should be before non-constructor declarations. Try moving the constructor declaration before all other members • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:10:3 • sort_constructors_first
warning • The type argument(s) of the function 'into' can't be inferred. Use explicit type argument(s) for 'into' • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:14:15 • inference_failure_on_function_invocation
  error • The getter 'conteosFisicos' isn't defined for the type 'AppDatabase'. Try importing the library that defines 'conteosFisicos', correcting the name to the name of an existing getter, or defining a getter or field named 'conteosFisicos' • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:14:24 • undefined_getter
  error • Undefined name 'ConteosFisicosCompanion'. Try correcting the name to one that is defined, or defining the name • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:15:7 • undefined_identifier
warning • The type argument(s) of the function 'select' can't be inferred. Use explicit type argument(s) for 'select' • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:28:33 • inference_failure_on_function_invocation
  error • The getter 'conteosFisicos' isn't defined for the type 'AppDatabase'. Try importing the library that defines 'conteosFisicos', correcting the name to the name of an existing getter, or defining a getter or field named 'conteosFisicos' • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:28:44 • undefined_getter
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int?'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:30:11 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:31:21 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'DateTime'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:32:20 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String?'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:33:22 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:34:18 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'DateTime'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:35:22 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:36:42 • argument_type_not_assignable
warning • The type argument(s) of the function 'select' can't be inferred. Use explicit type argument(s) for 'select' • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:42:34 • inference_failure_on_function_invocation
  error • The getter 'diferenciasConteo' isn't defined for the type 'AppDatabase'. Try importing the library that defines 'diferenciasConteo', correcting the name to the name of an existing getter, or defining a getter or field named 'diferenciasConteo' • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:42:45 • undefined_getter
  error • The getter 'conteoId' isn't defined for the type 'HasResultSet'. Try importing the library that defines 'conteoId', correcting the name to the name of an existing getter, or defining a getter or field named 'conteoId' • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:43:28 • undefined_getter
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:46:11 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:47:17 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'int'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:48:19 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:49:23 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:50:23 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:51:21 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:52:20 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'double'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:53:19 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String?'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:54:15 • argument_type_not_assignable
  error • The argument type 'dynamic' can't be assigned to the parameter type 'String'.  • lib/features/inventario_fisico/data/repositories/inventario_fisico_repository_impl.dart:55:15 • argument_type_not_assignable
  error • The argument type 'Provider<InventarioFisicoDatabase>' can't be assigned to the parameter type 'ProviderListenable<AppDatabase>'.  • lib/features/inventario_fisico/presentation/providers/inventario_fisico_provider.dart:18:51 • argument_type_not_assignable
  error • Undefined name 'databaseProvider'. Try correcting the name to one that is defined, or defining the name • lib/main.dart:26:7 • undefined_identifier

50 issues found. (ran in 4.1s)

## Avance estimado

84 %
