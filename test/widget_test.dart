import 'package:flutter_test/flutter_test.dart';
import 'package:terrava/features/listings/data/listing_models.dart';
import 'package:terrava/features/listings/presentation/listing_formatters.dart';

void main() {
  test('formats NGN sale, land, and annual rent beacons', () {
    expect(
      formatListingPrice(
        price: 85000000,
        currency: 'NGN',
        transactionType: 'SALE',
      ),
      '₦85M',
    );
    expect(
      formatListingPrice(
        price: 12500000,
        currency: 'NGN',
        transactionType: 'SALE',
        propertyType: 'LAND',
        landSize: 930,
      ),
      '₦12.5M · 2 plots',
    );
    expect(
      formatListingPrice(
        price: 2400000,
        currency: 'NGN',
        transactionType: 'RENT',
        pricePeriod: 'PER_YEAR',
      ),
      '₦2.4M/yr',
    );
  });

  test('formats USD sale and rental prices', () {
    expect(
      formatListingPrice(
        price: 4850000,
        currency: 'USD',
        transactionType: 'SALE',
      ),
      '\$4.85M',
    );
    expect(
      formatListingPrice(
        price: 12500,
        currency: 'USD',
        transactionType: 'RENT',
      ),
      '\$12.5k/yr',
    );
  });

  test('listed-by labels and distance copy', () {
    expect(listedByLabel('OWNER'), 'Directly by owner');
    expect(listedByLabel('AGENT'), 'Listed by agent');
    expect(listedByLabel('TENANT'), 'Listed by existing tenant');
    expect(
      formatDistanceFromUser(listingLat: 5.0377, listingLng: 7.9128),
      'Turn on location to see distance',
    );
    final nearby = formatDistanceFromUser(
      listingLat: 5.0377,
      listingLng: 7.9128,
      userLat: 5.038,
      userLng: 7.913,
    );
    expect(nearby.endsWith('from you'), isTrue);
  });

  test('parses listing detail fees, listedBy, and total due', () {
    final detail = ListingDetail.fromJson({
      'id': 'listing-1',
      'title': 'Ewet Housing 4-Bed Duplex',
      'description': 'Owner duplex',
      'price': 85000000,
      'agencyFee': 0,
      'legalFee': 1500000,
      'currency': 'NGN',
      'transactionType': 'SALE',
      'listedBy': 'OWNER',
      'pricePeriod': 'ONE_OFF',
      'listingType': 'STANDARD',
      'status': 'APPROVED',
      'createdAt': '2026-09-17T05:00:00.000Z',
      'property': {
        'id': 'prop-1',
        'type': 'HOUSE',
        'address': '14 Ewet Housing Estate',
        'city': 'Ewet Housing',
        'state': 'Akwa Ibom',
        'country': 'NG',
        'latitude': 5.0165,
        'longitude': 7.908,
        'propertySize': 280,
        'landSize': 465,
        'bedrooms': 4,
        'bathrooms': 5,
        'description': null,
        'amenities': ['BQ'],
      },
      'media': const [],
      'lister': {
        'id': 'user-1',
        'name': 'Chinedu Okon',
        'profileImageUrl': null,
        'verificationStatus': 'VERIFIED',
      },
    });
    expect(detail.listedBy, 'OWNER');
    expect(detail.totalDue, 86500000);
    expect(detail.property.city, 'Ewet Housing');
  });
}
