/// ¿El módulo tiene una pantalla programada en la app?
///
/// Debe coincidir con lo que hace `features/home/features/main/views/main.dart`:
/// primero se reconocen por el nombre (expedientes, auditoría, administración,
/// adjudicados) y luego por el número del módulo. Un módulo que no cumple ninguno
/// solo muestra la pantalla de inicio: se ve en el menú pero "no abre nada".
bool moduloTienePantalla(int id, String nombre) {
  final n = nombre.toLowerCase();
  if (n.contains('expediente') ||
      n.contains('auditor') ||
      n.contains('bitacora') ||
      n.contains('bitácora') ||
      n.contains('administraci') ||
      n.contains('adjudic')) {
    return true;
  }
  return id == 9004 || (id >= 1 && id <= 19);
}
