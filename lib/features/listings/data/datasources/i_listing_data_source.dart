/// Lo que la feature necesita que alguien sepa hablar sobre publicaciones.
///
/// Habla en **filas** —lo mismo que viaja por la API— y no en entidades: eso
/// deja que un solo repositorio sirva para Roble y para la fuente en memoria,
/// en vez de un repositorio por cada una repitiendo la misma logica.
///
/// Ninguna implementacion decide nada, y ninguna sabe que la otra existe.
abstract class IListingDataSource {
  Future<List<Map<String, dynamic>>> readListings({
    Map<String, dynamic>? filters,
  });

  Future<Map<String, dynamic>?> listingById(String id);

  Future<Map<String, dynamic>> createListing(Map<String, dynamic> row);

  Future<Map<String, dynamic>> updateListing(
    String id,
    Map<String, dynamic> changes,
  );

  Future<List<Map<String, dynamic>>> readFollows(Map<String, dynamic> filters);

  Future<Map<String, dynamic>> createFollow(Map<String, dynamic> row);

  Future<void> deleteFollow(String id);
}
