import 'package:f_roble_market/core/roble.dart';
import 'package:f_roble_market/features/profiles/data/datasources/i_rating_data_source.dart';

/// Habla con Roble sobre calificaciones. No decide nada.
///
/// La tabla es publica: un perfil con su reputacion se tiene que poder mirar
/// antes de crear cuenta, igual que el catalogo.
class RobleRatingDataSource implements IRatingDataSource {
  RobleRatingDataSource(this._client);

  final RobleClient _client;

  @override
  Future<List<Map<String, dynamic>>> readRatings(
    Map<String, dynamic> filters,
  ) => _client.readPublicOrPrivate(RobleClient.ratings, filters: filters);

  @override
  Future<Map<String, dynamic>> createRating(Map<String, dynamic> row) =>
      _client.db.create(RobleClient.ratings, row);
}
