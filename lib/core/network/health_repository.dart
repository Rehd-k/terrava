import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_client.dart';
import 'package:terrava/core/network/api_exception.dart';

class HealthRepository {
  HealthRepository(this._dio);

  final Dio _dio;

  Future<bool> isHealthy() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/health');
      return response.data?['status'] == 'ok';
    } on DioException catch (e) {
      final error = e.error;
      if (error is ApiException) rethrow;
      throw ApiException(message: 'Backend unavailable', isNetworkError: true);
    }
  }
}

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(ref.watch(apiClientProvider));
});
