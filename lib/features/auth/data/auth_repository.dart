import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_client.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/core/storage/token_storage.dart';
import 'package:terrava/features/auth/data/auth_models.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final auth = AuthResponse.fromJson(response.data!);
      await _tokenStorage.writeAccessToken(auth.accessToken);
      return auth;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
        },
      );
      final auth = AuthResponse.fromJson(response.data!);
      await _tokenStorage.writeAccessToken(auth.accessToken);
      return auth;
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<AuthUser?> me() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me');
      return AuthUser.fromJson(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _tokenStorage.clear();
        return null;
      }
      throw _map(e);
    }
  }

  Future<void> logout() => _tokenStorage.clear();

  Future<AuthUser> updateMe({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/users/me',
        data: {
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        },
      );
      return AuthUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<UserStats> stats() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/users/me/stats');
      return UserStats.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Exception _map(DioException e) {
    final error = e.error;
    if (error is ApiException) return error;
    return ApiException(message: e.message ?? 'Authentication failed');
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});
