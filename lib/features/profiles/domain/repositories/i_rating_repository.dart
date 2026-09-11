import 'package:f_roble_market/features/profiles/domain/models/user_rating.dart';

/// Las calificaciones entre las dos partes de una venta.
abstract class IRatingRepository {
  /// Las que ha recibido esa persona, de la mas reciente a la mas antigua.
  Future<List<UserRating>> receivedBy(String userId);

  /// Deja una calificacion. Falla si ya existe una de esa persona para esa
  /// venta: es una por venta y por parte.
  Future<UserRating> rate({
    required String listingId,
    required String raterId,
    required String raterName,
    required String ratedId,
    required RatedRole ratedRole,
    required int stars,
    required String comment,
  });
}
