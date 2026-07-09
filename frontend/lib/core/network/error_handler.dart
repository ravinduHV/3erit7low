import 'package:dio/dio.dart';

class ErrorHandler {
  static String handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return "Connection timed out. Please check your internet connection.";
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data is Map && data.containsKey('detail')) {
            return data['detail'] is String ? data['detail'] : data['detail'].toString();
          }
          if (data is Map && data.containsKey('message')) {
            return data['message'] is String ? data['message'] : data['message'].toString();
          }
          return "Server error: ${error.response?.statusCode}. Please try again.";
        case DioExceptionType.cancel:
          return "Request cancelled.";
        case DioExceptionType.connectionError:
          return "Unable to connect to the server. Please verify the backend status.";
        default:
          return "Something went wrong. Please try again later.";
      }
    }
    return error?.toString() ?? "An unexpected error occurred.";
  }
}
