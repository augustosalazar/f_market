import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';
import 'package:f_roble_market/features/profiles/domain/models/user_rating.dart';
import 'package:f_roble_market/features/profiles/domain/repositories/i_rating_repository.dart';

/// Una venta que quien mira todavia puede calificar.
class PendingRating {
  const PendingRating({required this.listing, required this.role});

  final CarListing listing;

  /// El papel de la **persona del perfil** en esa venta: si vendio, quien mira
  /// fue el comprador, y al reves.
  final RatedRole role;
}

/// El perfil publico de una persona: lo que vende, lo que vendio, lo que
/// compro y lo que opinan de ella.
///
/// Se mira sin sesion, igual que el catalogo. Lo unico que exige cuenta es
/// calificar, y solo a quien tuvo una venta con esa persona.
class UserProfileViewModel extends GetxController {
  UserProfileViewModel({
    required this.userId,
    required this.userName,
    required this.listings,
    required this.ratings,
    required this.session,
  });

  final String userId;
  final String userName;
  final IListingRepository listings;
  final IRatingRepository ratings;
  final SessionViewModel session;

  final selling = <CarListing>[].obs;
  final sold = <CarListing>[].obs;
  final bought = <CarListing>[].obs;
  final received = <UserRating>[].obs;
  final loading = true.obs;
  final saving = false.obs;
  final message = RxnString();
  final error = RxnString();

  bool get isMe => session.user.value?.userId == userId;

  /// El promedio de estrellas, o `null` si todavia no la ha calificado nadie:
  /// no es lo mismo que un cero, y pintarlo como cero seria mentir.
  double? get average {
    if (received.isEmpty) return null;
    final total = received.fold<int>(0, (sum, r) => sum + r.stars);
    return total / received.length;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      final publicadas = await listings.bySeller(userId);
      selling.assignAll(
        publicadas.where((l) => l.status != ListingStatus.sold),
      );
      sold.assignAll(publicadas.where((l) => l.status == ListingStatus.sold));
      bought.assignAll(await listings.purchasesOf(userId));
      received.assignAll(await ratings.receivedBy(userId));
    } on Object catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  /// Las ventas entre quien mira y esta persona que aun no ha calificado.
  ///
  /// Sale de lo que ya esta cargado: las ventas de esta persona en las que
  /// quien mira fue el comprador, y sus compras en las que fue el vendedor.
  List<PendingRating> get pending {
    final me = session.user.value?.userId;
    if (me == null || me == userId) return const [];
    final yaCalificadas = received
        .where((r) => r.raterId == me)
        .map((r) => r.listingId)
        .toSet();

    return [
      for (final listing in sold)
        if (listing.buyerId == me && !yaCalificadas.contains(listing.id))
          PendingRating(listing: listing, role: RatedRole.seller),
      for (final listing in bought)
        if (listing.sellerId == me && !yaCalificadas.contains(listing.id))
          PendingRating(listing: listing, role: RatedRole.buyer),
    ];
  }

  Future<void> rate({
    required PendingRating pending,
    required int stars,
    required String comment,
  }) async {
    if (!await session.ensureLoggedIn()) return;
    saving.value = true;
    try {
      await ratings.rate(
        listingId: pending.listing.id,
        raterId: session.requireUser.userId,
        raterName: session.requireUser.name,
        ratedId: userId,
        ratedRole: pending.role,
        stars: stars,
        comment: comment.trim(),
      );
      received.assignAll(await ratings.receivedBy(userId));
      message.value = 'Gracias: tu calificacion ya esta publicada.';
    } on Object catch (e) {
      error.value = e.toString();
    } finally {
      saving.value = false;
    }
  }
}
