import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';

/// El catalogo. `search` es publico a proposito: el requisito pide que todas
/// las publicaciones se vean sin haber iniciado sesion.
abstract class IListingRepository {
  Future<List<CarListing>> search(ListingFilter filter);

  Future<CarListing?> byId(String id);

  Future<List<CarListing>> bySeller(String sellerId);

  Future<CarListing> create(CarListing listing);

  Future<CarListing> changeStatus(String listingId, ListingStatus status);

  /// Cierra la venta dejando constancia de quien compro. Es lo que alimenta el
  /// historial de compras y lo que habilita las calificaciones.
  Future<CarListing> markSold({
    required String listingId,
    required String buyerId,
    required String buyerName,
  });

  /// Lo que `userId` ha comprado, de lo mas reciente a lo mas antiguo.
  Future<List<CarListing>> purchasesOf(String userId);

  /// Publicaciones que `userId` sigue, y por las que recibe notificaciones.
  Future<List<CarListing>> followedBy(String userId);

  Future<Set<String>> followedIds(String userId);

  Future<bool> toggleFollow({required String listingId, required String userId});

  /// Quienes siguen la publicacion. Es a quienes hay que avisarles cuando
  /// cambia de estado o aparece una pregunta o una respuesta.
  Future<List<String>> followerIdsOf(String listingId);
}
