import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/registrations_providers.dart';
import '../data/attendances_providers.dart';
import '../../../theme.dart';

class MyActivitiesScreen extends ConsumerWidget {
  const MyActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Hoạt động của tôi',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: kBlue,
            labelColor: kBlue,
            unselectedLabelColor: Colors.grey,
            tabs: const [
            Tab(text: 'Đã đăng ký'),
            Tab(text: 'Điểm danh'),
            ],
          ),
        ),
        body: TabBarView(children: [
          _RegistrationsTab(),
          _AttendancesTab(),
        ]),
        bottomNavigationBar: _BottomNavigationBar(),
      ),
    );
  }
}

class _RegistrationsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RegistrationsTab> createState() => _RegistrationsTabState();
}

class _RegistrationsTabState extends ConsumerState<_RegistrationsTab> {
  @override
  Widget build(BuildContext context) {
    final registrationsAsync = ref.watch(myRegistrationsProvider);
    
    return registrationsAsync.when(
      data: (data) {
        final list = List<Map<String, dynamic>>.from(data['registrations'] ?? []);
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
              onTap: () => context.push('/student/activity/${a['id']}'),
            );
          },
        );
      },
      error: (error, stack) => Center(child: Text('Lỗi: $error')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _AttendancesTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AttendancesTab> createState() => _AttendancesTabState();
}

class _AttendancesTabState extends ConsumerState<_AttendancesTab> {
  @override
  Widget build(BuildContext context) {
    final attendancesAsync = ref.watch(myAttendancesProvider);
    
    return attendancesAsync.when(
      data: (data) {
        final list = List<Map<String, dynamic>>.from(data['attendances'] ?? []);
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
              onTap: () => context.push('/student/activity/${a['id']}'),
            );
          },
        );
      },
      error: (error, stack) => Center(child: Text('Lỗi: $error')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.play_circle_fill,
                label: 'Hoạt động',
                isActive: false,
                onTap: () => context.go('/student/activities'),
              ),
              _NavItem(
                icon: Icons.qr_code_scanner,
                label: 'QR danh',
                isActive: false,
                onTap: () => context.push('/student/qr-scan'),
              ),
              _NavItem(
                icon: Icons.assessment_outlined,
                label: 'Báo cáo',
                isActive: false,
                onTap: () => context.push('/student/reports'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Hồ sơ',
                isActive: false,
                onTap: () => context.push('/student/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: isActive ? 28 : 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
