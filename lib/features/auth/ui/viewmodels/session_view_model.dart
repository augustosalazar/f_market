import 'dart:async';

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

  /// Lo que hay que decirle a quien se quedo sin sesion sin pedirlo.
  final expired = RxnString();

  StreamSubscription<void>? _expiry;

  @override
  void onInit() {
    super.onInit();
    // Caducar y cerrar sesion dejan los dos sin sesion, pero solo uno merece
    // una explicacion: el paquete no emite aqui en `logout()`.
    _expiry = _auth.sessionExpired.listen((_) {
      if (user.value == null) return;
      user.value = null;
      expired.value = 'Tu sesion caduco. Vuelve a entrar.';
      if (Get.currentRoute != AppRoutes.login) Get.toNamed(AppRoutes.login);
    });
  }

  @override
  void onClose() {
    _expiry?.cancel();
    super.onClose();
  }

  bool get isLoggedIn => user.value != null;
  AppUser get requireUser => user.value!;

  /// Entro sin cuenta. Tiene sesion y escribe lo suyo, pero no tiene correo
  /// con el que volver: por eso la pantalla le ofrece «guarda tu cuenta» en
  /// vez de «cerrar sesion».
  bool get isGuest => user.value?.isAnonymous ?? false;

  /// Una cuenta de verdad, no un invitado. Es lo que exigen publicar, chatear
  /// y calificar.
  bool get hasAccount => isLoggedIn && !isGuest;

  /// El nombre que un invitado eligio para que lo vean los demas.
  ///
  /// Vive solo en la sesion, a proposito: el servidor no deja renombrarse
  /// —`auth` solo expone `me/extra`, que el paquete todavia no publica— y la
  /// app no guarda nada en el dispositivo. Al cerrar la app se vuelve a pedir,
  /// que es barato: lo que ya escribio quedo firmado con el nombre que dio.
  final guestName = RxnString();

  /// Con que nombre se firma lo que esta persona escribe.
  ///
  /// Un invitado se llama «Invitado» en el servidor, y ese nombre se **copia**
  /// dentro de cada pregunta al escribirla: firmar asi dejaria al vendedor sin
  /// saber a quien contesta, y registrarse despues no lo arregla hacia atras.
  String get displayName => guestName.value ?? user.value?.name ?? '';

  /// Si hay que preguntarle como quiere que lo llamen antes de que escriba.
  bool get needsDisplayName => isGuest && guestName.value == null;

  /// Devuelve si el nombre vale. Corto o vacio no sirve de firma.
  bool setGuestName(String value) {
    final limpio = value.trim();
    if (limpio.length < 3) {
      error.value = 'Escribe un nombre de al menos 3 caracteres.';
      return false;
    }
    guestName.value = limpio;
    return true;
  }

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
    guestName.value = null;
  }

  /// Garantiza una **cuenta** antes de una accion que la exige —publicar,
  /// chatear, calificar—. Si no hay, manda al login.
  ///
  /// Un invitado tambien pasa por aqui: tiene sesion, pero no la cuenta que
  /// estas acciones necesitan.
  Future<bool> ensureLoggedIn() async {
    if (hasAccount) return true;
    await Get.toNamed(AppRoutes.login);
    return hasAccount;
  }

  /// Garantiza **algo** con lo que escribir, para lo que no exige cuenta.
  ///
  /// Es lo que convierte «entra para seguir este carro» en seguirlo y ya. Si
  /// el proyecto no admite invitados, cae al login en vez de dejar el gesto
  /// sin efecto.
  Future<bool> ensureWritableSession() async {
    if (isLoggedIn) return true;
    final entro = await _run(_auth.signInAnonymously);
    if (entro) return true;
    // Solo se cae al login cuando el proyecto no admite invitados. Un limite
    // temporal o un fallo de red se cuentan y ya: mandar al login a quien solo
    // tenia que esperar convierte un tropiezo en una barrera.
    if (_lastCode != AuthFailure.guestsDisabled) return false;
    // Sin invitados no hay nada que explicar: el login es la via normal.
    error.value = null;
    return ensureLoggedIn();
  }

  /// Convierte al invitado en una cuenta conservando todo lo suyo.
  Future<bool> upgrade({
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
    return _run(() async {
      final cuenta = await _auth.upgradeAccount(
        email: email.trim(),
        password: password,
        name: name.trim(),
      );
      // Ya es el nombre de la cuenta: mantener el de invitado encima solo
      // daria dos fuentes para lo mismo.
      guestName.value = null;
      return cuenta;
    });
  }

  /// El `code` del ultimo fallo, para las pantallas que distinguen cual fue.
  String? get lastErrorCode => _lastCode;

  String? _lastCode;

  Future<bool> _fail(String message) async {
    _lastCode = null;
    error.value = message;
    return false;
  }

  Future<bool> _run(Future<AppUser> Function() action) async {
    busy.value = true;
    error.value = null;
    _lastCode = null;
    try {
      user.value = await action();
      return true;
    } on AuthFailure catch (e) {
      _lastCode = e.code;
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
