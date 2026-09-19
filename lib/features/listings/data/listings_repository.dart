import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_client.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/features/listings/data/listing_models.dart';

class ListingsRepository {
  ListingsRepository(this._dio);

  final Dio _dio;

  Future<List<MapListingPin>> fetchMapPins({
    required MapBounds bounds,
    ListingFilters filters = ListingFilters.empty,
    int limit = 200,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/listings/map',
        queryParameters: {
          ...bounds.toQuery(),
          ...filters.toQuery(),
          'limit': limit,
        },
        cancelToken: cancelToken,
      );
      return (response.data ?? const [])
          .map((e) => MapListingPin.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ListingDetail> fetchListingDetail(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/listings/$id');
      return ListingDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<MapListingPin>> search({
    required String q,
    MapBounds? bounds,
    ListingFilters filters = ListingFilters.empty,
    int limit = 50,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/search',
        queryParameters: {
          'q': q,
          if (bounds != null) ...bounds.toQuery(),
          ...filters.copyWith(clearQ: true).toQuery(),
          'limit': limit,
        },
        cancelToken: cancelToken,
      );
      return (response.data ?? const [])
          .map((e) => MapListingPin.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<List<OwnerListing>> fetchMine({String? status}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/listings/me',
        queryParameters: {if (status != null) 'status': status},
      );
      return (response.data ?? const [])
          .map((e) => OwnerListing.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ListingDetail> fetchMineById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/listings/me/$id');
      return ListingDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ListingDetail> createListing(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/listings',
        data: body,
      );
      return ListingDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ListingDetail> updateListing(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/listings/$id',
        data: body,
      );
      return ListingDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ListingDetail> submitListing(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/listings/$id/submit',
      );
      return ListingDetail.fromJson(response.data!);
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
    return ApiException(message: e.message ?? 'Request failed');
  }
}

final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return ListingsRepository(ref.watch(apiClientProvider));
});
