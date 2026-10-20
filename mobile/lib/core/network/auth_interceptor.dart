import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends QueuedInterceptor {
  final Dio _dio;
  final SecureStorageService _storageService;
  late final Dio _tokenDio;
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshCompleters = [];

  AuthInterceptor(this._dio, this._storageService) {
    _tokenDio = Dio(
      BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip token for login and register endpoints
    final isAuthEndpoint = options.path.contains(ApiEndpoints.login) ||
        options.path.contains(ApiEndpoints.register) ||
        options.path.contains(ApiEndpoints.tokenRefresh);

    if (!isAuthEndpoint) {
      final token = await _storageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthEndpoint = err.requestOptions.path.contains(ApiEndpoints.login) ||
        err.requestOptions.path.contains(ApiEndpoints.tokenRefresh);

    if (err.response?.statusCode == 401 && !isAuthEndpoint) {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _storageService.clearTokens();
        return handler.next(err);
      }

      if (_isRefreshing) {
        final completer = Completer<void>();
        _refreshCompleters.add(completer);
        try {
          await completer.future;
          return handler.resolve(await _retry(err.requestOptions));
        } catch (_) {
          return handler.next(err);
        }
      }

      _isRefreshing = true;
      try {
        _tokenDio.options.baseUrl = _dio.options.baseUrl;
        final response = await _tokenDio.post(
          ApiEndpoints.tokenRefresh,
          data: {'refresh': refreshToken},
        );

        final newAccess = response.data['access'] as String?;
        if (newAccess != null) {
          await _storageService.saveTokens(access: newAccess);
          for (final c in _refreshCompleters) {
            c.complete();
          }
          _refreshCompleters.clear();
          return handler.resolve(await _retry(err.requestOptions));
        } else {
          throw Exception('No access token returned');
        }
      } catch (e) {
        for (final c in _refreshCompleters) {
          c.completeError(e);
        }
        _refreshCompleters.clear();
        await _storageService.clearTokens();
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }

    return handler.next(err);
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _storageService.getAccessToken();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
