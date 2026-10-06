import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out. Cloud server may be waking up, please retry in a few moments.',
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String extractedMsg = 'An unexpected error occurred.';

        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('detail')) {
            extractedMsg = responseData['detail'].toString();
          } else if (responseData.containsKey('error')) {
            extractedMsg = responseData['error'].toString();
          } else if (responseData.containsKey('message')) {
            extractedMsg = responseData['message'].toString();
          } else if (responseData.isNotEmpty) {
            final firstKey = responseData.keys.first;
            final val = responseData[firstKey];
            if (val is List && val.isNotEmpty) {
              extractedMsg = '$firstKey: ${val.first}';
            } else {
              extractedMsg = '$firstKey: $val';
            }
          }
        } else if (responseData is String && responseData.isNotEmpty) {
          extractedMsg = responseData;
        }

        if (statusCode == 401) {
          final msg = (extractedMsg != 'An unexpected error occurred.')
              ? extractedMsg
              : 'Invalid credentials or session expired. Please try again.';
          return ApiException(
            message: msg,
            statusCode: 401,
            data: responseData,
          );
        } else if (statusCode == 403) {
          final msg = (extractedMsg != 'An unexpected error occurred.')
              ? extractedMsg
              : 'You do not have permission to perform this action.';
          return ApiException(
            message: msg,
            statusCode: 403,
            data: responseData,
          );
        } else if (statusCode == 404) {
          final msg = (extractedMsg != 'An unexpected error occurred.')
              ? extractedMsg
              : 'Requested resource not found.';
          return ApiException(
            message: msg,
            statusCode: 404,
            data: responseData,
          );
        } else if (statusCode != null && statusCode >= 500) {
          final msg = (extractedMsg != 'An unexpected error occurred.')
              ? extractedMsg
              : 'Server error. Please try again later.';
          return ApiException(
            message: msg,
            statusCode: statusCode,
            data: responseData,
          );
        }

        return ApiException(
          message: extractedMsg,
          statusCode: statusCode,
          data: responseData,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Cannot reach StudentBrain cloud server. Please check your internet connection and retry.',
          statusCode: 0,
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'Request was cancelled.');
      default:
        return ApiException(
          message: error.message ?? 'An unknown network error occurred.',
          statusCode: error.response?.statusCode,
        );
    }
  }

  @override
  String toString() => message;
}
