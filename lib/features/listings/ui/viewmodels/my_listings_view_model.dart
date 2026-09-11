import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/domain/models/chat_thread.dart';
import 'package:f_roble_market/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';
import 'package:f_roble_market/features/listings/ui/viewmodels/follows_view_model.dart';
import 'package:f_roble_market/features/notifications/domain/models/app_notification.dart';
import 'package:f_roble_market/features/notifications/domain/repositories/i_notification_repository.dart';

/// Lo mio: lo que vendo y lo que sigo. Son las dos listas que le importan al
/// usuario una vez inicia sesion.
class MyListingsViewModel extends GetxController {
  MyListingsViewModel(
    this._listings,
    this._chats,
    this._dispatcher,
    this._session,
    this._follows,
  );

  final IListingRepository _listings;
  final IChatRepository _chats;
  final INotificationDispatcher _dispatcher;
  final SessionViewModel _session;
  final FollowsViewModel _follows;

  final selling = <CarListing>[].obs;
  final following = <CarListing>[].obs;
  final loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_session.user, (_) => load());
    // La estrella se marca en el catalogo y en el detalle, nunca aqui, y esta
    // pestana vive en un `IndexedStack`: no se reconstruye al volver a ella.
    // Sin escuchar la fuente compartida, lo recien seguido no apareceria hasta
    // reiniciar la app.
    ever(_follows.ids, (_) => _loadFollowing());
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

  /// Solo la lista de seguidas, sin tocar `loading`: se dispara al marcar la
  /// estrella en otra pantalla y no debe tapar la pestana con un spinner.
  Future<void> _loadFollowing() async {
    final user = _session.user.value;
    if (user == null) {
      following.clear();
      return;
    }
    following.assignAll(await _listings.followedBy(user.userId));
  }

  /// A quien se le pudo haber vendido: quienes abrieron chat sobre ella.
  Future<List<ChatThread>> buyerCandidates(CarListing listing) async {
    final threads = await _chats.threadsOfListing(listing.id);
    return threads.where((t) => t.buyerId != listing.sellerId).toList();
  }

  /// Cierra la venta dejando constancia del comprador. Avisa igual que
  /// cualquier otro cambio de estado, porque para quien sigue lo es.
  Future<void> markSold(
    CarListing listing, {
    required String buyerId,
    required String buyerName,
  }) async {
    final updated = await _listings.markSold(
      listingId: listing.id,
      buyerId: buyerId,
      buyerName: buyerName,
    );
    _replace(updated);
    await _notifyFollowers(updated, ListingStatus.sold);
  }

  /// Cambiar el estado avisa a los seguidores (requisito 6). La misma regla
  /// esta en `ListingDetailViewModel.changeStatus`, que es la otra pantalla
  /// desde donde el dueno puede cambiarlo: si cambia una, cambia la otra.
  Future<void> changeStatus(CarListing listing, ListingStatus status) async {
    final updated = await _listings.changeStatus(listing.id, status);
    _replace(updated);
    await _notifyFollowers(updated, status);
  }

  void _replace(CarListing updated) {
    final index = selling.indexWhere((l) => l.id == updated.id);
    if (index >= 0) selling[index] = updated;
  }

  Future<void> _notifyFollowers(
    CarListing updated,
    ListingStatus status,
  ) async {
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
