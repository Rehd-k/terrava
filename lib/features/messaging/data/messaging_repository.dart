import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_client.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/features/messaging/data/messaging_models.dart';

class MessagingRepository {
  MessagingRepository(this._dio);

  final Dio _dio;

  Future<List<ConversationSummary>> listConversations() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/messaging/conversations',
      );
      return (response.data ?? const [])
          .map((e) => ConversationSummary.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/messaging/unread-count',
      );
      return response.data?['count'] as int? ?? 0;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ConversationSummary> startConversation({
    required String listingId,
    String? message,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/messaging/conversations',
        data: {
          'listingId': listingId,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        },
      );
      return ConversationSummary.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ConversationSummary> getConversation(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/messaging/conversations/$id',
      );
      return ConversationSummary.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<MessagePage> listMessages(
    String conversationId, {
    String? before,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/messaging/conversations/$conversationId/messages',
        queryParameters: {if (before != null) 'before': before, 'limit': limit},
      );
      return MessagePage.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/messaging/conversations/$conversationId/messages',
        data: {'body': body},
      );
      return ChatMessage.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ConversationSummary> markRead(String conversationId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/messaging/conversations/$conversationId/read',
      );
      return ConversationSummary.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Exception _map(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return e;
    }
    final error = e.error;
    if (error is ApiException) return error;
    return ApiException(message: e.message ?? 'Messaging request failed');
  }
}

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository(ref.watch(apiClientProvider));
});
