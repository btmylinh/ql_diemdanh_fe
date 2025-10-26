import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/registrations_providers.dart';
import '../data/attendances_providers.dart';
import '../../../theme.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationsAsync = ref.watch(myRegistrationsProvider);
    final attendancesAsync = ref.watch(myAttendancesProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Báo cáo thống kê',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => context.push('/student/periodic-reports'),
            tooltip: 'Báo cáo định kỳ',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(myRegistrationsProvider);
              ref.invalidate(myAttendancesProvider);
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tổng quan
            _OverviewCard(
              registrationsAsync: registrationsAsync,
              attendancesAsync: attendancesAsync,
            ),
            
            const SizedBox(height: 24),
            
            // Thống kê chi tiết
            registrationsAsync.when(
              data: (registrationsData) {
                final registrations = List<Map<String, dynamic>>.from(registrationsData['registrations'] ?? []);
                return attendancesAsync.when(
                  data: (attendancesData) {
                    final attendances = List<Map<String, dynamic>>.from(attendancesData['attendances'] ?? []);
                    return _DetailedStats(
                      registrations: registrations,
                      attendances: attendances,
                    );
                  },
                  error: (error, stack) => Center(child: Text('Lỗi: $error')),
                  loading: () => const Center(child: CircularProgressIndicator()),
                );
              },
              error: (error, stack) => Center(child: Text('Lỗi: $error')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.registrationsAsync,
    required this.attendancesAsync,
  });

  final AsyncValue registrationsAsync;
  final AsyncValue attendancesAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kGreen, kGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan hoạt động',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          registrationsAsync.when(
            data: (registrationsData) {
              final registrations = List<Map<String, dynamic>>.from(registrationsData['registrations'] ?? []);
              return attendancesAsync.when(
                data: (attendancesData) {
                  final attendances = List<Map<String, dynamic>>.from(attendancesData['attendances'] ?? []);
                  
                  // Tính tổng điểm
                  int totalPoints = 0;
                  for (final attendance in attendances) {
                    totalPoints += (attendance['points'] as int? ?? 0);
                  }
                  
                  return Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          icon: Icons.event_available,
                          label: 'Đã đăng ký',
                          value: '${registrations.length}',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.check_circle,
                          label: 'Đã tham gia',
                          value: '${attendances.length}',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
                error: (error, stack) => const Text('Lỗi tải dữ liệu', style: TextStyle(color: Colors.white)),
                loading: () => const Text('Đang tải...', style: TextStyle(color: Colors.white)),
              );
            },
            error: (error, stack) => const Text('Lỗi tải dữ liệu', style: TextStyle(color: Colors.white)),
            loading: () => const Text('Đang tải...', style: TextStyle(color: Colors.white)),
          ),
          
          const SizedBox(height: 16),
          
          // Tổng điểm rèn luyện
          attendancesAsync.when(
            data: (attendancesData) {
              final attendances = List<Map<String, dynamic>>.from(attendancesData['attendances'] ?? []);
              int totalPoints = 0;
              for (final attendance in attendances) {
                totalPoints += (attendance['points'] as int? ?? 0);
              }
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Tổng điểm rèn luyện: $totalPoints',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
            error: (error, stack) => const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _DetailedStats extends StatelessWidget {
  const _DetailedStats({
    required this.registrations,
    required this.attendances,
  });

  final List<Map<String, dynamic>> registrations;
  final List<Map<String, dynamic>> attendances;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chi tiết hoạt động',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        // Danh sách đã đăng ký
        if (registrations.isNotEmpty) ...[
          _SectionCard(
            title: 'Hoạt động đã đăng ký',
            count: registrations.length,
            icon: Icons.event_available,
            color: Colors.blue,
            children: registrations.map((reg) => _ActivityItem(
              activity: Map<String, dynamic>.from(reg['activity'] ?? {}),
              status: 'registered',
              points: null,
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Danh sách đã tham gia
        if (attendances.isNotEmpty) ...[
          _SectionCard(
            title: 'Hoạt động đã tham gia',
            count: attendances.length,
            icon: Icons.check_circle,
            color: Colors.green,
            children: attendances.map((att) => _ActivityItem(
              activity: Map<String, dynamic>.from(att['activity'] ?? {}),
              status: 'attended',
              points: att['points'] as int? ?? 0,
            )).toList(),
          ),
        ],
        
        if (registrations.isEmpty && attendances.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: const Column(
              children: [
                Icon(Icons.inbox, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Chưa có hoạt động nào',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Hãy tham gia các hoạt động để tích lũy điểm rèn luyện',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.children,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.activity,
    required this.status,
    this.points,
  });

  final Map<String, dynamic> activity;
  final String status;
  final int? points;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['name'] ?? 'Hoạt động',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (activity['location'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    activity['location'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (points != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '$points điểm',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
                isActive: true,
                onTap: () {},
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
