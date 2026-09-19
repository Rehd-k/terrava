import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terrava/features/listings/data/listing_models.dart';

void main() {
  test('parses live NestJS map pins from localhost:3000', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:3000',
        connectTimeout: const Duration(seconds: 5),
      ),
    );

    final response = await dio.get<List<dynamic>>(
      '/listings/map',
      queryParameters: {
        'minLat': 4.95,
        'maxLat': 5.12,
        'minLng': 7.82,
        'maxLng': 7.98,
      },
    );

    expect(response.statusCode, 200);
    final pins = (response.data ?? const [])
        .map((e) => MapListingPin.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(pins, isNotEmpty);
    expect(pins.first.id, isNotEmpty);
    expect(pins.first.latitude, isNonZero);
    expect(pins.first.longitude, isNonZero);

    final detailResponse = await dio.get<Map<String, dynamic>>(
      '/listings/${pins.first.id}',
    );
    final detail = ListingDetail.fromJson(detailResponse.data!);
    expect(detail.title, isNotEmpty);
    expect(detail.status, 'APPROVED');
  });

  test('parses live NestJS search results', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final response = await dio.get<List<dynamic>>(
      '/search',
      queryParameters: {'q': 'Ewet'},
    );
    final pins = (response.data ?? const [])
        .map((e) => MapListingPin.fromJson(e as Map<String, dynamic>))
        .toList();
    expect(pins, isNotEmpty);
    expect(
      pins.any(
        (p) =>
            p.city?.toLowerCase().contains('ewet') == true ||
            p.title.toLowerCase().contains('ewet'),
      ),
      isTrue,
    );
  });
}
