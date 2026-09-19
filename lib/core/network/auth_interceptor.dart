import 'package:dio/dio.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: ApiException(
            message:
                'Unable to reach the Terrava server. Check that the API is running.',
            isNetworkError: true,
          ),
          type: err.type,
          response: err.response,
        ),
      );
      return;
    }

    final data = response?.data;
    String message = 'Something went wrong';
    if (data is Map && data['message'] != null) {
      final raw = data['message'];
      if (raw is List) {
        message = raw.join(', ');
      } else {
        message = raw.toString();
      }
    } else if (err.message != null && err.message!.isNotEmpty) {
      message = err.message!;
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiException(message: message, statusCode: response?.statusCode),
        type: err.type,
        response: err.response,
      ),
    );
  }
}
