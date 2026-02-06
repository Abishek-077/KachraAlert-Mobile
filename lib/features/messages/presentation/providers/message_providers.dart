import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

import '../../../../core/api/api_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/chat_contact.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/message_repository_api.dart';

final messageRepoProvider = Provider<MessageRepositoryApi>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  return MessageRepositoryApi(
    client: ref.watch(apiClientProvider),
    accessToken: auth?.session?.accessToken,
  );
});

final messageContactsProvider = StateNotifierProvider<MessageContactsNotifier,
    AsyncValue<List<ChatContact>>>((ref) {
  return MessageContactsNotifier(ref.watch(messageRepoProvider));
});

class MessageContactsNotifier
    extends StateNotifier<AsyncValue<List<ChatContact>>> {
  MessageContactsNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  final MessageRepositoryApi _repo;
  static const int _pageSize = 50;

  Future<void> load({bool silent = false}) async {
    if (!silent) state = const AsyncValue.loading();
    try {
      final contacts = await _repo.getContacts(limit: _pageSize);
      state = AsyncValue.data(contacts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final messageConversationProvider = StateNotifierProvider<
    MessageConversationNotifier, AsyncValue<List<ChatMessage>>>((ref) {
  return MessageConversationNotifier(ref.watch(messageRepoProvider));
});

class MessageConversationNotifier
    extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  MessageConversationNotifier(this._repo) : super(const AsyncValue.data([]));

  final MessageRepositoryApi _repo;
  String? _activeContactId;
  static const int _pageSize = 50;

  String? get activeContactId => _activeContactId;

  Future<void> openConversation(String contactId) async {
    final normalizedId = contactId.trim();
    if (normalizedId.isEmpty) return;
    _activeContactId = normalizedId;
    state = const AsyncValue.loading();
    await _loadConversation(showLoadingOnError: true, limit: _pageSize);
  }

  Future<void> restoreConversation(String? contactId) async {
    final normalizedId = contactId?.trim();
    if (normalizedId == null || normalizedId.isEmpty) {
      _activeContactId = null;
      state = const AsyncValue.data([]);
      return;
    }
    _activeContactId = normalizedId;
    await _loadConversation(showLoadingOnError: false, limit: _pageSize);
  }

  Future<void> refresh() async {
    await _loadConversation(
      showLoadingOnError: false,
      silent: true,
      limit: _pageSize,
    );
  }

  Future<void> sendMessage(String body) async {
    final contactId = _activeContactId;
    final text = body.trim();
    if (contactId == null || contactId.isEmpty || text.isEmpty) return;

    await _repo.sendMessage(contactId: contactId, body: text);
    await refresh();
  }

  Future<void> _loadConversation({
    required bool showLoadingOnError,
    bool silent = false,
    int? limit,
    DateTime? before,
  }) async {
    final contactId = _activeContactId;
    if (contactId == null || contactId.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    if (!silent) state = const AsyncValue.loading();

    try {
      final messages = await _repo.getConversation(
        contactId,
        limit: limit,
        before: before,
      );
      state = AsyncValue.data(messages);
    } catch (e, st) {
      if (showLoadingOnError && state.valueOrNull == null) {
        state = const AsyncValue.loading();
      }
      state = AsyncValue.error(e, st);
    }
  }
}
