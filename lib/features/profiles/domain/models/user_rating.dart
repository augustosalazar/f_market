/// El papel que jugaba la persona calificada en esa venta.
///
/// Se guarda porque no significan lo mismo: a un vendedor se le califica el
/// carro y el trato, y a un comprador el haber aparecido y cumplido.
enum RatedRole {
  seller('Como vendedor'),
  buyer('Como comprador');

  const RatedRole(this.label);
  final String label;

  static RatedRole fromName(String name) =>
      RatedRole.values.firstWhere((r) => r.name == name, orElse: () => seller);
}

/// Una calificacion de una parte de la venta a la otra.
///
/// Es **inmutable**: se escribe una vez por venta y por parte, y no se edita
/// ni se borra. Poder reescribirla convertiria el historial en algo que se
/// negocia despues ("bajame la estrella y te devuelvo el dinero").
class UserRating {
  const UserRating({
    required this.id,
    required this.listingId,
    required this.raterId,
    required this.raterName,
    required this.ratedId,
    required this.ratedRole,
    required this.stars,
    required this.comment,
    required this.createdAt,
  });

  static const int minStars = 1;
  static const int maxStars = 5;

  final String id;

  /// La venta que la justifica. Sin ella no se puede calificar.
  final String listingId;
  final String raterId;
  final String raterName;
  final String ratedId;
  final RatedRole ratedRole;
  final int stars;
  final String comment;
  final DateTime createdAt;
}
