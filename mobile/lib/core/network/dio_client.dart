import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class DioClient {
  final Dio dio;
  final SecureStorageService storageService;

  DioClient({
    required this.storageService,
  }) : dio = Dio() {
    final customBaseUrl = storageService.getBaseUrl();
    final baseUrl = (customBaseUrl != null &&
            customBaseUrl.isNotEmpty &&
            customBaseUrl.startsWith('https://') &&
            !customBaseUrl.contains('192.168.') &&
            !customBaseUrl.contains('10.') &&
            !customBaseUrl.contains('172.') &&
            !customBaseUrl.contains('10.0.2.2') &&
            !customBaseUrl.contains('127.0.0.1') &&
            !customBaseUrl.contains('localhost'))
        ? customBaseUrl
        : ApiEndpoints.defaultBaseUrl;

    dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    // Auto-retry interceptor for Render cloud cold-start wakeups
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException err, ErrorInterceptorHandler handler) async {
          final isNetworkOrTimeout = err.type == DioExceptionType.connectionTimeout ||
              err.type == DioExceptionType.receiveTimeout ||
              err.type == DioExceptionType.sendTimeout ||
              err.type == DioExceptionType.connectionError;

          final alreadyRetried = err.requestOptions.extra['retried_cold_start'] == true;

          if (isNetworkOrTimeout && !alreadyRetried) {
            err.requestOptions.extra['retried_cold_start'] = true;
            // Ensure target is the official Render cloud backend
            if (!err.requestOptions.baseUrl.contains('onrender.com')) {
              err.requestOptions.baseUrl = ApiEndpoints.defaultBaseUrl;
            }
            try {
              await Future.delayed(const Duration(milliseconds: 1500));
              final response = await dio.fetch(err.requestOptions);
              return handler.resolve(response);
            } catch (_) {
              return handler.next(err);
            }
          }
          return handler.next(err);
        },
      ),
    );

    dio.interceptors.add(AuthInterceptor(dio, storageService));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('[DIO] $obj'),
        ),
      );
    }
  }

  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
    storageService.setBaseUrl(newUrl);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
