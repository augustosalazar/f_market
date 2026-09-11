/// Lo que la feature necesita que alguien sepa hablar sobre calificaciones.
abstract class IRatingDataSource {
  Future<List<Map<String, dynamic>>> readRatings(Map<String, dynamic> filters);

  Future<Map<String, dynamic>> createRating(Map<String, dynamic> row);
}
