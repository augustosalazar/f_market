/// Lo que la feature entiende cuando el servidor dice que no.
class ChatFailure implements Exception {
  ChatFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
