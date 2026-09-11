/// Lo que la feature necesita que alguien sepa hablar sobre chats.
///
/// Los mensajes van aparte de la cabecera porque en Roble viven en otro sitio
/// —el arbol JSON, que es lo unico que emite tiempo real—, y la interfaz lo
/// refleja en vez de esconderlo.
abstract class IChatDataSource {
  /// Quien mira, para decidir cual de los dos interruptores del hilo es suyo.
  String? get currentUserId;

  Future<List<Map<String, dynamic>>> readThreads(Map<String, dynamic> filters);

  Future<Map<String, dynamic>?> threadById(String id);

  Future<Map<String, dynamic>> createThread(Map<String, dynamic> row);

  Future<Map<String, dynamic>> updateThread(
    String id,
    Map<String, dynamic> changes,
  );

  Future<Map<String, dynamic>?> listingById(String id);

  Future<Map<String, dynamic>> currentUser();

  /// Todo el hilo: `{clave: mensaje}`, o `null` si aun no tiene ninguno.
  Future<Object?> readMessages(String threadId);

  /// Devuelve la clave, que va ordenada por tiempo.
  Future<String> pushMessage(String threadId, Map<String, dynamic> message);

  /// Lo que llegue de ahora en adelante, ya desenvuelto: `{clave: mensaje}`.
  Stream<Map<String, dynamic>> watchMessageRecords(String threadId);
}
