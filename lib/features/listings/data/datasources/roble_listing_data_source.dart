import 'package:roble/roble.dart';

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

  /// Con cuenta, el filtro entero se resuelve en Postgres con una consulta
  /// guardada: un viaje y solo las filas que cumplen.
  ///
  /// Sin sesion —o como invitado— no se puede: ejecutar una consulta pide
  /// sesion y el permiso `execute`, que el rol `anonymous` no trae. Ahi va por
  /// `publicRead`, que al menos filtra la marca en el servidor.
  @override
  Future<List<Map<String, dynamic>>> searchListings({
    required String text,
    String? brand,
    double? minPrice,
    double? maxPrice,
    int? minYear,
  }) async {
    if (_client.readsPublicly) {
      return _client.db.publicRead(
        listings,
        filters: brand == null ? null : {'brand': brand},
      );
    }
    final result = await _client.db.executeQueryByName(
      RobleClient.searchListingsQuery,
      // El orden es el de `$1..$5` en el SQL guardado.
      params: [text, brand, minPrice, maxPrice, minYear],
    );
    return _rowsOf(result);
  }

  @override
  Future<Map<String, dynamic>?> listingById(String id) async {
    if (!_client.readsPublicly) return _client.db.getById(listings, id);
    // Sin sesion —o como invitado, que solo ve lo suyo— no hay `getById`: el
    // detalle tambien tiene que verse, y `public-read` filtra por `_id` en el
    // servidor.
    final rows = await _client.db.publicRead(listings, filters: {'_id': id});
    return rows.firstOrNull;
  }

  /// Con cuenta, un viaje con la consulta guardada.
  ///
  /// Un invitado tambien sigue publicaciones pero no puede ejecutar consultas,
  /// asi que pide cada una por `public-read` filtrando por `_id`, en paralelo.
  /// Son pocas, y siempre sale mejor que bajar el catalogo entero.
  @override
  Future<List<Map<String, dynamic>>> listingsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    if (_client.readsPublicly) {
      final rows = await Future.wait(ids.map(listingById));
      return rows.nonNulls.toList();
    }
    final result = await _client.db.executeQueryByName(
      RobleClient.listingsByIdsQuery,
      params: [ids],
    );
    return _rowsOf(result);
  }

  static List<Map<String, dynamic>> _rowsOf(RobleQueryResult result) => [
    for (final row in result.rows)
      if (row is Map) Map<String, dynamic>.from(row),
  ];

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
