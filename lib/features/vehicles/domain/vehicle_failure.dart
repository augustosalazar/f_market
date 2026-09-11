/// Lo que sale mal al leer el catalogo de marcas y modelos.
class VehicleFailure implements Exception {
  const VehicleFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
