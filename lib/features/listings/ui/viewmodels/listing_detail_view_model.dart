import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/domain/repositories/i_chat_repository.dart';
import 'package:f_roble_market/features/listings/domain/models/car_listing.dart';
import 'package:f_roble_market/features/listings/domain/models/listing_status.dart';
import 'package:f_roble_market/features/listings/domain/repositories/i_listing_repository.dart';
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
    required this.session,
  });

  final String listingId;
  final IListingRepository listings;
  final IQaRepository qa;
  final IChatRepository chats;
  final INotificationDispatcher dispatcher;
  final SessionViewModel session;

  final listing = Rxn<CarListing>();
  final questions = <Question>[].obs;
  final loading = true.obs;
  final following = false.obs;
  final sending = false.obs;
  final photoIndex = 0.obs;

  /// Lo que la pantalla debe mostrarle al usuario. La vista escucha y lo pinta;
  /// el view model no toca widgets, asi se puede probar sin Flutter.
  final message = RxnString();
  final error = RxnString();

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
      final user = session.user.value;
      following.value = user != null &&
          (await listings.followedIds(user.userId)).contains(listingId);
    } finally {
      loading.value = false;
    }
  }

  Future<void> toggleFollow() async {
    if (!await session.ensureLoggedIn()) return;
    following.value = await listings.toggleFollow(
      listingId: listingId,
      userId: session.requireUser.userId,
    );
    message.value = following.value
        ? 'Sigues esta publicacion: te avisaremos de preguntas, respuestas y cambios de estado.'
        : 'Dejaste de seguir esta publicacion.';
  }

  /// Pregunta publica. Avisa al vendedor (requisito 7) y a los seguidores de
  /// la publicacion (requisito 6), nunca a quien pregunta.
  Future<void> ask(String text) async {
    if (!await session.ensureLoggedIn()) return;
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

    await _guard(() async {
      await qa.ask(
        listingId: current.id,
        askerId: asker.userId,
        askerName: asker.name,
        text: body,
      );
      await _notify(
        listing: current,
        kind: NotificationKind.question,
        body: '${asker.name} pregunto: $body',
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
