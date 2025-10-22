import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'registrations_repository.dart';

// Provider for activity registrations (use records for stable params)
typedef ActivityRegistrationsParams = ({int activityId, int page, int limit, String? search, String? status});

final activityRegistrationsProvider = FutureProvider.family<Map<String, dynamic>, ActivityRegistrationsParams>((ref, params) async {
  final repository = ref.read(managerRegistrationsRepositoryProvider);
  return repository.getActivityRegistrations(
    params.activityId,
    page: params.page,
    limit: params.limit,
    search: params.search,
    status: params.status,
  );
});

// Provider for all registrations - Đã xóa vì không cần thiết

// Provider for registration statistics
final registrationStatsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, activityId) async {
  final repository = ref.read(managerRegistrationsRepositoryProvider);
  return repository.getRegistrationStats(activityId);
});

// Provider for registration management state
final registrationManagementProvider = StateNotifierProvider<RegistrationManagementNotifier, RegistrationManagementState>((ref) {
  return RegistrationManagementNotifier(ref.read(managerRegistrationsRepositoryProvider));
});

class RegistrationManagementState {
  final bool isLoading;
  final String? error;
  final List<int> selectedRegistrations;
  final String? searchQuery;
  final String? statusFilter;

  const RegistrationManagementState({
    this.isLoading = false,
    this.error,
    this.selectedRegistrations = const [],
    this.searchQuery,
    this.statusFilter,
  });

  RegistrationManagementState copyWith({
    bool? isLoading,
    String? error,
    List<int>? selectedRegistrations,
    String? searchQuery,
    String? statusFilter,
  }) {
    return RegistrationManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedRegistrations: selectedRegistrations ?? this.selectedRegistrations,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }
}

class RegistrationManagementNotifier extends StateNotifier<RegistrationManagementState> {
  RegistrationManagementNotifier(this._repository) : super(const RegistrationManagementState());

  final ManagerRegistrationsRepository _repository;

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
  }

  void toggleRegistrationSelection(int registrationId) {
    final selected = List<int>.from(state.selectedRegistrations);
    if (selected.contains(registrationId)) {
      selected.remove(registrationId);
    } else {
      selected.add(registrationId);
    }
    state = state.copyWith(selectedRegistrations: selected);
  }

  void selectAllRegistrations(List<int> allRegistrationIds) {
    state = state.copyWith(selectedRegistrations: allRegistrationIds);
  }

  void clearSelection() {
    state = state.copyWith(selectedRegistrations: []);
  }


  Future<List<int>?> exportRegistrationsToCSV(int activityId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final csvData = await _repository.exportRegistrationsToCSV(activityId);
      state = state.copyWith(isLoading: false);
      return csvData;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<List<int>?> exportAllRegistrationsToCSV({int? activityId, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final csvData = await _repository.exportAllRegistrationsToCSV(
        activityId: activityId,
        status: status,
      );
      state = state.copyWith(isLoading: false);
      return csvData;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}
