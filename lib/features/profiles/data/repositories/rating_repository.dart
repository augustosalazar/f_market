import 'package:roble/roble.dart';

import 'package:f_roble_market/features/profiles/data/datasources/i_rating_data_source.dart';
import 'package:f_roble_market/features/profiles/domain/models/user_rating.dart';
import 'package:f_roble_market/features/profiles/domain/profile_failure.dart';
import 'package:f_roble_market/features/profiles/domain/repositories/i_rating_repository.dart';

/// Las calificaciones: decide y traduce, no habla.
///
/// Lo que decide: que no haya dos de la misma persona por la misma venta, y
/// que las estrellas esten dentro de rango. Lo primero **no** lo garantiza el
/// servidor —no hay unicidad por par de columnas—, asi que se comprueba antes
/// de escribir; dos toques a la vez desde el mismo telefono no la saltan
/// porque el boton se bloquea mientras se guarda.
class RatingRepository implements IRatingRepository {
  RatingRepository(this._source);

  final IRatingDataSource _source;

  @override
  Future<List<UserRating>> receivedBy(String userId) async {
    final rows = await _guard(() => _source.readRatings({'rated_id': userId}));
    final result = rows.map(_toRating).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<UserRating> rate({
    required String listingId,
    required String raterId,
    required String raterName,
    required String ratedId,
    required RatedRole ratedRole,
    required int stars,
    required String comment,
  }) async {
    if (stars < UserRating.minStars || stars > UserRating.maxStars) {
      throw const ProfileFailure(
        'La calificacion va de 1 a 5 estrellas.',
      );
    }
    if (raterId == ratedId) {
      throw const ProfileFailure('No puedes calificarte a ti mismo.');
    }

    final existing = await _guard(
      () => _source.readRatings({'listing_id': listingId, 'rater_id': raterId}),
    );
    if (existing.isNotEmpty) {
      throw const ProfileFailure('Ya calificaste esta venta.');
    }

    final row = await _guard(
      () => _source.createRating({
        'listing_id': listingId,
        'rater_id': raterId,
        'rater_name': raterName,
        'rated_id': ratedId,
        'rated_role': ratedRole.name,
        'stars': stars,
        'comment': comment,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return _toRating(row);
  }

  UserRating _toRating(Map<String, dynamic> row) => UserRating(
    id: '${row['_id']}',
    listingId: '${row['listing_id']}',
    raterId: '${row['rater_id']}',
    raterName: (row['rater_name'] as String?) ?? 'Alguien',
    ratedId: '${row['rated_id']}',
    ratedRole: RatedRole.fromName('${row['rated_role']}'),
    stars: (row['stars'] as num?)?.toInt() ?? 0,
    comment: (row['comment'] as String?) ?? '',
    createdAt: DateTime.parse('${row['created_at']}').toLocal(),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 403) {
        throw const ProfileFailure('Tu cuenta no puede hacer esto.');
      }
      throw ProfileFailure(e.message);
    } on RobleApiException catch (e) {
      throw ProfileFailure(e.message);
    }
  }
}
