/// A quien se le mira el perfil.
///
/// Viaja el nombre junto al id porque no hay forma de leer el perfil de otra
/// persona desde la app: los nombres que se ven salen denormalizados de las
/// filas (`seller_name`, `buyer_name`, `rater_name`), asi que quien navega ya
/// lo tiene y pasarlo evita una consulta que no existe.
class ProfileArgs {
  const ProfileArgs({required this.userId, required this.name});

  final String userId;
  final String name;
}
