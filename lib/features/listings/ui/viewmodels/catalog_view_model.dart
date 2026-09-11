import 'dart:async';

import 'package:get/get.dart';

import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/follows_view_model.dart';
import 'package:f_roble_market/features/vehicles/domain/models/car_brand.dart';
import 'package:f_roble_market/features/vehicles/domain/repositories/i_vehicle_catalog_repository.dart';

/// El catalogo publico. No exige sesion; solo la usa para saber que
/// publicaciones marcar como seguidas.
class CatalogViewModel extends GetxController {
  CatalogViewModel(this._listings, this._vehicles, this._follows);

  final IListingRepository _listings;
  final IVehicleCatalogRepository _vehicles;
  final FollowsViewModel _follows;

  final listings = <CarListing>[].obs;

  /// Las marcas salen del catalogo precargado, no de lo que haya publicado.
  /// Derivarlas de las publicaciones hacia que la tira cambiara sola segun lo
  /// que hubiera en venta, y que una marca sin stock no se pudiera ni elegir.
  final brands = <CarBrand>[].obs;
  final filter = const ListingFilter().obs;
  final loading = false.obs;

  /// Lo seguido no es suyo: lo lee de la fuente compartida, para que marcar la
  /// estrella aqui se vea tambien en «Lo mio -> Siguiendo».
  RxSet<String> get followed => _follows.ids;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      listings.assignAll(await _listings.search(filter.value));
      // El catalogo de marcas no cambia entre busquedas: se pide una vez.
      if (brands.isEmpty) brands.assignAll(await _vehicles.brands());
    } finally {
      loading.value = false;
    }
  }

  /// La marca elegida en la tira horizontal. `null` es «Todas».
  String? get selectedBrand => filter.value.brand;

  void selectBrand(String? brand) {
    if (filter.value.brand == brand) return;
    filter.value = brand == null
        ? filter.value.copyWith(clearBrand: true)
        : filter.value.copyWith(brand: brand);
    load();
  }

  /// La busqueda se retrasa: escribir no dispara una consulta por tecla.
  void onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      filter.value = filter.value.copyWith(query: value);
      load();
    });
  }

  void applyFilter(ListingFilter next) {
    filter.value = next;
    load();
  }

  void clearFilter() {
    filter.value = const ListingFilter();
    load();
  }

  /// Seguir una publicacion es lo que suscribe al comprador a sus avisos, asi
  /// que exige sesion. De eso se encarga [FollowsViewModel].
  Future<void> toggleFollow(String listingId) async {
    await _follows.toggle(listingId);
  }
}
