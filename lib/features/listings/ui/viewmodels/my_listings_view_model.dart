import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';
import 'package:f_roble_market/features/notifications/domain/models/app_notification.dart';
import 'package:f_roble_market/features/notifications/domain/repositories/i_notification_repository.dart';

/// Lo mio: lo que vendo y lo que sigo. Son las dos listas que le importan al
/// usuario una vez inicia sesion.
class MyListingsViewModel extends GetxController {
  MyListingsViewModel(this._listings, this._dispatcher, this._session);

  final IListingRepository _listings;
  final INotificationDispatcher _dispatcher;
  final SessionViewModel _session;

  final selling = <CarListing>[].obs;
  final following = <CarListing>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_session.user, (_) => load());
    load();
  }

  Future<void> load() async {
    final user = _session.user.value;
    if (user == null) {
      selling.clear();
      following.clear();
      return;
    }
    loading.value = true;
    try {
      selling.assignAll(await _listings.bySeller(user.userId));
      following.assignAll(await _listings.followedBy(user.userId));
    } finally {
      loading.value = false;
    }
  }

  /// Cambiar el estado avisa a los seguidores (requisito 6). La misma regla
  /// esta en `ListingDetailViewModel.changeStatus`, que es la otra pantalla
  /// desde donde el dueno puede cambiarlo: si cambia una, cambia la otra.
  Future<void> changeStatus(CarListing listing, ListingStatus status) async {
    final updated = await _listings.changeStatus(listing.id, status);
    final index = selling.indexWhere((l) => l.id == updated.id);
    if (index >= 0) selling[index] = updated;

    final followers = (await _listings.followerIdsOf(updated.id))
        .where((id) => id != updated.sellerId)
        .toList();
    if (followers.isEmpty) return;
    await _dispatcher.dispatch(
      userIds: followers,
      kind: NotificationKind.statusChange,
      title: updated.title,
      body: 'La publicacion ahora esta ${status.label.toLowerCase()}.',
      listingId: updated.id,
    );
  }
}
