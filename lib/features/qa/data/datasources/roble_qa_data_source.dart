import 'package:f_roble_market/core/roble.dart';
import 'package:f_roble_market/features/qa/data/datasources/i_qa_data_source.dart';


/// Habla con Roble sobre preguntas publicas. No decide nada.
class RobleQaDataSource implements IQaDataSource {
  RobleQaDataSource(this._client);

  final RobleClient _client;

  static const questions = RobleClient.questions;

  /// El detalle se ve sin sesion, asi que la lectura pasa por `publicRead`
  /// cuando no la hay.
  @override
  Future<List<Map<String, dynamic>>> readForListing(String listingId) =>
      _client.readPublicOrPrivate(questions, filters: {'listing_id': listingId});

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> row) =>
      _client.db.create(questions, row);

  @override
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> changes) =>
      _client.db.update(questions, id, changes);
}
