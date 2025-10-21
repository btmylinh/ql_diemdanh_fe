import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class RegistrationsRepository {
  RegistrationsRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> register(int activityId) async {
    final res = await _dio.post('/registrations', data: {'activityId': activityId});
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> cancel(int activityId) async {
    final res = await _dio.delete('/registrations/$activityId');
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> my({int page = 1, int limit = 10}) async {
    final res = await _dio.get('/registrations/my', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return Map<String, dynamic>.from(res.data);
  }
}

final registrationsRepositoryProvider = Provider<RegistrationsRepository>((ref) {
  return RegistrationsRepository(buildDio());
});



