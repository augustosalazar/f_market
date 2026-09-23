import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/listings/data/datasources/i_listing_data_source.dart';

/// Las mismas filas, servidas desde memoria.
///
/// Simula la latencia para que los estados de carga de la UI se puedan ver de
/// verdad, y respeta las mismas reglas que el servidor en lo que la app nota:
/// el `_id` lo pone la fuente, no quien escribe.
class InMemoryListingDataSource implements IListingDataSource {
  InMemoryListingDataSource(this._data);

  final DummyData _data;

  static const _delay = Duration(milliseconds: 300);

  bool _matches(Map<String, dynamic> row, Map<String, dynamic>? filters) =>
      filters == null ||
      filters.entries.every((f) => row[f.key] == f.value);

  @override
  Future<List<Map<String, dynamic>>> readListings({
    Map<String, dynamic>? filters,
  }) async {
    await Future.delayed(_delay);
    return _data.listings.where((r) => _matches(r, filters)).toList();
  }

  /// Solo la marca: el resto lo filtra el repositorio, y repetirlo aqui seria
  /// probar una copia de la regla en vez de la regla.
  @override
  Future<List<Map<String, dynamic>>> searchListings({
    required String text,
    String? brand,
    double? minPrice,
    double? maxPrice,
    int? minYear,
  }) => readListings(filters: brand == null ? null : {'brand': brand});

  @override
  Future<Map<String, dynamic>?> listingById(String id) async {
    await Future.delayed(_delay);
    return _data.listings.where((r) => r['_id'] == id).firstOrNull;
  }

  @override
  Future<List<Map<String, dynamic>>> listingsByIds(List<String> ids) async {
    await Future.delayed(_delay);
    return _data.listings.where((r) => ids.contains(r['_id'])).toList();
  }

  @override
  Future<Map<String, dynamic>> createListing(Map<String, dynamic> row) async {
    await Future.delayed(_delay);
    final stored = {...row, '_id': _data.nextId('l')};
    _data.listings.insert(0, stored);
    return stored;
  }

  @override
  Future<Map<String, dynamic>> updateListing(
    String id,
    Map<String, dynamic> changes,
  ) async {
    await Future.delayed(_delay);
    final index = _data.listings.indexWhere((r) => r['_id'] == id);
    if (index < 0) throw StateError('No existe la publicacion $id');
    _data.listings[index] = {..._data.listings[index], ...changes};
    return _data.listings[index];
  }

  @override
  Future<List<Map<String, dynamic>>> readFollows(
    Map<String, dynamic> filters,
  ) async {
    await Future.delayed(_delay);
    return _data.follows.where((r) => _matches(r, filters)).toList();
  }

  @override
  Future<Map<String, dynamic>> createFollow(Map<String, dynamic> row) async {
    final stored = {...row, '_id': _data.nextId('f')};
    _data.follows.add(stored);
    return stored;
  }

  @override
  Future<void> deleteFollow(String id) async {
    _data.follows.removeWhere((r) => r['_id'] == id);
  }
}
