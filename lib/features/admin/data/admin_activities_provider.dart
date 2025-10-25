import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/api_client.dart';

class AdminActivitiesState {
  final List<Map<String, dynamic>> activities;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String statusFilter;
  final String sortBy;
  final String sortOrder;

  const AdminActivitiesState({
    this.activities = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.sortBy = 'created_at',
    this.sortOrder = 'desc',
  });

  AdminActivitiesState copyWith({
    List<Map<String, dynamic>>? activities,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? statusFilter,
    String? sortBy,
    String? sortOrder,
  }) {
    return AdminActivitiesState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
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
        'sortBy': state.sortBy,
        'sortOrder': state.sortOrder,
      };

      final response = await _apiClient.get('/activities/admin/all', queryParams);
      
      if (response['activities'] != null) {
        final activities = List<Map<String, dynamic>>.from(response['activities']);
        state = state.copyWith(activities: activities, isLoading: false);
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể tải danh sách hoạt động',
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

  void sortActivities(String sortBy, String sortOrder) {
    state = state.copyWith(sortBy: sortBy, sortOrder: sortOrder);
    loadActivities();
  }

  Future<void> changeActivityStatus(int activityId, int newStatus) async {
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
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể thay đổi trạng thái hoạt động',
        );
      }
    } catch (e) {
      debugPrint('[ADMIN_ACTIVITIES] Error changing activity status: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
    }
  }

  Future<void> deleteActivity(int activityId) async {
    try {
      final response = await _apiClient.delete('/activities/$activityId');

      if (response['message'] != null) {
        // Remove activity from local state
        final updatedActivities = state.activities.where((a) => a['id'] != activityId).toList();
        state = state.copyWith(activities: updatedActivities);
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể xóa hoạt động',
        );
      }
    } catch (e) {
      debugPrint('[ADMIN_ACTIVITIES] Error deleting activity: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
    }
  }

  Future<void> bulkDeleteActivities(List<int> activityIds) async {
    try {
      final response = await _apiClient.post(
        '/activities/bulk-delete',
        {'activity_ids': activityIds},
      );

      if (response['message'] != null) {
        // Remove activities from local state
        final updatedActivities = state.activities.where((a) => !activityIds.contains(a['id'])).toList();
        state = state.copyWith(activities: updatedActivities);
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể xóa các hoạt động',
        );
      }
    } catch (e) {
      debugPrint('[ADMIN_ACTIVITIES] Error bulk deleting activities: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
    }
  }

  Future<void> exportActivities() async {
    try {
      final response = await _apiClient.post('/activities/export', {});
      
      if (response['data'] != null) {
        // TODO: Handle file download
        debugPrint('[ADMIN_ACTIVITIES] Export data received: ${response['data']}');
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
}

final adminActivitiesProvider = StateNotifierProvider<AdminActivitiesNotifier, AdminActivitiesState>(
  (ref) => AdminActivitiesNotifier(ref),
);
