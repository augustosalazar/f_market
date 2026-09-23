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

  /// Las publicaciones que **pueden** cumplir el filtro.
  ///
  /// Devuelve al menos todas las que lo cumplen, y quiza mas: donde la fuente
  /// no sabe filtrar, devuelve de mas. El repositorio vuelve a filtrar y
  /// ordena, asi que la regla del filtro vive en un solo sitio.
  Future<List<Map<String, dynamic>>> searchListings({
    required String text,
    String? brand,
    double? minPrice,
    double? maxPrice,
    int? minYear,
  });

  Future<Map<String, dynamic>?> listingById(String id);

  /// Las publicaciones con esos `_id`, en cualquier orden. Las que no existan
  /// simplemente no vienen.
  Future<List<Map<String, dynamic>>> listingsByIds(List<String> ids);

  Future<Map<String, dynamic>> createListing(Map<String, dynamic> row);

  Future<Map<String, dynamic>> updateListing(
    String id,
    Map<String, dynamic> changes,
  );

  Future<List<Map<String, dynamic>>> readFollows(Map<String, dynamic> filters);

  Future<Map<String, dynamic>> createFollow(Map<String, dynamic> row);

  Future<void> deleteFollow(String id);
}
