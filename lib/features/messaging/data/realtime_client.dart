import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:terrava/core/config/app_config.dart';
import 'package:terrava/core/storage/token_storage.dart';
import 'package:terrava/features/auth/providers/auth_session_provider.dart';
import 'package:terrava/features/messaging/data/messaging_models.dart';

sealed class RealtimeEvent {}

class RealtimeMessageEvent extends RealtimeEvent {
  RealtimeMessageEvent(this.message);
  final ChatMessage message;
}

class RealtimeConversationEvent extends RealtimeEvent {
  RealtimeConversationEvent(this.conversation);
  final ConversationSummary conversation;
}

class RealtimeClient {
  RealtimeClient();

  io.Socket? _socket;
  final _controller = StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get events => _controller.stream;

  void connect(String token) {
    if (_socket?.connected == true) {
      return;
    }
    disconnect();
    final socket = io.io(
      '${AppConfig.apiBaseUrl}/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    socket.on('message:new', (data) {
      if (data is Map) {
        _controller.add(
          RealtimeMessageEvent(
            ChatMessage.fromJson(Map<String, dynamic>.from(data)),
          ),
        );
      }
    });
    socket.on('conversation:updated', (data) {
      if (data is Map) {
        _controller.add(
          RealtimeConversationEvent(
            ConversationSummary.fromJson(Map<String, dynamic>.from(data)),
          ),
        );
      }
    });
    socket.connect();
    _socket = socket;
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _controller.close();
  }
}

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient();
  ref.onDispose(client.dispose);
  return client;
});

final realtimeConnectionProvider = Provider<void>((ref) {
  final client = ref.watch(realtimeClientProvider);
  final auth = ref.watch(authSessionProvider).asData?.value;
  if (auth == null) {
    client.disconnect();
    return;
  }

  Future<void> attach() async {
    final token = await ref.read(tokenStorageProvider).readAccessToken();
    if (token == null || token.isEmpty) {
      client.disconnect();
      return;
    }
    client.connect(token);
  }

  attach();
});
