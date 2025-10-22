import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class ManagerAttendancesRepository {
  final Dio _dio;

  ManagerAttendancesRepository(this._dio);

  // Get attendances for a specific activity
  Future<Map<String, dynamic>> getActivityAttendances({
    required int activityId,
    int page = 1,
    int limit = 50,
    String? search,
  }) async {
    try {
      print('[ATTENDANCES_API] Calling /attendances/activity/$activityId with params: page=$page, limit=$limit, search=$search');
      final res = await _dio.get('/attendances/activity/$activityId', queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      });
      print('[ATTENDANCES_API] Response status: ${res.statusCode}');
      print('[ATTENDANCES_API] Response data keys: ${res.data.keys}');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      print('[ATTENDANCES_API] Error: $e');
      if (e is DioException) {
        print('[ATTENDANCES_API] DioException type: ${e.type}');
        print('[ATTENDANCES_API] DioException status: ${e.response?.statusCode}');
        print('[ATTENDANCES_API] DioException message: ${e.message}');
        print('[ATTENDANCES_API] DioException response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // Get attendance stats for a specific activity
  Future<Map<String, dynamic>> getAttendanceStats({
    required int activityId,
  }) async {
    try {
      print('[ATTENDANCES_API] Calling /attendances/activity/$activityId/stats');
      final res = await _dio.get('/attendances/activity/$activityId/stats');
      print('[ATTENDANCES_API] Stats response status: ${res.statusCode}');
      print('[ATTENDANCES_API] Stats response data keys: ${res.data.keys}');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      print('[ATTENDANCES_API] Stats error: $e');
      if (e is DioException) {
        print('[ATTENDANCES_API] Stats DioException type: ${e.type}');
        print('[ATTENDANCES_API] Stats DioException status: ${e.response?.statusCode}');
        print('[ATTENDANCES_API] Stats DioException message: ${e.message}');
        print('[ATTENDANCES_API] Stats DioException response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // Manual check-in for a user
  Future<Map<String, dynamic>> manualCheckin({
    required int activityId,
    required int userId,
    String? notes,
  }) async {
    try {
      print('[ATTENDANCES_API] Manual checkin for activity $activityId, user $userId');
      final res = await _dio.post('/attendances/checkin-manual', data: {
        'activityId': activityId,
        'userId': userId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      print('[ATTENDANCES_API] Manual checkin response status: ${res.statusCode}');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      print('[ATTENDANCES_API] Manual checkin error: $e');
      if (e is DioException) {
        print('[ATTENDANCES_API] Manual checkin DioException type: ${e.type}');
        print('[ATTENDANCES_API] Manual checkin DioException status: ${e.response?.statusCode}');
        print('[ATTENDANCES_API] Manual checkin DioException message: ${e.message}');
        print('[ATTENDANCES_API] Manual checkin DioException response data: ${e.response?.data}');
      }
      rethrow;
    }
  }
}

final managerAttendancesRepositoryProvider = Provider<ManagerAttendancesRepository>((ref) {
  return ManagerAttendancesRepository(buildDio());
});
