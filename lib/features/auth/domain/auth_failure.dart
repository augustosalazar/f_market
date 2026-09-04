/// Lo que el repositorio de sesion lanza cuando el servidor rechaza al usuario
/// (credenciales malas, correo ya registrado). La UI lo muestra tal cual.
class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
