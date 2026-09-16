import 'package:f_roble_market/core/roble.dart';
import 'package:f_roble_market/features/listings/data/datasources/i_listing_data_source.dart';


/// Habla con Roble sobre publicaciones y seguimientos. No decide nada.
///
/// Entra y sale con las filas tal como viajan —`Map<String, dynamic>`— y deja
/// **subir las excepciones del paquete tal cual**: traducirlas es del
/// repositorio, que es quien sabe que significa cada fallo para la feature.
class RobleListingDataSource implements IListingDataSource {
  RobleListingDataSource(this._client);

  final RobleClient _client;

  static const listings = RobleClient.listings;
  static const follows = RobleClient.follows;

  /// El catalogo. Sin sesion pasa por `publicRead`, que exige que la tabla
  /// este marcada como publica; con sesion, por la lectura normal.
  @override
  Future<List<Map<String, dynamic>>> readListings({
    Map<String, dynamic>? filters,
  }) => _client.readPublicOrPrivate(listings, filters: filters);

  @override
  Future<Map<String, dynamic>?> listingById(String id) async {
    if (!_client.readsPublicly) return _client.db.getById(listings, id);
    // Sin sesion —o como invitado, que solo ve lo suyo— no hay `getById`: el
    // detalle tambien tiene que verse.
    final rows = await _client.db.publicRead(listings);
    for (final row in rows) {
      if (row['_id'] == id) return row;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> createListing(Map<String, dynamic> row) =>
      _client.db.create(listings, row);

  @override
  Future<Map<String, dynamic>> updateListing(
    String id,
    Map<String, dynamic> changes,
  ) => _client.db.update(listings, id, changes);

  /// Seguir es cosa de quien tiene sesion, asi que no pasa por `publicRead`:
  /// `listing_follow` no necesita ser una tabla publica.
  @override
  Future<List<Map<String, dynamic>>> readFollows(
    Map<String, dynamic> filters,
  ) => _client.db.read(follows, filters: filters);

  @override
  Future<Map<String, dynamic>> createFollow(Map<String, dynamic> row) =>
      _client.db.create(follows, row);

  @override
  Future<void> deleteFollow(String id) => _client.db.delete(follows, id);
}
