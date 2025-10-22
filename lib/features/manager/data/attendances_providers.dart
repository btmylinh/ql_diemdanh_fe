import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'attendances_repository.dart';

// Provider for activity attendances
final activityAttendancesProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final repository = ref.watch(managerAttendancesRepositoryProvider);
  return repository.getActivityAttendances(
    activityId: params['activityId'] as int,
    page: params['page'] as int? ?? 1,
    limit: params['limit'] as int? ?? 50,
    search: params['search'] as String?,
  );
});

// Provider for attendance stats
final attendanceStatsProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, activityId) async {
  final repository = ref.watch(managerAttendancesRepositoryProvider);
  return repository.getAttendanceStats(activityId: activityId);
});

// Provider for manual checkin
final manualCheckinProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final repository = ref.watch(managerAttendancesRepositoryProvider);
  return repository.manualCheckin(
    activityId: params['activityId'] as int,
    userId: params['userId'] as int,
    notes: params['notes'] as String?,
  );
});
