/// Un usuario de la aplicacion.
///
/// `userId` es el identificador del usuario en Roble (el que referencian las
/// demas tablas). No se confunde con el `id` de la fila de perfil.
class AppUser {
  const AppUser({
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  final String userId;
  final String name;
  final String email;
  final String? photoUrl;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
