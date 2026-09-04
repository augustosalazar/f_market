import 'dart:async';

import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_filter.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';

/// El catalogo publico. No exige sesion; solo la usa para saber que
/// publicaciones marcar como seguidas.
class CatalogViewModel extends GetxController {
  CatalogViewModel(this._listings, this._session);

  final IListingRepository _listings;
  final SessionViewModel _session;

  final listings = <CarListing>[].obs;
  final brands = <String>[].obs;
  final followed = <String>{}.obs;
  final filter = const ListingFilter().obs;
  final loading = false.obs;

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    ever(_session.user, (_) => _loadFollowed());
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
      if (brands.isEmpty) brands.assignAll(await _listings.brands());
      await _loadFollowed();
    } finally {
      loading.value = false;
    }
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
  /// que exige sesion.
  Future<void> toggleFollow(String listingId) async {
    if (!await _session.ensureLoggedIn()) return;
    final following = await _listings.toggleFollow(
      listingId: listingId,
      userId: _session.requireUser.userId,
    );
    if (following) {
      followed.add(listingId);
    } else {
      followed.remove(listingId);
    }
  }

  Future<void> _loadFollowed() async {
    final user = _session.user.value;
    if (user == null) {
      followed.clear();
      return;
    }
    followed.assignAll(await _listings.followedIds(user.userId));
  }
}
