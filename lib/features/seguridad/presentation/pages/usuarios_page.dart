import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:fiscogest_rd/core/auth/sesion_provider.dart';
import 'package:fiscogest_rd/core/auth/permisos_roles.dart';
import 'package:fiscogest_rd/core/database/app_database.dart';
import 'package:fiscogest_rd/core/database/database_provider.dart';
import 'package:fiscogest_rd/core/ui/app_scaffold.dart';
import 'package:fiscogest_rd/core/ui/app_colors.dart';
import 'package:fiscogest_rd/core/ui/app_typography.dart';
import 'package:fiscogest_rd/core/ui/app_breakpoints.dart';
import 'package:fiscogest_rd/features/seguridad/data/auth_service.dart';
import 'package:fiscogest_rd/features/seguridad/data/dao/usuarios_dao.dart';

final _usuariosListaProvider = FutureProvider.autoDispose<List<UsuarioData>>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  return UsuariosDao(db).obtenerTodos();
});

class UsuariosPage extends ConsumerWidget {
  const UsuariosPage({super.key});

  static const routeName = 'usuarios';
  static const path = '/usuarios';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesion = ref.watch(sesionProvider);
    final mobile = AppBreakpoints.isMobile(context);
    final async = ref.watch(_usuariosListaProvider);

    if (sesion == null || !sesion.esAdmin) {
      return const AppScaffold(
        title: 'USUARIOS',
        body: Center(
          child: Text('Solo el administrador puede gestionar usuarios.'),
        ),
      );
    }

    return AppScaffold(
      title: 'USUARIOS',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              mobile ? 16 : 24,
              12,
              mobile ? 16 : 24,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Cuentas del sistema. En modo normal cada rol limita el menú.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () => _abrirFormulario(context, ref, null),
                  icon: const Icon(Icons.person_add_outlined, size: 20),
                  label: Text(mobile ? 'Nuevo' : 'Nuevo usuario'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (lista) {
                if (lista.isEmpty) {
                  return const Center(child: Text('No hay usuarios'));
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    mobile ? 16 : 24,
                    4,
                    mobile ? 16 : 24,
                    24,
                  ),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final u = lista[i];
                    final activo = u.estado.toLowerCase() == 'activo';
                    return Material(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _abrirFormulario(context, ref, u),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      u.username,
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${u.nombre}${u.apellido != null && u.apellido!.isNotEmpty ? ' ${u.apellido}' : ''} · ${u.rol}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (activo
                                              ? AppColors.success
                                              : AppColors.error)
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  u.estado,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: activo
                                        ? AppColors.success
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: activo ? 'Desactivar' : 'Activar',
                                onPressed: () async {
                                  final dao = UsuariosDao(
                                    ref.read(databaseProvider),
                                  );
                                  await dao.cambiarEstado(
                                    u.id,
                                    activo ? 'Inactivo' : 'Activo',
                                  );
                                  ref.invalidate(_usuariosListaProvider);
                                },
                                icon: Icon(
                                  activo
                                      ? Icons.block_outlined
                                      : Icons.check_circle_outline,
                                  color: activo
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _abrirFormulario(
    BuildContext context,
    WidgetRef ref,
    UsuarioData? existente,
  ) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FormUsuarioSheet(existente: existente),
    );
    if (ok == true) {
      ref.invalidate(_usuariosListaProvider);
    }
  }
}

class _FormUsuarioSheet extends ConsumerStatefulWidget {
  const _FormUsuarioSheet({this.existente});
  final UsuarioData? existente;

  @override
  ConsumerState<_FormUsuarioSheet> createState() => _FormUsuarioSheetState();
}

class _FormUsuarioSheetState extends ConsumerState<_FormUsuarioSheet> {
  final _userCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _rol = 'Vendedor';
  String _estado = 'Activo';
  bool _guardando = false;
  String? _error;
  bool _ocultar = true;

  static const roles = rolesDisponibles;

  @override
  void initState() {
    super.initState();
    final e = widget.existente;
    if (e != null) {
      _userCtrl.text = e.username;
      _nombreCtrl.text = e.nombre;
      _rol = e.rol;
      _estado = e.estado;
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _nombreCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final user = _userCtrl.text.trim();
    final nombre = _nombreCtrl.text.trim();
    final pass = _passCtrl.text;
    final esNuevo = widget.existente == null;

    if (user.length < 3) {
      setState(() => _error = 'Usuario: mínimo 3 caracteres');
      return;
    }
    if (nombre.isEmpty) {
      setState(() => _error = 'Indique el nombre');
      return;
    }
    if (nombre.length > 80) {
      setState(() => _error = 'El nombre no puede superar 80 caracteres');
      return;
    }
    if (esNuevo && pass.length < 6) {
      setState(() => _error = 'Contraseña: mínimo 6 caracteres');
      return;
    }
    if (!esNuevo && pass.isNotEmpty && pass.length < 6) {
      setState(() => _error = 'Contraseña: mínimo 6 caracteres');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    try {
      final db = ref.read(databaseProvider);
      final dao = UsuariosDao(db);

      if (esNuevo) {
        final existe = await dao.obtenerPorUsuario(user);
        if (existe != null) {
          setState(() => _error = 'Ese usuario ya existe');
          return;
        }
        await dao.insertar(
          UsuariosTableCompanion.insert(
            nombre: nombre,
            username: user,
            passwordHash: AuthService.hashPassword(pass),
            rol: Value(_rol),
            estado: Value(_estado),
            requiereSetupInicial: const Value(false),
          ),
        );
      } else {
        final e = widget.existente!;
        // No permitir dejar el sistema sin ningún Admin activo
        if (e.rol.toLowerCase().contains('admin') &&
            _rol.toLowerCase() != 'admin') {
          final todos = await dao.obtenerTodos();
          final otrosAdmin = todos.where(
            (u) =>
                u.id != e.id &&
                u.rol.toLowerCase().contains('admin') &&
                u.estado.toLowerCase() == 'activo',
          );
          if (otrosAdmin.isEmpty) {
            setState(() => _error = 'Debe quedar al menos un Admin activo');
            return;
          }
        }
        await (db.update(
          db.usuariosTable,
        )..where((t) => t.id.equals(e.id))).write(
          UsuariosTableCompanion(
            username: Value(user),
            nombre: Value(nombre),
            rol: Value(_rol),
            estado: Value(_estado),
            passwordHash: pass.isEmpty
                ? const Value.absent()
                : Value(AuthService.hashPassword(pass)),
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final esNuevo = widget.existente == null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                esNuevo ? 'Nuevo usuario' : 'Editar usuario',
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _userCtrl,
                decoration: const InputDecoration(
                  labelText: 'Usuario *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _nombreCtrl,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passCtrl,
                obscureText: _ocultar,
                decoration: InputDecoration(
                  labelText: esNuevo
                      ? 'Contraseña *'
                      : 'Nueva contraseña (opcional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultar
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _ocultar = !_ocultar),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: roles.contains(_rol) ? _rol : 'Vendedor',
                decoration: const InputDecoration(
                  labelText: 'Rol *',
                  border: OutlineInputBorder(),
                ),
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _rol = v);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _estado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'Inactivo', child: Text('Inactivo')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _estado = v);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _guardando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(esNuevo ? 'Crear usuario' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
