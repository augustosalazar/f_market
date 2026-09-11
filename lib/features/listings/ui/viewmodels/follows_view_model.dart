import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';

/// Quien sigue que, en un solo sitio.
///
/// La estrella se toca desde el catalogo y desde el detalle, pero quien la
/// muestra tambien es «Lo mio -> Siguiendo». Esa pestana vive dentro del
/// `IndexedStack` de la carcasa, asi que no se reconstruye al volver a ella:
/// si cada pantalla guardara su propia copia de lo seguido, la lista se
/// quedaria con la que cargo al arrancar y lo recien marcado no apareceria
/// hasta reiniciar la app.
///
/// Por eso el conjunto es uno solo y es observable: las pantallas leen de aqui
/// y reaccionan a sus cambios, vengan de donde vengan.
class FollowsViewModel extends GetxController {
  FollowsViewModel(this._listings, this._session);

  final IListingRepository _listings;
  final SessionViewModel _session;

  /// Los ids de las publicaciones que sigue quien esta dentro.
  final ids = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    ever(_session.user, (_) => load());
    load();
  }

  bool isFollowing(String listingId) => ids.contains(listingId);

  Future<void> load() async {
    final user = _session.user.value;
    if (user == null) {
      ids.clear();
      return;
    }
    ids.assignAll(await _listings.followedIds(user.userId));
  }

  /// Seguir es lo que suscribe al comprador a los avisos, asi que exige
  /// sesion. Devuelve si quedo siguiendo, o `null` si no llego a haberla:
  /// quien llama distingue asi «no sigue» de «no entro».
  Future<bool?> toggle(String listingId) async {
    if (!await _session.ensureLoggedIn()) return null;
    final following = await _listings.toggleFollow(
      listingId: listingId,
      userId: _session.requireUser.userId,
    );
    if (following) {
      ids.add(listingId);
    } else {
      ids.remove(listingId);
    }
    return following;
  }
}
