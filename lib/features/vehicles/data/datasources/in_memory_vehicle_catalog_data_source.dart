import 'package:f_roble_market/core/data/dummy_data.dart';
import 'package:f_roble_market/features/vehicles/data/datasources/i_vehicle_catalog_data_source.dart';

/// El catalogo de vehiculos servido desde memoria, con la misma latencia
/// simulada que el resto de la fuente local.
class InMemoryVehicleCatalogDataSource implements IVehicleCatalogDataSource {
  InMemoryVehicleCatalogDataSource(this._data);

  final DummyData _data;

  static const _delay = Duration(milliseconds: 200);

  @override
  Future<List<Map<String, dynamic>>> readBrands() async {
    await Future.delayed(_delay);
    return List.of(_data.brands);
  }

  @override
  Future<List<Map<String, dynamic>>> readModels(String brandId) async {
    await Future.delayed(_delay);
    return _data.models.where((r) => r['brand_id'] == brandId).toList();
  }
}
