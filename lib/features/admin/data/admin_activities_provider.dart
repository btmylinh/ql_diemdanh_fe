import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api_client.dart';

class AdminActivitiesState {
  final List<Map<String, dynamic>> activities;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String statusFilter;

  const AdminActivitiesState({
    this.activities = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter = 'all',
  });

  AdminActivitiesState copyWith({
    List<Map<String, dynamic>>? activities,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
  }) {
    return AdminActivitiesState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class AdminActivitiesNotifier extends StateNotifier<AdminActivitiesState> {
  AdminActivitiesNotifier(this.ref) : super(const AdminActivitiesState());

  final Ref ref;
  final ApiClient _apiClient = ApiClient();

  Future<void> loadActivities() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final queryParams = <String, String>{
        'page': '1',
        'limit': '100',
        if (state.searchQuery.isNotEmpty) 'q': state.searchQuery,
        if (state.statusFilter != 'all') 'status': state.statusFilter,
        'sortBy': 'createdAt',
        'sortOrder': 'desc',
      };

      final response = await _apiClient.get('/activities/admin/all', queryParams);
      
      if (response['activities'] != null) {
        final activities = List<Map<String, dynamic>>.from(response['activities']);
        state = state.copyWith(activities: activities, isLoading: false);
      } else {
        state = state.copyWith(
          error: response['error']?['message'] ?? response['message'] ?? 'Không thể tải danh sách hoạt động',
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('[ADMIN_ACTIVITIES] Error loading activities: $e');
      state = state.copyWith(
        error: 'Lỗi kết nối: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  void searchActivities(String query) {
    state = state.copyWith(searchQuery: query);
    loadActivities();
  }

  void filterByStatus(String status) {
    state = state.copyWith(statusFilter: status);
    loadActivities();
  }


  Future<bool> changeActivityStatus(int activityId, int newStatus) async {
    try {
      final response = await _apiClient.put(
        '/activities/$activityId',
        {'status': newStatus},
      );

      if (response['data'] != null) {
        // Update activity in local state
        final updatedActivities = state.activities.map((a) {
          if (a['id'] == activityId) {
            return {...a, 'status': newStatus};
          }
          return a;
        }).toList();
        state = state.copyWith(activities: updatedActivities);
        return true;
      } else if (response['error'] != null) {
        state = state.copyWith(
          error: response['error']['message'] ?? 'Không thể thay đổi trạng thái hoạt động',
        );
        return false;
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể thay đổi trạng thái hoạt động',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[ADMIN_ACTIVITIES] Error changing activity status: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deleteActivity(int activityId) async {
    try {
      final response = await _apiClient.delete('/activities/$activityId');

      if (response['message'] != null) {
        // Remove activity from local state
        final updatedActivities = state.activities.where((a) => a['id'] != activityId).toList();
        state = state.copyWith(activities: updatedActivities);
        return true;
      } else if (response['error'] != null) {
        state = state.copyWith(
          error: response['error']['message'] ?? 'Không thể xóa hoạt động',
        );
        return false;
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể xóa hoạt động',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[ADMIN_ACTIVITIES] Error deleting activity: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> bulkDeleteActivities(List<int> activityIds) async {
    try {
      final response = await _apiClient.post(
        '/activities/bulk-delete',
        {'activity_ids': activityIds},
      );

      if (response['message'] != null) {
        // Remove activities from local state
        final updatedActivities = state.activities.where((a) => !activityIds.contains(a['id'])).toList();
        state = state.copyWith(activities: updatedActivities);
        return true;
      } else if (response['error'] != null) {
        state = state.copyWith(
          error: response['error']['message'] ?? 'Không thể xóa các hoạt động',
        );
        return false;
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể xóa các hoạt động',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[ADMIN_ACTIVITIES] Error bulk deleting activities: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateActivity(int activityId, Map<String, dynamic> activityData) async {
    try {
      final response = await _apiClient.put(
        '/activities/$activityId',
        activityData,
      );

      if (response['data'] != null) {
        // Update activity in local state
        final updatedActivities = state.activities.map((a) {
          if (a['id'] == activityId) {
            return {...a, ...activityData};
          }
          return a;
        }).toList();
        state = state.copyWith(activities: updatedActivities);
        return true;
      } else if (response['error'] != null) {
        state = state.copyWith(
          error: response['error']['message'] ?? 'Không thể cập nhật hoạt động',
        );
        return false;
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể cập nhật hoạt động',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[ADMIN_ACTIVITIES] Error updating activity: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> exportActivities() async {
    try {
      final response = await _apiClient.post('/activities/export', {});
      
      if (response['data'] != null) {
        // TODO: Handle file download
        debugPrint('[ADMIN_ACTIVITIES] Export data received: ${response['data']}');
      } else if (response['error'] != null) {
        state = state.copyWith(
          error: response['error']['message'] ?? 'Không thể xuất dữ liệu hoạt động',
        );
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể xuất dữ liệu hoạt động',
        );
      }
    } catch (e) {
      debugPrint('[ADMIN_ACTIVITIES] Error exporting activities: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> getActivityRegistrations(int activityId) async {
    try {
      final response = await _apiClient.get(
        '/activities/$activityId/registrations',
        {'page': '1', 'limit': '100'},
      );
      return response;
    } catch (e) {
      debugPrint('[ADMIN_ACTIVITIES] Error getting activity registrations: $e');
      return {'error': 'Lỗi: ${e.toString()}'};
    }
  }
}

final adminActivitiesProvider = StateNotifierProvider<AdminActivitiesNotifier, AdminActivitiesState>(
  (ref) => AdminActivitiesNotifier(ref),
);
