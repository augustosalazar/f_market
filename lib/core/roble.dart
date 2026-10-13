import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:roble/roble.dart';

import 'package:f_roble_market/core/roble_config.dart';

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
        // Solo lo usa la ventana de web: en movil el selector nativo de
        // Google vuelve solo, sin destino de retorno que registrar. Es el
        // nombre de un destino de la consola, no una URL.
        ssoRedirect: RobleConfig.ssoRedirect,
        googleIosClientId: RobleConfig.googleIosClientId.isEmpty
            ? null
            : RobleConfig.googleIosClientId,
      );

  RobleClient.withDatabase(this.db);

  /// Enlaza Google con la cuenta que **ya tiene sesion**.
  ///
  /// Es lo que asciende a un invitado sin moverle un dato: el servidor une la
  /// identidad al usuario que ya existe, le quita la marca de invitado y le da
  /// el rol normal, todo con el mismo `userId`. Entrar con Google a secas no
  /// sirve para esto: eso resolveria otra identidad y dejaria atras lo suyo.
  ///
  /// A diferencia de entrar, esto **siempre pasa por el navegador**, tambien
  /// en movil: el selector nativo devuelve un `id_token` para iniciar sesion,
  /// y el enlace no tiene esa puerta.
  Future<void> linkGoogle({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final inicio = await db.linkIdentity(
      provider: 'google',
      redirect: kIsWeb
          ? RobleConfig.webLinkRedirect
          : RobleConfig.mobileSsoRedirect,
    );

    final retorno = Uri.parse(
      await FlutterWebAuth2.authenticate(
        url: inicio['url']!,
        // En web el plugin lo ignora —alli el retorno lo recoge
        // `auth.html`—, asi que vale el mismo valor en las dos plataformas.
        callbackUrlScheme: RobleConfig.mobileCallbackScheme,
      ).timeout(timeout),
    );

    final error = retorno.queryParameters['error'];
    if (error != null) {
      throw RobleApiAuthException(
        retorno.queryParameters['error_description'] ?? error,
      );
    }

    final codigo = retorno.queryParameters['code'];
    if (codigo == null || codigo.isEmpty) {
      throw const RobleApiAuthException(
        'Google volvio sin codigo: el enlace no se completo.',
      );
    }

    // El servidor emite sesion nueva para el mismo usuario, ya sin la marca de
    // invitado. Sin canjearla, el token en memoria seguiria diciendo que es un
    // invitado y la pantalla seguiria ofreciendo «guarda tu cuenta».
    await db.exchangeSocialCode(codigo);
  }

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

  /// La consulta guardada que filtra el catalogo en el servidor.
  ///
  /// **Corre sin el alcance `own` y sin mirar si la tabla es publica**: ve
  /// todas las filas, y sus parametros los pone el cliente. Por eso solo lee
  /// `listing`, que ya es publica. Nunca una consulta que filtre por «mi»
  /// usuario: cualquiera podria pasar el id de otro.
  static const searchListingsQuery = 'market_search_listings';

  /// La consulta guardada que trae varias publicaciones por su `_id` de una
  /// vez (`$1` es un `uuid[]`). Misma advertencia: solo lee `listing`.
  static const listingsByIdsQuery = 'market_listings_by_ids';

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
  ///
  /// Los filtros viajan en los dos caminos: `public-read` tambien filtra por
  /// igualdad en el servidor. Antes se bajaba la tabla entera y se filtraba
  /// aqui.
  Future<List<Map<String, dynamic>>> readPublicOrPrivate(
    String table, {
    Map<String, dynamic>? filters,
  }) => readsPublicly
      ? db.publicRead(table, filters: filters)
      : db.read(table, filters: filters);
}
