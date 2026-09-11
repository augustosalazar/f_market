import 'package:roble/roble.dart';

import 'package:f_roble_market/features/qa/data/datasources/i_qa_data_source.dart';
import 'package:f_roble_market/features/qa/domain/models/question.dart';
import 'package:f_roble_market/features/qa/domain/qa_failure.dart';
import 'package:f_roble_market/features/qa/domain/repositories/i_qa_repository.dart';

/// Preguntas publicas: decide y traduce, no habla.
///
/// La respuesta va en la misma fila que la pregunta y no en otra tabla: el
/// dueno responde una sola vez, asi que una fila se lee de un viaje.
class QaRepository implements IQaRepository {
  QaRepository(this._source);

  final IQaDataSource _source;

  @override
  Future<List<Question>> forListing(String listingId) async {
    final rows = await _guard(() => _source.readForListing(listingId));
    final result = rows.map(_toQuestion).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<Question> ask({
    required String listingId,
    required String askerId,
    required String askerName,
    required String text,
  }) async {
    final row = await _guard(
      () => _source.create({
        'listing_id': listingId,
        'asker_id': askerId,
        'asker_name': askerName,
        'body': text,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    return _toQuestion(row);
  }

  @override
  Future<Question> answer({
    required String questionId,
    required String responderId,
    required String responderName,
    required String text,
  }) async {
    final row = await _guard(
      () => _source.update(questionId, {
        'answer_body': text,
        'answer_by': responderId,
        'answer_by_name': responderName,
        'answered_at': DateTime.now().toUtc().toIso8601String(),
      }),
      siNoEsta: 'Esa pregunta ya no existe.',
    );
    return _toQuestion(row);
  }

  Future<T> _guard<T>(Future<T> Function() action, {String? siNoEsta}) async {
    try {
      return await action();
    } on RobleApiHttpException catch (e) {
      if (e.statusCode == 404 && siNoEsta != null) throw QaFailure(siNoEsta);
      if (e.statusCode == 403) throw QaFailure('Tu cuenta no puede hacer esto.');
      throw QaFailure(e.message);
    } on RobleApiException catch (e) {
      throw QaFailure(e.message);
    }
  }

  Question _toQuestion(Map<String, dynamic> row) {
    final answerBody = row['answer_body'] as String?;
    return Question(
      id: row['_id'] as String,
      listingId: row['listing_id'] as String,
      askerId: row['asker_id'] as String,
      askerName: (row['asker_name'] as String?) ?? 'Sin nombre',
      text: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      answer: answerBody == null
          ? null
          : Answer(
              responderId: (row['answer_by'] as String?) ?? '',
              responderName: (row['answer_by_name'] as String?) ?? 'El vendedor',
              text: answerBody,
              createdAt: DateTime.parse(
                (row['answered_at'] as String?) ?? row['created_at'] as String,
              ).toLocal(),
            ),
    );
  }
}
