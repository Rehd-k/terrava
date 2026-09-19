import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_client.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/features/saved/data/saved_listing.dart';

class SavedPropertiesRepository {
  SavedPropertiesRepository(this._dio);

  final Dio _dio;

  Future<List<SavedListing>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/saved-properties');
      return (response.data ?? const [])
          .map((e) => SavedListing.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<bool> isSaved(String listingId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/saved-properties/$listingId',
      );
      return response.data?['saved'] as bool? ?? false;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<SavedListing> save(String listingId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/saved-properties',
        data: {'listingId': listingId},
      );
      return SavedListing.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<void> unsave(String listingId) async {
    try {
      await _dio.delete<void>('/saved-properties/$listingId');
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Exception _map(DioException e) {
    if (e.type == DioExceptionType.cancel) return e;
    final error = e.error;
    if (error is ApiException) return error;
    return ApiException(message: e.message ?? 'Saved listings request failed');
  }
}

final savedPropertiesRepositoryProvider = Provider<SavedPropertiesRepository>((
  ref,
) {
  return SavedPropertiesRepository(ref.watch(apiClientProvider));
});
