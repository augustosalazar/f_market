/// Lo que la feature necesita que alguien sepa hablar sobre el catalogo de
/// vehiculos. Habla en filas, como los demas datasources.
abstract class IVehicleCatalogDataSource {
  Future<List<Map<String, dynamic>>> readBrands();

  Future<List<Map<String, dynamic>>> readModels(String brandId);
}
