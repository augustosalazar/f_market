import 'package:roble/roble.dart';

/// El cliente de Roble, uno solo para toda la app.
///
/// Se crea una vez y se comparte: crear uno por pantalla le daria a cada copia
/// su propia sesion. Los repositorios lo reciben inyectado.
class RobleClient {
  RobleClient({required String baseUrl, required String contractId})
    : db = RobleApiDataBase(
        config: RobleApiConfig.fromContract(
          baseUrl: baseUrl,
          contractId: contractId,
        ),
      );

  RobleClient.withDatabase(this.db);

  final RobleApiDataBase db;

  /// El `userId` de la sesion, cacheado.
  ///
  /// El paquete guarda los tokens pero no el perfil, y `currentUser()` es un
  /// viaje al servidor. Varias lecturas dependen de quien mira —si un chat
  /// esta silenciado *para mi*, cuantos mensajes tengo *yo* sin leer—, asi que
  /// preguntarlo en cada una seria una llamada de mas cada vez. Lo escribe el
  /// repositorio de sesion al entrar, y lo borra al salir.
  String? currentUserId;

  /// Nombres de las tablas, en un solo sitio: un typo aqui es un 404 y no un
  /// error de compilacion, asi que mejor que no se repitan por ahi sueltos.
  static const listings = 'listing';
  static const questions = 'listing_question';
  static const follows = 'listing_follow';
  static const threads = 'chat_thread';

  /// El catalogo precargado de vehiculos. Lo siembra el proyecto, no la app:
  /// desde aqui solo se lee, y por eso las dos tablas son publicas.
  static const brands = 'car_brand';
  static const models = 'car_model';

  /// Las calificaciones entre las dos partes de una venta.
  static const ratings = 'user_rating';

  /// La coleccion del arbol JSON donde viven los mensajes. Los hilos cuelgan
  /// de ella: `chat_message/<threadId>/<claveDelServidor>`.
  static const messages = 'chat_message';

  /// Si quien mira es un invitado, y no una cuenta.
  ///
  /// Sale del token que ya esta en memoria, sin ir al servidor.
  bool get isGuest => db.isAnonymous;

  /// Quien no puede leer la tabla entera: sin sesion, o con sesion de
  /// invitado.
  ///
  /// **Un invitado tiene sesion iniciada pero el rol `anonymous`, que solo lee
  /// lo suyo.** Mirar solo `isLoggedIn` mandaria su catalogo por la lectura
  /// normal y le devolveria sus propias filas —o sea, ninguna— sin ningun
  /// error: la pantalla sale vacia y no hay nada que depurar.
  bool get readsPublicly => !db.isLoggedIn || db.isAnonymous;

  /// El catalogo se lee sin sesion (requisito 3), pero `publicRead` solo
  /// funciona si la tabla esta marcada como publica en la consola. Con una
  /// cuenta de verdad se usa la lectura normal, que no depende de esa marca.
  Future<List<Map<String, dynamic>>> readPublicOrPrivate(
    String table, {
    Map<String, dynamic>? filters,
  }) async {
    if (!readsPublicly) return db.read(table, filters: filters);
    final rows = await db.publicRead(table);
    if (filters == null || filters.isEmpty) return rows;
    return rows
        .where((row) => filters.entries.every((f) => row[f.key] == f.value))
        .toList();
  }
}
