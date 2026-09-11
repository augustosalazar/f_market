/// Lo que la feature entiende cuando el servidor dice que no.
///
/// El `domain/` no debe saber que existe HTTP, asi que las excepciones del
/// paquete mueren en el repositorio y salen de aqui convertidas en esto.
class ListingFailure implements Exception {
  ListingFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
