import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'attendances_repository.dart';

final myAttendancesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(attendancesRepositoryProvider);
  return repo.my();
});
