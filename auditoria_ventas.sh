echo "=== HISTORIAL DE CAMBIOS RECIENTES EN VENTAS ==="
git log -n 5 --oneline --stat lib/features/ventas/
echo -e "\n=== ÚLTIMOS COMMITS DEL PROYECTO ==="
git log -n 5 --oneline
echo -e "\n=== VERIFICANDO RUTAS EN APP_SHELL ==="
grep -rn "ventas" lib/core/presentation/widgets/app_shell.dart
