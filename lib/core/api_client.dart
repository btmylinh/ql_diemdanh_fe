import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as dev;

String baseUrl() {
  if (Platform.isAndroid) return 'http://10.0.2.2:3000'; // Android Emulator
  return 'http://127.0.0.1:3000'; 
}

final storage = const FlutterSecureStorage();

Dio buildDio() {
  final dio = Dio(BaseOptions(
    baseUrl: baseUrl(), 
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  ));
  dev.log('[API] Base URL: ${dio.options.baseUrl}');
  
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await storage.read(key: 'access_token');
      dev.log('[API][REQ] ${options.method} ${options.uri}');
      dev.log('[API][TOKEN] Token: ${token != null ? 'Present (${token.length} chars)' : 'Missing'}');
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onResponse: (response, handler) {
      dev.log('[API][RES] ${response.requestOptions.method} ${response.requestOptions.uri} Status: ${response.statusCode}');
      handler.next(response);
    },
    onError: (DioException e, handler) {
      dev.log('[API][ERR] ${e.requestOptions.method} ${e.requestOptions.uri} Type: ${e.type} Status: ${e.response?.statusCode} Message: ${e.message}');
      
      // Xử lý lỗi mạng cụ thể
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        e = DioException(
          requestOptions: e.requestOptions,
          error: 'Kết nối quá thời gian. Vui lòng thử lại.',
          type: e.type,
        );
      } else if (e.type == DioExceptionType.connectionError) {
        e = DioException(
          requestOptions: e.requestOptions,
          error: 'Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng và thử lại.',
          type: e.type,
        );
      }
      
      handler.next(e);
    },
  ));
  return dio;
}

class ApiClient {
  final Dio _dio = buildDio();

  Future<Map<String, dynamic>> get(String path, [Map<String, String>? queryParams]) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      rethrow;
    }
  }
}