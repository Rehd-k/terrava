import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_client.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/features/admin/data/admin_models.dart';
import 'package:terrava/features/listings/data/listing_models.dart';

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  Future<AdminStats> fetchStats() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/stats');
      return AdminStats.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<PaginatedAdminUsers> fetchUsers({
    AdminUserQuery query = const AdminUserQuery(),
    int page = 1,
    int limit = 40,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/users',
        queryParameters: {
          if (query.verificationStatus != null)
            'verificationStatus': query.verificationStatus,
          if (query.accountStatus != null) 'accountStatus': query.accountStatus,
          if (query.q != null && query.q!.trim().isNotEmpty)
            'q': query.q!.trim(),
          'page': page,
          'limit': limit,
        },
      );
      return PaginatedAdminUsers.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<AdminUser> fetchUser(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/admin/users/$id');
      return AdminUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<AdminUser> verifyUser(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/users/$id/verify',
      );
      return AdminUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<AdminUser> rejectVerification(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/users/$id/reject-verification',
      );
      return AdminUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<AdminUser> suspendUser(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/users/$id/suspend',
      );
      return AdminUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<AdminUser> activateUser(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/users/$id/activate',
      );
      return AdminUser.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<PaginatedAdminListings> fetchListings({
    AdminListingQuery query = AdminListingQuery.pending,
    int page = 1,
    int limit = 40,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/listings',
        queryParameters: {
          if (query.all) 'all': true,
          if (!query.all && query.status != null) 'status': query.status,
          if (query.q != null && query.q!.trim().isNotEmpty)
            'q': query.q!.trim(),
          'page': page,
          'limit': limit,
        },
      );
      return PaginatedAdminListings.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ListingDetail> fetchListing(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/admin/listings/$id',
      );
      return ListingDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ListingDetail> approveListing(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/listings/$id/approve',
      );
      return ListingDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ListingDetail> rejectListing(String id, String note) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/listings/$id/reject',
        data: {'note': note},
      );
      return ListingDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ListingDetail> requestChanges(String id, String note) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/listings/$id/request-changes',
        data: {'note': note},
      );
      return ListingDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ListingDetail> suspendListing(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/admin/listings/$id/suspend',
      );
      return ListingDetail.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Exception _map(DioException e) {
    if (e.type == DioExceptionType.cancel) return e;
    final error = e.error;
    if (error is ApiException) return error;
    return ApiException(message: e.message ?? 'Request failed');
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});
