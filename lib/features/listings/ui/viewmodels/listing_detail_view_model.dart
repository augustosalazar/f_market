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
import 'package:f_roble_market/features/qa/domain/models/question.dart';
import 'package:f_roble_market/features/qa/domain/repositories/i_qa_repository.dart';
import 'package:f_roble_market/routes/app_routes.dart';

/// La pantalla de detalle: ficha, preguntas publicas, seguir y chat privado.
///
/// Aqui viven las reglas de los requisitos 5, 6 y 7: quien puede preguntar,
/// quien puede responder, y a quien se le avisa de cada cosa.
class ListingDetailViewModel extends GetxController {
  ListingDetailViewModel({
    required this.listingId,
    required this.listings,
    required this.qa,
    required this.chats,
    required this.dispatcher,
    required this.follows,
    required this.session,
  });

  final String listingId;
  final IListingRepository listings;
  final IQaRepository qa;
  final IChatRepository chats;
  final INotificationDispatcher dispatcher;
  final FollowsViewModel follows;
  final SessionViewModel session;

  final listing = Rxn<CarListing>();
  final questions = <Question>[].obs;
  final loading = true.obs;
  final sending = false.obs;
  final photoIndex = 0.obs;

  /// Lo que la pantalla debe mostrarle al usuario. La vista escucha y lo pinta;
  /// el view model no toca widgets, asi se puede probar sin Flutter.
  final message = RxnString();
  final error = RxnString();

  /// Se lee de la fuente compartida, no de una copia: asi la estrella de esta
  /// pantalla y la lista de «Lo mio -> Siguiendo» no pueden discrepar.
  bool get isFollowing => follows.isFollowing(listingId);

  bool get isOwner =>
      session.isLoggedIn && listing.value?.sellerId == session.requireUser.userId;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    loading.value = true;
    try {
      listing.value = await listings.byId(listingId);
      questions.assignAll(await qa.forListing(listingId));
    } finally {
      loading.value = false;
    }
  }

  Future<void> toggleFollow() async {
    final following = await follows.toggle(listingId);
    // `null` es que no llego a haber sesion: no hay nada que contar.
    if (following == null) return;
    message.value = following
        ? 'Sigues esta publicacion: te avisaremos de preguntas, respuestas y cambios de estado.'
        : 'Dejaste de seguir esta publicacion.';
  }

  /// Pregunta publica. Avisa al vendedor (requisito 7) y a los seguidores de
  /// la publicacion (requisito 6), nunca a quien pregunta.
  /// Preguntar **no exige cuenta**: es la pregunta de quien esta mirando, y
  /// mandarlo al registro es donde se pierde. Basta una sesion de invitado,
  /// que es lo que hace que la pregunta tenga a quien avisar de la respuesta.
  Future<void> ask(String text) async {
    if (!await session.ensureWritableSession()) return;
    final current = listing.value;
    final body = text.trim();
    if (current == null) return;
    if (body.isEmpty) {
      error.value = 'Escribe tu pregunta.';
      return;
    }
    final asker = session.requireUser;
    if (asker.userId == current.sellerId) {
      error.value = 'No puedes preguntar en tu propia publicacion.';
      return;
    }
    // El nombre que se copia en la fila es el elegido, no «Invitado».
    final firma = session.displayName;

    await _guard(() async {
      await qa.ask(
        listingId: current.id,
        askerId: asker.userId,
        askerName: firma,
        text: body,
      );
      await _notify(
        listing: current,
        kind: NotificationKind.question,
        body: '$firma pregunto: $body',
        exclude: {asker.userId},
        includeSeller: true,
      );
      questions.assignAll(await qa.forListing(listingId));
      message.value = 'Pregunta publicada.';
    });
  }

  /// Respuesta publica del dueno. Avisa a quien pregunto y a los seguidores.
  Future<void> answer(Question question, String text) async {
    final current = listing.value;
    final body = text.trim();
    if (current == null) return;
    if (body.isEmpty) {
      error.value = 'Escribe la respuesta.';
      return;
    }
    final responder = session.user.value;
    if (responder == null || responder.userId != current.sellerId) {
      error.value = 'Solo el dueno de la publicacion puede responder.';
      return;
    }

    await _guard(() async {
      await qa.answer(
        questionId: question.id,
        responderId: responder.userId,
        responderName: responder.name,
        text: body,
      );
      await _notify(
        listing: current,
        kind: NotificationKind.answer,
        body: '${responder.name} respondio: $body',
        exclude: {responder.userId},
        includeSeller: false,
        extra: {question.askerId},
      );
      questions.assignAll(await qa.forListing(listingId));
      message.value = 'Respuesta publicada.';
    });
  }

  /// Cambia el estado y avisa a quienes siguen la publicacion (requisito 6).
  /// A quien se le pudo haber vendido: quienes abrieron chat sobre ella.
  Future<List<ChatThread>> buyerCandidates() async {
    final threads = await chats.threadsOfListing(listingId);
    final sellerId = listing.value?.sellerId;
    return threads.where((t) => t.buyerId != sellerId).toList();
  }

  /// Cierra la venta con comprador. La misma regla esta en
  /// `MyListingsViewModel.markSold`: si cambia una, cambia la otra.
  Future<void> markSold({
    required String buyerId,
    required String buyerName,
  }) async {
    final current = listing.value;
    if (current == null) return;
    await _guard(() async {
      final updated = await listings.markSold(
        listingId: current.id,
        buyerId: buyerId,
        buyerName: buyerName,
      );
      listing.value = updated;
      await _notify(
        listing: updated,
        kind: NotificationKind.statusChange,
        body: 'La publicacion ahora esta vendida.',
        exclude: {updated.sellerId},
        includeSeller: false,
      );
      message.value = 'Venta registrada con $buyerName.';
    });
  }

  Future<void> changeStatus(ListingStatus status) async {
    final current = listing.value;
    if (current == null) return;
    await _guard(() async {
      final updated = await listings.changeStatus(current.id, status);
      listing.value = updated;
      await _notify(
        listing: updated,
        kind: NotificationKind.statusChange,
        body: 'La publicacion ahora esta ${status.label.toLowerCase()}.',
        exclude: {updated.sellerId},
        includeSeller: false,
      );
      message.value = 'Estado actualizado a ${status.label.toLowerCase()}.';
    });
  }

  /// Abre (o reabre) el chat privado con el vendedor.
  Future<void> openPrivateChat() async {
    if (!await session.ensureLoggedIn()) return;
    final thread = await chats.openThread(
      listingId: listingId,
      buyerId: session.requireUser.userId,
    );
    await Get.toNamed(AppRoutes.chat, arguments: thread.id);
  }

  /// El aviso va a los seguidores, mas quien corresponda segun el caso, y
  /// nunca a quien provoco el evento.
  Future<void> _notify({
    required CarListing listing,
    required NotificationKind kind,
    required String body,
    required Set<String> exclude,
    required bool includeSeller,
    Set<String> extra = const {},
  }) async {
    final targets = <String>{
      ...await listings.followerIdsOf(listing.id),
      ...extra,
      if (includeSeller) listing.sellerId,
    }..removeAll(exclude);
    if (targets.isEmpty) return;
    await dispatcher.dispatch(
      userIds: targets.toList(),
      kind: kind,
      title: listing.title,
      body: body,
      listingId: listing.id,
    );
  }

  Future<void> _guard(Future<void> Function() action) async {
    sending.value = true;
    try {
      await action();
    } catch (e) {
      error.value = e.toString();
    } finally {
      sending.value = false;
    }
  }
}
