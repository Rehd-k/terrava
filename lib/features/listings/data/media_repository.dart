import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terrava/core/network/api_client.dart';
import 'package:terrava/core/network/api_exception.dart';
import 'package:terrava/features/listings/data/listing_models.dart';

class ImageKitAuth {
  const ImageKitAuth({
    required this.token,
    required this.expire,
    required this.signature,
    required this.publicKey,
  });

  final String token;
  final int expire;
  final String signature;
  final String publicKey;

  factory ImageKitAuth.fromJson(Map<String, dynamic> json) {
    return ImageKitAuth(
      token: json['token'] as String,
      expire: (json['expire'] as num).toInt(),
      signature: json['signature'] as String,
      publicKey: json['publicKey'] as String,
    );
  }
}

class ImageKitUploadResult {
  const ImageKitUploadResult({
    required this.fileId,
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.fileType,
  });

  final String fileId;
  final String url;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final String? fileType;
}

class MediaRepository {
  MediaRepository(this._dio);

  final Dio _dio;
  final Dio _uploadDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ),
  );

  Future<ImageKitAuth> fetchAuth() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/media/imagekit/auth',
      );
      return ImageKitAuth.fromJson(response.data!);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<ImageKitUploadResult> uploadToImageKit({
    required List<int> bytes,
    required String fileName,
    required ImageKitAuth auth,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'fileName': fileName,
        'publicKey': auth.publicKey,
        'signature': auth.signature,
        'expire': auth.expire.toString(),
        'token': auth.token,
        'useUniqueFileName': 'true',
        'folder': '/terrava/listings',
      });
      final response = await _uploadDio.post<Map<String, dynamic>>(
        'https://upload.imagekit.io/api/v1/files/upload',
        data: form,
      );
      final data = response.data!;
      return ImageKitUploadResult(
        fileId: data['fileId'] as String,
        url: data['url'] as String,
        thumbnailUrl: data['thumbnailUrl'] as String?,
        width: (data['width'] as num?)?.toInt(),
        height: (data['height'] as num?)?.toInt(),
        fileType: data['fileType'] as String?,
      );
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Photo upload failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ListingMedia> persist({
    required ImageKitUploadResult uploaded,
    required String listingId,
    String fileType = 'image/jpeg',
    int sortOrder = 0,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/media',
        data: {
          'imageKitFileId': uploaded.fileId,
          'url': uploaded.url,
          'fileType': fileType,
          'mediaType': 'IMAGE',
          if (uploaded.thumbnailUrl != null)
            'thumbnailUrl': uploaded.thumbnailUrl,
          if (uploaded.width != null) 'width': uploaded.width,
          if (uploaded.height != null) 'height': uploaded.height,
          'sortOrder': sortOrder,
          'listingId': listingId,
        },
      );
      final data = response.data!;
      return ListingMedia(
        id: data['id'] as String,
        url: data['url'] as String,
        thumbnailUrl: data['thumbnailUrl'] as String?,
        mediaType: data['mediaType'] as String? ?? 'IMAGE',
        sortOrder: data['sortOrder'] as int? ?? sortOrder,
      );
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<void>('/media/$id');
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  Exception _map(DioException e) {
    if (e.type == DioExceptionType.cancel) return e;
    final error = e.error;
    if (error is ApiException) return error;
    return ApiException(message: e.message ?? 'Media request failed');
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(apiClientProvider));
});
