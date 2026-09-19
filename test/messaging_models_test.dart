import 'package:flutter_test/flutter_test.dart';
import 'package:terrava/features/messaging/data/messaging_models.dart';

void main() {
  test('parses conversation summaries and relative times', () {
    final summary = ConversationSummary.fromJson({
      'id': 'convo-1',
      'listing': {
        'id': 'listing-1',
        'title': 'The Glass Pavilion Villa',
        'transactionType': 'SALE',
        'city': 'Bel Air',
        'thumbnailUrl': 'https://example.com/villa.jpg',
      },
      'otherUser': {
        'id': 'user-1',
        'name': 'Elena Vance',
        'profileImageUrl': null,
        'verificationStatus': 'VERIFIED',
      },
      'lastMessage': {
        'id': 'msg-1',
        'conversationId': 'convo-1',
        'senderId': 'user-2',
        'body': 'Is the pavilion still available?',
        'createdAt': '2026-09-08T12:00:00.000Z',
        'updatedAt': '2026-09-08T12:00:00.000Z',
      },
      'unreadCount': 1,
      'createdAt': '2026-09-08T11:00:00.000Z',
      'updatedAt': '2026-09-08T12:00:00.000Z',
      'lastMessageAt': '2026-09-08T12:00:00.000Z',
    });

    expect(summary.otherUser.name, 'Elena Vance');
    expect(summary.listing.city, 'Bel Air');
    expect(summary.lastMessage?.body, contains('pavilion'));
    expect(summary.unreadCount, 1);
    expect(
      formatThreadTime(
        DateTime(2026, 9, 8, 15, 4),
        now: DateTime(2026, 9, 8, 18),
      ),
      '15:04',
    );
    expect(
      formatThreadTime(
        DateTime(2026, 9, 7, 15, 4),
        now: DateTime(2026, 9, 8, 18),
      ),
      'Yesterday',
    );
  });
}
