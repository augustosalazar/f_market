/// Lo que la feature entiende cuando el servidor dice que no.
class QaFailure implements Exception {
  QaFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
