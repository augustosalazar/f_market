import 'package:get/get.dart';

import 'package:f_roble_market/features/auth/ui/viewmodels/session_view_model.dart';
import 'package:f_roble_market/features/chat/domain/models/chat_thread.dart';
import 'package:f_roble_market/features/chat/domain/repositories/i_chat_repository.dart';

/// La lista de chats privados del usuario.
class ChatsViewModel extends GetxController {
  ChatsViewModel(this._chats, this._session);

  final IChatRepository _chats;
  final SessionViewModel _session;

  final threads = <ChatThread>[].obs;
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
      threads.clear();
      return;
    }
    loading.value = true;
    try {
      threads.assignAll(await _chats.threadsOf(user.userId));
    } finally {
      loading.value = false;
    }
  }
}
