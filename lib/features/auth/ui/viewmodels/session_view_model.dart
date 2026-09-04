import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/domain/auth_failure.dart';
import 'package:f_roble_market/features/auth/domain/models/app_user.dart';
import 'package:f_roble_market/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// Quien esta dentro. Vive toda la vida de la app: el catalogo es publico, asi
/// que la sesion es un dato transversal y no el dueno de una pantalla.
///
/// Valida las credenciales antes de llamar al repositorio: lo que no cumple
/// las reglas ni siquiera sale de la app.
class SessionViewModel extends GetxController {
  SessionViewModel(this._auth);

  final IAuthRepository _auth;

  static final _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final user = Rxn<AppUser>();
  final busy = false.obs;
  final error = RxnString();

  bool get isLoggedIn => user.value != null;
  AppUser get requireUser => user.value!;

  Future<void> restore() async {
    user.value = await _auth.restoreSession();
  }

  Future<bool> login({required String email, required String password}) {
    if (!_emailRe.hasMatch(email.trim())) {
      return _fail('Ese correo no parece valido.');
    }
    if (password.isEmpty) return _fail('Escribe tu contrasena.');
    return _run(
      () => _auth.loginWithEmail(email: email.trim(), password: password),
    );
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) {
    if (name.trim().length < 3) {
      return _fail('Tu nombre debe tener al menos 3 caracteres.');
    }
    if (!_emailRe.hasMatch(email.trim())) {
      return _fail('Ese correo no parece valido.');
    }
    if (password.length < 6) {
      return _fail('La contrasena debe tener al menos 6 caracteres.');
    }
    if (password != confirmation) {
      return _fail('Las contrasenas no coinciden.');
    }
    return _run(
      () => _auth.registerWithEmail(
        name: name.trim(),
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<bool> signInWithGoogle() => _run(_auth.signInWithGoogle);

  Future<void> logout() async {
    await _auth.logout();
    user.value = null;
  }

  /// Garantiza sesion antes de una accion que la exige. Si no hay, manda al
  /// login y devuelve si el usuario termino entrando.
  Future<bool> ensureLoggedIn() async {
    if (isLoggedIn) return true;
    await Get.toNamed(AppRoutes.login);
    return isLoggedIn;
  }

  Future<bool> _fail(String message) async {
    error.value = message;
    return false;
  }

  Future<bool> _run(Future<AppUser> Function() action) async {
    busy.value = true;
    error.value = null;
    try {
      user.value = await action();
      return true;
    } on AuthFailure catch (e) {
      error.value = e.message;
      return false;
    } catch (_) {
      error.value = 'No se pudo completar la operacion. Intenta de nuevo.';
      return false;
    } finally {
      busy.value = false;
    }
  }
}
