/// Lo que la feature necesita que alguien sepa hablar sobre preguntas.
///
/// En filas, no en entidades: asi un solo repositorio sirve para Roble y para
/// la fuente en memoria.
abstract class IQaDataSource {
  Future<List<Map<String, dynamic>>> readForListing(String listingId);

  Future<Map<String, dynamic>> create(Map<String, dynamic> row);

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> changes);
}
