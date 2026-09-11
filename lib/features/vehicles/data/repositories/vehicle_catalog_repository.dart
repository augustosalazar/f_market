import 'package:roble/roble.dart';

import 'package:f_roble_market/features/vehicles/data/datasources/i_vehicle_catalog_data_source.dart';
import 'package:f_roble_market/features/vehicles/domain/models/car_brand.dart';
import 'package:f_roble_market/features/vehicles/domain/models/car_model.dart';
import 'package:f_roble_market/features/vehicles/domain/repositories/i_vehicle_catalog_repository.dart';
import 'package:f_roble_market/features/vehicles/domain/vehicle_failure.dart';

/// El catalogo de vehiculos: decide y traduce, no habla.
///
/// Lo que decide: que las filas inactivas no se muestran —dar de baja una
/// marca no puede romper las publicaciones que ya la usan— y que el orden lo
/// manda `sort_order`, con el nombre para desempatar.
class VehicleCatalogRepository implements IVehicleCatalogRepository {
  VehicleCatalogRepository(this._source);

  final IVehicleCatalogDataSource _source;

  @override
  Future<List<CarBrand>> brands() async {
    final rows = await _guard(_source.readBrands);
    final brands = rows
        .where(_isActive)
        .map(
          (r) => CarBrand(
            id: '${r['_id']}',
            name: '${r['name']}',
            sortOrder: _int(r['sort_order']),
          ),
        )
        .toList();
    brands.sort(_by((b) => b.sortOrder, (b) => b.name));
    return brands;
  }

  @override
  Future<List<CarModel>> modelsOf(String brandId) async {
    final rows = await _guard(() => _source.readModels(brandId));
    final models = rows
        .where(_isActive)
        .map(
          (r) => CarModel(
            id: '${r['_id']}',
            brandId: '${r['brand_id']}',
            name: '${r['name']}',
            sortOrder: _int(r['sort_order']),
          ),
        )
        .toList();
    models.sort(_by((m) => m.sortOrder, (m) => m.name));
    return models;
  }

  /// `active` nulo cuenta como activo: una fila sembrada sin la bandera no
  /// deberia desaparecer del formulario.
  static bool _isActive(Map<String, dynamic> row) => row['active'] != false;

  static int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static int Function(T, T) _by<T>(
    int Function(T) order,
    String Function(T) name,
  ) => (a, b) {
    final byOrder = order(a).compareTo(order(b));
    return byOrder != 0 ? byOrder : name(a).compareTo(name(b));
  };

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on RobleApiException catch (e) {
      throw VehicleFailure(e.message);
    }
  }
}
