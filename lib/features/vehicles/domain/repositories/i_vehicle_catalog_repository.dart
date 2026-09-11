import 'package:f_roble_market/features/vehicles/domain/models/car_brand.dart';
import 'package:f_roble_market/features/vehicles/domain/models/car_model.dart';

/// El catalogo precargado de marcas y modelos.
///
/// Es de solo lectura: lo siembra el proyecto en Roble, no la app. Se lee sin
/// sesion porque el filtro del catalogo tiene que funcionar sin haber entrado.
abstract class IVehicleCatalogRepository {
  Future<List<CarBrand>> brands();

  /// Los modelos de una marca, ya ordenados.
  Future<List<CarModel>> modelsOf(String brandId);
}
