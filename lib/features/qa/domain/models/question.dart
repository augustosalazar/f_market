/// Una pregunta publica sobre una publicacion, con la respuesta del vendedor.
///
/// La respuesta vive dentro de la pregunta porque el dueno responde una sola
/// vez y en publico; las conversaciones de ida y vuelta van por chat privado.
class Question {
  const Question({
    required this.id,
    required this.listingId,
    required this.askerId,
    required this.askerName,
    required this.text,
    required this.createdAt,
    this.answer,
  });

  final String id;
  final String listingId;
  final String askerId;
  final String askerName;
  final String text;
  final DateTime createdAt;
  final Answer? answer;

  bool get isAnswered => answer != null;

  Question copyWith({Answer? answer}) => Question(
    id: id,
    listingId: listingId,
    askerId: askerId,
    askerName: askerName,
    text: text,
    createdAt: createdAt,
    answer: answer ?? this.answer,
  );
}

class Answer {
  const Answer({
    required this.responderId,
    required this.responderName,
    required this.text,
    required this.createdAt,
  });

  final String responderId;
  final String responderName;
  final String text;
  final DateTime createdAt;
}
