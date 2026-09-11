import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/qa/data/datasources/i_qa_data_source.dart';

class InMemoryQaDataSource implements IQaDataSource {
  InMemoryQaDataSource(this._data);

  final DummyData _data;

  static const _delay = Duration(milliseconds: 250);

  @override
  Future<List<Map<String, dynamic>>> readForListing(String listingId) async {
    await Future.delayed(_delay);
    return _data.questions.where((r) => r['listing_id'] == listingId).toList();
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> row) async {
    await Future.delayed(_delay);
    final stored = {...row, '_id': _data.nextId('q')};
    _data.questions.add(stored);
    return stored;
  }

  @override
  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> changes,
  ) async {
    await Future.delayed(_delay);
    final index = _data.questions.indexWhere((r) => r['_id'] == id);
    if (index < 0) throw StateError('No existe la pregunta $id');
    _data.questions[index] = {..._data.questions[index], ...changes};
    return _data.questions[index];
  }
}
