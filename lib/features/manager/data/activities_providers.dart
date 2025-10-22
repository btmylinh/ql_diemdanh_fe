import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activities_repository.dart';

// Provider for manager activities list
final managerActivitiesProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final repository = ref.read(managerActivitiesRepositoryProvider);
  return repository.list(
    page: params['page'] as int? ?? 1,
    limit: params['limit'] as int? ?? 10,
    q: params['q'] as String?,
    status: params['status'] as int?,
    location: params['location'] as String?,
    startDate: params['startDate'] as String?,
    endDate: params['endDate'] as String?,
    capacityMin: params['capacityMin'] as int?,
    capacityMax: params['capacityMax'] as int?,
  );
});

// Provider for my activities (created by current user)
// Use records for stable value-equality to avoid re-fetch loops on rebuilds
typedef MyActivitiesParams = ({int page, int limit, String? q, int? status});

final myActivitiesProvider = FutureProvider.family<Map<String, dynamic>, MyActivitiesParams>((ref, params) async {
  final repository = ref.read(managerActivitiesRepositoryProvider);
  return repository.getMyActivities(
    page: params.page,
    limit: params.limit,
    q: params.q,
    status: params.status,
  );
});

// Provider for single activity
final activityProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final repository = ref.read(managerActivitiesRepositoryProvider);
  return repository.getById(id);
});

// Provider for dashboard statistics
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(managerActivitiesRepositoryProvider);
  return repository.getDashboardStats();
});

// Provider for activity form state
final activityFormProvider = StateNotifierProvider<ActivityFormNotifier, ActivityFormState>((ref) {
  return ActivityFormNotifier(ref.read(managerActivitiesRepositoryProvider));
});

class ActivityFormState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? activity;
  final bool isEditing;

  const ActivityFormState({
    this.isLoading = false,
    this.error,
    this.activity,
    this.isEditing = false,
  });

  ActivityFormState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? activity,
    bool? isEditing,
  }) {
    return ActivityFormState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activity: activity ?? this.activity,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class ActivityFormNotifier extends StateNotifier<ActivityFormState> {
  ActivityFormNotifier(this._repository) : super(const ActivityFormState());

  final ManagerActivitiesRepository _repository;

  void setEditing(bool isEditing) {
    state = state.copyWith(isEditing: isEditing);
  }

  void setActivity(Map<String, dynamic> activity) {
    state = state.copyWith(activity: activity);
  }

  Future<void> createActivity(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.create(data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateActivity(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.update(id, data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteActivity(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.delete(id);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateActivityStatus(int id, int status) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.updateStatus(id, status);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
