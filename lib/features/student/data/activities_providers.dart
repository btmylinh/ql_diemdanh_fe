import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activities_repository.dart';

class ActivitiesQuery {
  const ActivitiesQuery({this.q, this.dateIso, this.page = 1});
  final String? q;
  final String? dateIso;
  final int page;
}

final activitiesQueryProvider = StateProvider<ActivitiesQuery>((ref) {
  return const ActivitiesQuery();
});

final activitiesListProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(activitiesRepositoryProvider);
  final query = ref.watch(activitiesQueryProvider);
  return repo.list(page: query.page, q: query.q, dateIso: query.dateIso);
});



