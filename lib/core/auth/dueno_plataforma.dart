/// Dueño de la plataforma FiscoGest (no Admin de un negocio cliente).
bool esDuenoPlataforma(String? username) {
  if (username == null) return false;
  final u = username.trim().toLowerCase();
  return u == 'mrtn' || u == 'mrtnpascual';
}
