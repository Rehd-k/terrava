import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/config/app_config.dart';

class GeocodedAddress {
  const GeocodedAddress({
    this.address,
    this.city,
    this.state,
    this.country,
    this.label,
  });

  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? label;
}

class GeocodingRepository {
  GeocodingRepository(this._dio);

  final Dio _dio;

  Future<GeocodedAddress?> reverse({
    required double latitude,
    required double longitude,
  }) async {
    final token = AppConfig.mapboxAccessToken;
    if (token.isEmpty) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$longitude,$latitude.json',
        queryParameters: {'access_token': token, 'limit': 1},
      );
      final features = response.data?['features'] as List<dynamic>? ?? const [];
      if (features.isEmpty) return null;
      final feature = features.first as Map<String, dynamic>;
      final context = feature['context'] as List<dynamic>? ?? const [];

      String? city;
      String? state;
      String? country;
      for (final raw in context) {
        if (raw is! Map<String, dynamic>) continue;
        final id = (raw['id'] as String?) ?? '';
        final text = raw['text'] as String?;
        if (id.startsWith('place') || id.startsWith('locality')) {
          city ??= text;
        } else if (id.startsWith('region')) {
          state = text;
        } else if (id.startsWith('country')) {
          country = (raw['short_code'] as String?)?.toUpperCase() ?? text;
        }
      }

      final houseNumber = feature['address'] as String?;
      final street = feature['text'] as String?;
      final line = [
        if (houseNumber != null && houseNumber.isNotEmpty) houseNumber,
        if (street != null && street.isNotEmpty) street,
      ].join(' ');

      return GeocodedAddress(
        address: line.isEmpty ? feature['place_name'] as String? : line,
        city: city,
        state: state,
        country: country,
        label: feature['place_name'] as String?,
      );
    } on DioException {
      return null;
    }
  }
}

final geocodingRepositoryProvider = Provider<GeocodingRepository>((ref) {
  return GeocodingRepository(Dio());
});
