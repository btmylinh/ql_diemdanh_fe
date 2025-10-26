import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'registrations_repository.dart';

final myRegistrationsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(registrationsRepositoryProvider);
  return repo.my();
});
