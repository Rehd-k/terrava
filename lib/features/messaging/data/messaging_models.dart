class ConversationUser {
  const ConversationUser({
    required this.id,
    required this.name,
    this.profileImageUrl,
    required this.verificationStatus,
  });

  final String id;
  final String name;
  final String? profileImageUrl;
  final String verificationStatus;

  factory ConversationUser.fromJson(Map<String, dynamic> json) {
    return ConversationUser(
      id: json['id'] as String,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      verificationStatus: json['verificationStatus'] as String,
    );
  }
}

class ConversationListing {
  const ConversationListing({
    required this.id,
    required this.title,
    required this.transactionType,
    this.city,
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String transactionType;
  final String? city;
  final String? thumbnailUrl;

  factory ConversationListing.fromJson(Map<String, dynamic> json) {
    return ConversationListing(
      id: json['id'] as String,
      title: json['title'] as String,
      transactionType: json['transactionType'] as String,
      city: json['city'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.listing,
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
    this.lastMessageAt,
  });

  final String id;
  final ConversationListing listing;
  final ConversationUser otherUser;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime? lastMessageAt;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'] as String,
      listing: ConversationListing.fromJson(
        json['listing'] as Map<String, dynamic>,
      ),
      otherUser: ConversationUser.fromJson(
        json['otherUser'] as Map<String, dynamic>,
      ),
      lastMessage: json['lastMessage'] == null
          ? null
          : ChatMessage.fromJson(json['lastMessage'] as Map<String, dynamic>),
      unreadCount: json['unreadCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      lastMessageAt: json['lastMessageAt'] == null
          ? null
          : DateTime.parse(json['lastMessageAt'] as String).toLocal(),
    );
  }

  ConversationSummary copyWith({
    ChatMessage? lastMessage,
    int? unreadCount,
    DateTime? lastMessageAt,
  }) {
    return ConversationSummary(
      id: id,
      listing: listing,
      otherUser: otherUser,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }
}

class MessagePage {
  const MessagePage({required this.items, required this.hasMore});

  final List<ChatMessage> items;
  final bool hasMore;

  factory MessagePage.fromJson(Map<String, dynamic> json) {
    return MessagePage(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

String formatThreadTime(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final local = time.toLocal();
  final sameDay =
      current.year == local.year &&
      current.month == local.month &&
      current.day == local.day;
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  if (sameDay) {
    return '$hh:$mm';
  }
  final yesterday = current.subtract(const Duration(days: 1));
  final isYesterday =
      yesterday.year == local.year &&
      yesterday.month == local.month &&
      yesterday.day == local.day;
  if (isYesterday) {
    return 'Yesterday';
  }
  return '${local.month}/${local.day}';
}
