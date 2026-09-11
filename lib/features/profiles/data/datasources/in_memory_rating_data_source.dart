import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/profiles/data/datasources/i_rating_data_source.dart';

/// Las calificaciones servidas desde memoria.
class InMemoryRatingDataSource implements IRatingDataSource {
  InMemoryRatingDataSource(this._data);

  final DummyData _data;

  static const _delay = Duration(milliseconds: 200);

  @override
  Future<List<Map<String, dynamic>>> readRatings(
    Map<String, dynamic> filters,
  ) async {
    await Future.delayed(_delay);
    return _data.ratings
        .where((r) => filters.entries.every((f) => r[f.key] == f.value))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createRating(Map<String, dynamic> row) async {
    await Future.delayed(_delay);
    final stored = {...row, '_id': _data.nextId('r')};
    _data.ratings.add(stored);
    return stored;
  }
}
