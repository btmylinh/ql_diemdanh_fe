import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class ManagerRegistrationsRepository {
  ManagerRegistrationsRepository(this._dio);
  final Dio _dio;

  // Get registrations for a specific activity
  Future<Map<String, dynamic>> getActivityRegistrations(int activityId, {
    int page = 1,
    int limit = 50,
    String? search,
    String? status,
  }) async {
    final res = await _dio.get('/activities/$activityId/registrations', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return Map<String, dynamic>.from(res.data);
  }

  // Get all registrations - Đã xóa vì không cần thiết


  // Export registrations to CSV
  Future<List<int>> exportRegistrationsToCSV(int activityId) async {
    final res = await _dio.get('/activities/$activityId/registrations/export', 
      options: Options(responseType: ResponseType.bytes)
    );
    return res.data as List<int>;
  }

  // Export all registrations to CSV
  Future<List<int>> exportAllRegistrationsToCSV({
    int? activityId,
    String? status,
  }) async {
    final res = await _dio.get('/registrations/export', 
      queryParameters: {
        if (activityId != null) 'activity_id': activityId,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      options: Options(responseType: ResponseType.bytes)
    );
    return res.data as List<int>;
  }

  // Get registration statistics
  Future<Map<String, dynamic>> getRegistrationStats(int activityId) async {
    final res = await _dio.get('/activities/$activityId/registrations/stats');
    return Map<String, dynamic>.from(res.data);
  }
}

final managerRegistrationsRepositoryProvider = Provider<ManagerRegistrationsRepository>((ref) {
  return ManagerRegistrationsRepository(buildDio());
});
