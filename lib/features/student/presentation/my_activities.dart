import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/registrations_repository.dart';
import '../data/attendances_repository.dart';

class MyActivitiesScreen extends ConsumerWidget {
  const MyActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hoạt động của tôi'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Đã đăng ký'),
            Tab(text: 'Điểm danh'),
          ]),
        ),
        body: TabBarView(children: [
          _RegistrationsTab(),
          _AttendancesTab(),
        ]),
      ),
    );
  }
}

class _RegistrationsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RegistrationsTab> createState() => _RegistrationsTabState();
}

class _RegistrationsTabState extends ConsumerState<_RegistrationsTab> {
  late Future<Map<String, dynamic>> _future;
  @override
  void initState() {
    super.initState();
    _future = ref.read(registrationsRepositoryProvider).my();
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
        final list = List<Map<String, dynamic>>.from(snap.data?['registrations'] ?? []);
        if (list.isEmpty) return const Center(child: Text('Chưa có đăng ký'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r = list[i];
            final a = Map<String, dynamic>.from(r['activity'] ?? {});
            return ListTile(
              leading: const Icon(Icons.event),
              title: Text(a['name'] ?? ''),
              subtitle: Text('Trạng thái: ${r['status'] ?? 'unknown'}'),
            );
          },
        );
      },
    );
  }
}

class _AttendancesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AttendancesTab> createState() => _AttendancesTabState();
}

class _AttendancesTabState extends ConsumerState<_AttendancesTab> {
  late Future<Map<String, dynamic>> _future;
  @override
  void initState() {
    super.initState();
    _future = ref.read(attendancesRepositoryProvider).my();
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));
        final list = List<Map<String, dynamic>>.from(snap.data?['attendances'] ?? []);
        if (list.isEmpty) return const Center(child: Text('Chưa có điểm danh'));
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final it = list[i];
            final a = Map<String, dynamic>.from(it['activity'] ?? {});
            final status = it['status'] ?? 'present';
            final points = it['points'] ?? 0;
            return ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(a['name'] ?? ''),
              subtitle: Text('Trạng thái: $status  •  Điểm: $points'),
            );
          },
        );
      },
    );
  }
}



