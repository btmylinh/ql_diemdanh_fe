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

  // Get all registrations (for admin/manager overview)
  Future<Map<String, dynamic>> getAllRegistrations({
    int page = 1,
    int limit = 50,
    String? search,
    String? status,
    int? activityId,
  }) async {
    try {
      print('[REGISTRATIONS_API] Calling /registrations with params: page=$page, limit=$limit, search=$search, status=$status, activityId=$activityId');
      final res = await _dio.get('/registrations', queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (activityId != null) 'activity_id': activityId,
      });
      print('[REGISTRATIONS_API] Response status: ${res.statusCode}');
      print('[REGISTRATIONS_API] Response data keys: ${res.data.keys}');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      print('[REGISTRATIONS_API] Error: $e');
      if (e is DioException) {
        print('[REGISTRATIONS_API] DioException type: ${e.type}');
        print('[REGISTRATIONS_API] DioException status: ${e.response?.statusCode}');
        print('[REGISTRATIONS_API] DioException message: ${e.message}');
        print('[REGISTRATIONS_API] DioException response data: ${e.response?.data}');
      }
      rethrow;
    }
  }

  // Update registration status
  Future<Map<String, dynamic>> updateRegistrationStatus(int registrationId, String status) async {
    final res = await _dio.patch('/registrations/$registrationId/status', data: {
      'status': status,
    });
    return Map<String, dynamic>.from(res.data);
  }

  // Batch update registration statuses
  Future<Map<String, dynamic>> batchUpdateRegistrationStatuses(List<int> registrationIds, String status) async {
    final res = await _dio.patch('/registrations/batch-status', data: {
      'registration_ids': registrationIds,
      'status': status,
    });
    return Map<String, dynamic>.from(res.data);
  }

  // Delete registration
  Future<void> deleteRegistration(int registrationId) async {
    await _dio.delete('/registrations/$registrationId');
  }

  // Batch delete registrations
  Future<void> batchDeleteRegistrations(List<int> registrationIds) async {
    await _dio.delete('/registrations/batch', data: {
      'registration_ids': registrationIds,
    });
  }

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
