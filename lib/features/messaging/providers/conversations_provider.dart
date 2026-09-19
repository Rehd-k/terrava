import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/messaging/data/messaging_models.dart';
import 'package:terrava/features/messaging/data/messaging_repository.dart';
import 'package:terrava/features/messaging/data/realtime_client.dart';

class ConversationsNotifier extends AsyncNotifier<List<ConversationSummary>> {
  StreamSubscription<RealtimeEvent>? _subscription;

  @override
  Future<List<ConversationSummary>> build() async {
    ref.watch(realtimeConnectionProvider);
    final user = ref.watch(authSessionProvider).asData?.value;
    _subscription?.cancel();
    _subscription = ref.read(realtimeClientProvider).events.listen(_onEvent);
    ref.onDispose(() => _subscription?.cancel());

    if (user == null) {
      return const [];
    }
    return ref.read(messagingRepositoryProvider).listConversations();
  }

  Future<void> refresh() async {
    final user = ref.read(authSessionProvider).asData?.value;
    if (user == null) {
      state = const AsyncData([]);
      return;
    }
    state = await AsyncValue.guard(
      () => ref.read(messagingRepositoryProvider).listConversations(),
    );
  }

  void upsert(ConversationSummary conversation) {
    final current = state.asData?.value ?? const <ConversationSummary>[];
    final next =
        [conversation, ...current.where((item) => item.id != conversation.id)]
          ..sort((a, b) {
            final aTime = a.lastMessageAt ?? a.createdAt;
            final bTime = b.lastMessageAt ?? b.createdAt;
            return bTime.compareTo(aTime);
          });
    state = AsyncData(next);
  }

  void _onEvent(RealtimeEvent event) {
    switch (event) {
      case RealtimeConversationEvent(:final conversation):
        upsert(conversation);
      case RealtimeMessageEvent():
        break;
    }
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<ConversationSummary>>(
      ConversationsNotifier.new,
    );

final unreadMessagesCountProvider = Provider<int>((ref) {
  final conversations = ref.watch(conversationsProvider).asData?.value;
  if (conversations == null) {
    return 0;
  }
  return conversations.fold<int>(
    0,
    (sum, conversation) => sum + conversation.unreadCount,
  );
});
