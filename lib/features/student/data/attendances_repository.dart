import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class AttendancesRepository {
  AttendancesRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> checkinByQr({required String qr}) async {
    final res = await _dio.post('/attendances/checkin-qr', data: {'qr': qr});
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> checkinByCode({required int activityId, required String code}) async {
    final res = await _dio.post('/attendances/checkin-code', data: {
      'activityId': activityId,
      'code': code,
    });
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> my({int page = 1, int limit = 10}) async {
    final res = await _dio.get('/attendances/my', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return Map<String, dynamic>.from(res.data);
  }
}

final attendancesRepositoryProvider = Provider<AttendancesRepository>((ref) {
  return AttendancesRepository(buildDio());
});



