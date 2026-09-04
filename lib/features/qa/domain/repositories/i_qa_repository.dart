import 'package:f_roble_market/features/qa/domain/models/question.dart';

/// Preguntas publicas sobre una publicacion.
abstract class IQaRepository {
  Future<List<Question>> forListing(String listingId);

  Future<Question> ask({
    required String listingId,
    required String askerId,
    required String askerName,
    required String text,
  });

  Future<Question> answer({
    required String questionId,
    required String responderId,
    required String responderName,
    required String text,
  });
}
