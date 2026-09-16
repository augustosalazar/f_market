/// Lo que el repositorio de sesion lanza cuando el servidor rechaza al usuario
/// (credenciales malas, correo ya registrado). La UI lo muestra tal cual.
class AuthFailure implements Exception {
  AuthFailure(this.message, {this.code});

  /// El correo del ascenso ya tiene cuenta. Roble no fusiona dos cuentas, asi
  /// que la pantalla tiene que ofrecer otra salida en vez de reintentar.
  static const emailTaken = 'ANON_UPGRADE_EMAIL_TAKEN';

  /// El proyecto no admite invitados. No es culpa de quien lo intenta.
  static const guestsDisabled = 'ANON_UNAVAILABLE';

  /// El servidor limita las sesiones de invitado por IP. Es temporal: quien
  /// espera un rato entra. Confundirlo con [guestsDisabled] manda al login a
  /// alguien que solo tenia que esperar.
  static const tooManyGuests = 'ANON_RATE_LIMITED';

  final String message;

  /// Qué falló, cuando importa distinguirlo. `null` en los fallos corrientes.
  final String? code;
  @override
  String toString() => message;
}
