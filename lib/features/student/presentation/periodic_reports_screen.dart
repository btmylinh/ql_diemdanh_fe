import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../theme.dart';
import '../data/registrations_providers.dart';
import '../data/attendances_providers.dart';

class PeriodicReportsScreen extends ConsumerStatefulWidget {
  const PeriodicReportsScreen({super.key});

  @override
  ConsumerState<PeriodicReportsScreen> createState() => _PeriodicReportsScreenState();
}

class _PeriodicReportsScreenState extends ConsumerState<PeriodicReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedPeriod = DateTime.now();
  String _selectedPeriodType = 'month'; // month, week, year

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Báo cáo định kỳ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: _showPeriodSelector,
            tooltip: 'Chọn kỳ báo cáo',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: kGreen,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kGreen,
          tabs: const [
            Tab(icon: Icon(Icons.assessment), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.timeline), text: 'Xu hướng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildTrendsTab(),
        ],
      ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }

  Widget _buildOverviewTab() {
    final registrationsAsync = ref.watch(myRegistrationsProvider);
    final attendancesAsync = ref.watch(myAttendancesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kGreen.withValues(alpha: 0.6), kGreen.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kGreen.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Kỳ báo cáo: ${_getPeriodText()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Thống kê hoạt động cá nhân',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Cards
          Text(
            'Thống kê tổng quan',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // Registration Stats
          registrationsAsync.when(
            data: (data) {
              final registrations = List<Map<String, dynamic>>.from(data['registrations'] ?? []);
              final periodRegistrations = _filterByPeriod(registrations);
              
              return Column(
                children: [
                  _StatCard(
                    title: 'Hoạt động đã đăng ký',
                    value: periodRegistrations.length.toString(),
                    icon: Icons.event_note,
                    color: Colors.blue,
                    subtitle: 'Trong kỳ này',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Tổng hoạt động đã đăng ký',
                    value: registrations.length.toString(),
                    icon: Icons.event_available,
                    color: Colors.purple,
                    subtitle: 'Tất cả thời gian',
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Lỗi tải đăng ký: $e')),
          ),
          
          const SizedBox(height: 16),
          
          // Attendance Stats
          attendancesAsync.when(
            data: (data) {
              final attendances = List<Map<String, dynamic>>.from(data['attendances'] ?? []);
              final periodAttendances = _filterByPeriod(attendances);
              final totalPoints = periodAttendances.fold<int>(0, (sum, item) => sum + (item['points'] as int? ?? 0));
              
              return Column(
                children: [
                  _StatCard(
                    title: 'Hoạt động đã tham gia',
                    value: periodAttendances.length.toString(),
                    icon: Icons.check_circle,
                    color: kGreen,
                    subtitle: 'Trong kỳ này',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Điểm rèn luyện',
                    value: totalPoints.toString(),
                    icon: Icons.star,
                    color: Colors.amber,
                    subtitle: 'Điểm trong kỳ',
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Lỗi tải điểm danh: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Xu hướng tham gia',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // Weekly Activity Chart
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hoạt động theo tuần',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildWeeklyChart(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Monthly Activity Chart
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hoạt động theo tháng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMonthlyChart(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    final registrationsAsync = ref.watch(myRegistrationsProvider);
    final attendancesAsync = ref.watch(myAttendancesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết hoạt động',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          
          // Registered Activities
          registrationsAsync.when(
            data: (data) {
              final registrations = List<Map<String, dynamic>>.from(data['registrations'] ?? []);
              final periodRegistrations = _filterByPeriod(registrations);
              
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hoạt động đã đăng ký trong kỳ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (periodRegistrations.isEmpty)
                        const Center(
                          child: Text(
                            'Không có hoạt động nào trong kỳ này',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: periodRegistrations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final r = periodRegistrations[i];
                            final a = Map<String, dynamic>.from(r['activity'] ?? {});
                            return _ActivityDetailItem(
                              activity: a,
                              status: 'Đã đăng ký',
                              icon: Icons.event_note,
                              iconColor: Colors.blue,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Lỗi tải đăng ký: $e')),
          ),
          
          const SizedBox(height: 16),
          
          // Attended Activities
          attendancesAsync.when(
            data: (data) {
              final attendances = List<Map<String, dynamic>>.from(data['attendances'] ?? []);
              final periodAttendances = _filterByPeriod(attendances);
              
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hoạt động đã tham gia trong kỳ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (periodAttendances.isEmpty)
                        const Center(
                          child: Text(
                            'Không có hoạt động nào trong kỳ này',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: periodAttendances.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final it = periodAttendances[i];
                            final a = Map<String, dynamic>.from(it['activity'] ?? {});
                            final points = it['points'] ?? 0;
                            return _ActivityDetailItem(
                              activity: a,
                              status: 'Điểm: $points',
                              icon: Icons.check_circle,
                              iconColor: kGreen,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Lỗi tải điểm danh: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    // Mock data for weekly chart
    final weeklyData = [
      {'week': 'Tuần 1', 'activities': 2},
      {'week': 'Tuần 2', 'activities': 3},
      {'week': 'Tuần 3', 'activities': 1},
      {'week': 'Tuần 4', 'activities': 4},
    ];

    return Container(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weeklyData.map((data) {
                final height = (data['activities'] as int) * 20.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 30,
                      height: height,
                      decoration: BoxDecoration(
                        color: kGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['week'].toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      data['activities'].toString(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyChart() {
    // Mock data for monthly chart
    final monthlyData = [
      {'month': 'T1', 'activities': 5},
      {'month': 'T2', 'activities': 8},
      {'month': 'T3', 'activities': 6},
      {'month': 'T4', 'activities': 10},
    ];

    return Container(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: monthlyData.map((data) {
                final height = (data['activities'] as int) * 15.0;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 40,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['month'].toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      data['activities'].toString(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showPeriodSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chọn kỳ báo cáo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tuần này'),
              leading: Radio<String>(
                value: 'week',
                groupValue: _selectedPeriodType,
                onChanged: (value) => setState(() => _selectedPeriodType = value!),
              ),
            ),
            ListTile(
              title: const Text('Tháng này'),
              leading: Radio<String>(
                value: 'month',
                groupValue: _selectedPeriodType,
                onChanged: (value) => setState(() => _selectedPeriodType = value!),
              ),
            ),
            ListTile(
              title: const Text('Năm này'),
              leading: Radio<String>(
                value: 'year',
                groupValue: _selectedPeriodType,
                onChanged: (value) => setState(() => _selectedPeriodType = value!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  String _getPeriodText() {
    final now = DateTime.now();
    switch (_selectedPeriodType) {
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('dd/MM').format(startOfWeek)} - ${DateFormat('dd/MM/yyyy').format(endOfWeek)}';
      case 'month':
        return DateFormat('MM/yyyy').format(now);
      case 'year':
        return 'Năm ${now.year}';
      default:
        return 'Tháng hiện tại';
    }
  }

  List<Map<String, dynamic>> _filterByPeriod(List<Map<String, dynamic>> data) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_selectedPeriodType) {
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31);
        break;
      default:
        return data;
    }

    return data.where((item) {
      final createdAt = DateTime.tryParse(item['created_at']?.toString() ?? '');
      if (createdAt == null) return false;
      return createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
             createdAt.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityDetailItem extends StatelessWidget {
  const _ActivityDetailItem({
    required this.activity,
    required this.status,
    required this.icon,
    required this.iconColor,
  });

  final Map<String, dynamic> activity;
  final String status;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final name = activity['name'] ?? 'Hoạt động';
    final startTime = DateTime.tryParse(activity['start_time']?.toString() ?? '');
    final endTime = DateTime.tryParse(activity['end_time']?.toString() ?? '');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => context.push('/student/activity/${activity['id']}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Thời gian: ${_formatDateTime(startTime, endTime)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Trạng thái: $status',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? start, DateTime? end) {
    if (start == null) return 'N/A';
    final localStart = start.toLocal();
    String formatted = '${localStart.day}/${localStart.month}/${localStart.year} ${localStart.hour.toString().padLeft(2, '0')}:${localStart.minute.toString().padLeft(2, '0')}';
    if (end != null) {
      final localEnd = end.toLocal();
      formatted += ' - ${localEnd.hour.toString().padLeft(2, '0')}:${localEnd.minute.toString().padLeft(2, '0')}';
    }
    return formatted;
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
