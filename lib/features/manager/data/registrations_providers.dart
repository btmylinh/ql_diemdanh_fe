import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'registrations_repository.dart';

// Provider for activity registrations
final activityRegistrationsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final repository = ref.read(managerRegistrationsRepositoryProvider);
  return repository.getActivityRegistrations(
    params['activityId'] as int,
    page: params['page'] as int? ?? 1,
    limit: params['limit'] as int? ?? 50,
    search: params['search'] as String?,
    status: params['status'] as String?,
  );
});

// Provider for all registrations
final allRegistrationsProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final repository = ref.read(managerRegistrationsRepositoryProvider);
  return repository.getAllRegistrations(
    page: params['page'] as int? ?? 1,
    limit: params['limit'] as int? ?? 50,
    search: params['search'] as String?,
    status: params['status'] as String?,
    activityId: params['activityId'] as int?,
  );
});

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

  Future<void> updateRegistrationStatus(int registrationId, String status) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.updateRegistrationStatus(registrationId, status);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> batchUpdateRegistrationStatuses(String status) async {
    if (state.selectedRegistrations.isEmpty) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.batchUpdateRegistrationStatuses(state.selectedRegistrations, status);
      state = state.copyWith(isLoading: false, selectedRegistrations: []);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteRegistration(int registrationId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.deleteRegistration(registrationId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> batchDeleteRegistrations() async {
    if (state.selectedRegistrations.isEmpty) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.batchDeleteRegistrations(state.selectedRegistrations);
      state = state.copyWith(isLoading: false, selectedRegistrations: []);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
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
