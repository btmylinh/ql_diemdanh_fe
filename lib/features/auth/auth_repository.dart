import 'package:dio/dio.dart';
import 'dart:convert';
import '../../core/api_client.dart';

class AuthRepository {
  final Dio _dio = buildDio();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
      await storage.write(key: 'access_token', value: res.data['accessToken']);
      await storage.write(key: 'user_json', value: res.data['user'] == null ? null : jsonEncode(res.data['user']));
      return Map<String, dynamic>.from(res.data['user']);
    } on DioException catch (e) {
      // Xử lý lỗi từ Dio
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Kết nối quá thời gian. Vui lòng thử lại.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng và thử lại.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('Email hoặc mật khẩu không đúng.');
      } else if (e.response?.statusCode == 403) {
        throw Exception('Tài khoản bị khóa. Vui lòng liên hệ quản trị viên.');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy tài khoản. Vui lòng kiểm tra email.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('Lỗi server. Vui lòng thử lại sau.');
      } else {
        throw Exception('Đăng nhập thất bại. Vui lòng thử lại.');
      }
    } catch (e) {
      // Xử lý các lỗi khác
      if (e.toString().contains('SocketException') || 
          e.toString().contains('HandshakeException')) {
        throw Exception('Không thể kết nối đến server. Vui lòng kiểm tra kết nối mạng và thử lại.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
    String? mssv,
    String? clazz,
    String? phone,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'name': name,
      'mssv': mssv,
      'class': clazz,
      'phone': phone,
    });
    await storage.write(key: 'access_token', value: res.data['accessToken']);
    await storage.write(key: 'user_json', value: res.data['user'] == null ? null : jsonEncode(res.data['user']));
    return Map<String, dynamic>.from(res.data['user']);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _dio.get('/auth/me');
    await storage.write(key: 'user_json', value: jsonEncode(res.data['user']));
    return Map<String, dynamic>.from(res.data['user']);
  }

  Future<void> logout() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'user_json');
  }
}
