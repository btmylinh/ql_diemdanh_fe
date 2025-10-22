import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';

class ManagerActivitiesRepository {
  ManagerActivitiesRepository(this._dio);
  final Dio _dio;

  // Get all activities for manager (with all statuses)
  Future<Map<String, dynamic>> list({
    int page = 1,
    int limit = 10,
    String? q,
    int? status,
    String? location,
    String? startDate,
    String? endDate,
    int? capacityMin,
    int? capacityMax,
  }) async {
    final res = await _dio.get('/activities', queryParameters: {
      'page': page,
      'limit': limit,
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != null) 'status': status,
      if (location != null && location.isNotEmpty) 'location': location,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      if (capacityMin != null) 'capacity_min': capacityMin,
      if (capacityMax != null) 'capacity_max': capacityMax,
      'sortBy': 'startTime',
      'sortOrder': 'desc',
    });
    return Map<String, dynamic>.from(res.data);
  }

  // Get my activities (created by current user)
  Future<Map<String, dynamic>> getMyActivities({
    int page = 1,
    int limit = 10,
    String? q,
    int? status,
  }) async {
    final res = await _dio.get('/activities/my', queryParameters: {
      'page': page,
      'limit': limit,
      if (q != null && q.isNotEmpty) 'q': q,
      if (status != null) 'status': status,
      'sortBy': 'startTime',
      'sortOrder': 'desc',
    });
    return Map<String, dynamic>.from(res.data);
  }

  // Get activity by ID
  Future<Map<String, dynamic>> getById(int id) async {
    final res = await _dio.get('/activities/$id');
    return Map<String, dynamic>.from(res.data['activity']);
  }

  // Create new activity
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final res = await _dio.post('/activities', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  // Update activity
  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final res = await _dio.put('/activities/$id', data: data);
    return Map<String, dynamic>.from(res.data);
  }

  // Delete activity
  Future<void> delete(int id) async {
    await _dio.delete('/activities/$id');
  }

  // Update activity status
  Future<Map<String, dynamic>> updateStatus(int id, int status) async {
    final res = await _dio.patch('/activities/$id/status', data: {'status': status});
    return Map<String, dynamic>.from(res.data);
  }

  // Generate QR code for activity
  Future<Map<String, dynamic>> generateQRCode(int id) async {
    final res = await _dio.post('/activities/$id/qr');
    return Map<String, dynamic>.from(res.data);
  }

  // Get QR code for activity
  Future<Map<String, dynamic>> getQRCode(int id) async {
    final res = await _dio.get('/activities/$id/qr');
    return Map<String, dynamic>.from(res.data);
  }

  // Get dashboard statistics (only for activities created by current manager)
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final res = await _dio.get('/activities/my', queryParameters: {
        'page': 1,
        'limit': 1000, // Get all my activities for stats calculation
      });
      final data = Map<String, dynamic>.from(res.data);
    
    // Calculate statistics from the data
    final activities = data['activities'] as List<dynamic>? ?? [];
    
    // Debug logging
    print('[DASHBOARD_STATS] API Response: ${data.keys}');
    print('[DASHBOARD_STATS] My activities count from API: ${activities.length}');
    
    int totalActivities = activities.length;
    int activeActivities = 0;      // status 2 (ongoing)
    int upcomingActivities = 0;  // status 1 (upcoming)
    int completedActivities = 0;  // status 3 (completed)
    int cancelledActivities = 0; // status 4 (cancelled)
    int totalRegistrations = 0;
    
    for (final activity in activities) {
      final activityData = activity as Map<String, dynamic>;
      final status = activityData['status'] as int? ?? 0;
      
      // Use API-provided registered_count instead of registrations array
      totalRegistrations += (activityData['registered_count'] as int?) ?? 0;
      
      switch (status) {
        case 1: // Upcoming
          upcomingActivities++;
          break;
        case 2: // Ongoing/Active
          activeActivities++;
          break;
        case 3: // Completed
          completedActivities++;
          break;
        case 4: // Cancelled
          cancelledActivities++;
          break;
      }
    }
    
    final result = {
      'totalActivities': totalActivities,
      'activeActivities': activeActivities,
      'upcomingActivities': upcomingActivities,
      'completedActivities': completedActivities,
      'cancelledActivities': cancelledActivities,
      'totalRegistrations': totalRegistrations,
    };
    
    // Debug logging
    print('[DASHBOARD_STATS] Final stats (my activities): $result');
    
    return result;
    } catch (e) {
      print('[DASHBOARD_STATS] Error: $e');
      // Return default stats on error
      return {
        'totalActivities': 0,
        'activeActivities': 0,
        'upcomingActivities': 0,
        'completedActivities': 0,
        'cancelledActivities': 0,
        'totalRegistrations': 0,
      };
    }
  }
}

final managerActivitiesRepositoryProvider = Provider<ManagerActivitiesRepository>((ref) {
  return ManagerActivitiesRepository(buildDio());
});
