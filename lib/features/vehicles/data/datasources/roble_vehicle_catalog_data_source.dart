import 'package:f_roble_market/core/roble.dart';
import 'package:f_roble_market/features/vehicles/data/datasources/i_vehicle_catalog_data_source.dart';

/// Habla con Roble sobre marcas y modelos. No decide nada.
///
/// Las dos tablas estan marcadas como publicas: el filtro rapido del catalogo
/// tiene que pintarse sin sesion, igual que las publicaciones.
class RobleVehicleCatalogDataSource implements IVehicleCatalogDataSource {
  RobleVehicleCatalogDataSource(this._client);

  final RobleClient _client;

  @override
  Future<List<Map<String, dynamic>>> readBrands() =>
      _client.readPublicOrPrivate(RobleClient.brands);

  @override
  Future<List<Map<String, dynamic>>> readModels(String brandId) =>
      _client.readPublicOrPrivate(
        RobleClient.models,
        filters: {'brand_id': brandId},
      );
}
