import 'package:f_roble_market/features/qa/domain/models/question.dart';
import 'package:f_roble_market/features/qa/domain/repositories/i_qa_repository.dart';
import 'package:f_roble_market/core/data/dummy_data.dart';

class LocalQaRepository implements IQaRepository {
  LocalQaRepository(this._data);

  final DummyData _data;

  @override
  Future<List<Question>> forListing(String listingId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final result =
        _data.questions.where((q) => q.listingId == listingId).toList();
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
    await Future.delayed(const Duration(milliseconds: 300));
    final question = Question(
      id: _data.nextId('q'),
      listingId: listingId,
      askerId: askerId,
      askerName: askerName,
      text: text,
      createdAt: DateTime.now(),
    );
    _data.questions.add(question);
    return question;
  }

  @override
  Future<Question> answer({
    required String questionId,
    required String responderId,
    required String responderName,
    required String text,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _data.questions.indexWhere((q) => q.id == questionId);
    if (index < 0) throw StateError('No existe la pregunta $questionId');
    final updated = _data.questions[index].copyWith(
      answer: Answer(
        responderId: responderId,
        responderName: responderName,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    _data.questions[index] = updated;
    return updated;
  }
}
