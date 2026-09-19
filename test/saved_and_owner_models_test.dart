import 'package:flutter_test/flutter_test.dart';
import 'package:terrava/features/listings/data/listing_models.dart';
import 'package:terrava/features/saved/data/saved_listing.dart';

void main() {
  test('parses saved listing and owner listing json', () {
    final saved = SavedListing.fromJson({
      'id': 'listing-1',
      'title': 'The Glass Pavilion Villa',
      'price': 4850000,
      'currency': 'USD',
      'transactionType': 'SALE',
      'propertyType': 'HOUSE',
      'latitude': 34.09,
      'longitude': -118.44,
      'thumbnailUrl': 'https://example.com/a.jpg',
      'city': 'Bel Air',
      'landSize': 0.82,
      'propertySize': 6200,
      'savedAt': '2026-09-08T15:00:00.000Z',
    });
    expect(saved.title, contains('Pavilion'));
    expect(saved.city, 'Bel Air');

    final owner = OwnerListing.fromJson({
      'id': 'listing-1',
      'title': 'The Glass Pavilion Villa',
      'price': 4850000,
      'currency': 'USD',
      'transactionType': 'SALE',
      'propertyType': 'HOUSE',
      'status': 'APPROVED',
      'thumbnailUrl': 'https://example.com/a.jpg',
      'address': '1 Crest Ridge Road',
      'city': 'Bel Air',
      'state': 'CA',
      'landSize': 0.82,
      'propertySize': 6200,
      'createdAt': '2026-09-08T11:00:00.000Z',
      'updatedAt': '2026-09-08T11:00:00.000Z',
      'submittedAt': '2026-09-08T11:00:00.000Z',
    });
    expect(owner.status, 'APPROVED');
    expect(owner.locationLabel, contains('Bel Air'));
  });
}
