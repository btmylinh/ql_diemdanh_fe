import 'package:dio/dio.dart';
import 'dart:convert';
import '../../core/api_client.dart';

class AuthRepository {
  final Dio _dio = buildDio();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {'email': email, 'password': password});
    await storage.write(key: 'access_token', value: res.data['accessToken']);
    await storage.write(key: 'user_json', value: res.data['user'] == null ? null : jsonEncode(res.data['user']));
    return Map<String, dynamic>.from(res.data['user']);
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
