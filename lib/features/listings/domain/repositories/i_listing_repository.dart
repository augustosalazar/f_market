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

  /// Publicaciones que `userId` sigue, y por las que recibe notificaciones.
  Future<List<CarListing>> followedBy(String userId);

  Future<Set<String>> followedIds(String userId);

  Future<bool> toggleFollow({required String listingId, required String userId});

  /// Quienes siguen la publicacion. Es a quienes hay que avisarles cuando
  /// cambia de estado o aparece una pregunta o una respuesta.
  Future<List<String>> followerIdsOf(String listingId);

  /// Las marcas presentes en el catalogo, para el filtro.
  Future<List<String>> brands();
}
