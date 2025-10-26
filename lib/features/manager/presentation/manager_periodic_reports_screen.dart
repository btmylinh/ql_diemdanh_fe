import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../theme.dart';
import '../data/activities_providers.dart';
import '../data/activities_repository.dart';

class ManagerPeriodicReportsScreen extends ConsumerStatefulWidget {
  const ManagerPeriodicReportsScreen({super.key});

  @override
  ConsumerState<ManagerPeriodicReportsScreen> createState() => _ManagerPeriodicReportsScreenState();
}

class _ManagerPeriodicReportsScreenState extends ConsumerState<ManagerPeriodicReportsScreen>
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
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        title: const Text(
          'Báo cáo định kỳ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showPeriodSelector,
            tooltip: 'Chọn kỳ báo cáo',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tổng quan'),
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
    );
  }

  Widget _buildOverviewTab() {
    final activitiesAsync = ref.watch(myActivitiesProvider((page: 1, limit: 100, q: null, status: null)));

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
                colors: [kBlue.withValues(alpha: 0.6), kBlue.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kBlue.withOpacity(0.3),
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
                  'Thống kê hoạt động quản lý',
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
          
          activitiesAsync.when(
            data: (data) {
              final activities = List<Map<String, dynamic>>.from(data['activities'] ?? []);
              final periodActivities = _filterByPeriod(activities);
              
              return Column(
                children: [
                  _StatCard(
                    title: 'Hoạt động trong kỳ',
                    value: periodActivities.length.toString(),
                    icon: Icons.event,
                    color: kBlue,
                    subtitle: 'Được tạo trong kỳ này',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Tổng hoạt động',
                    value: activities.length.toString(),
                    icon: Icons.event_available,
                    color: Colors.purple,
                    subtitle: 'Tất cả thời gian',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Hoạt động đang diễn ra',
                    value: _getActiveActivitiesCount(periodActivities).toString(),
                    icon: Icons.play_circle,
                    color: kGreen,
                    subtitle: 'Trong kỳ này',
                  ),
                  const SizedBox(height: 12),
                  _StatCard(
                    title: 'Hoạt động đã hoàn thành',
                    value: _getCompletedActivitiesCount(periodActivities).toString(),
                    icon: Icons.check_circle,
                    color: Colors.orange,
                    subtitle: 'Trong kỳ này',
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Lỗi tải hoạt động: $e')),
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
            'Xu hướng hoạt động',
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
    final activitiesAsync = ref.watch(myActivitiesProvider((page: 1, limit: 100, q: null, status: null)));

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
          
          activitiesAsync.when(
            data: (data) {
              final activities = List<Map<String, dynamic>>.from(data['activities'] ?? []);
              final periodActivities = _filterByPeriod(activities);
              
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hoạt động trong kỳ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (periodActivities.isEmpty)
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
                          itemCount: periodActivities.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final activity = periodActivities[i];
                            return _ActivityDetailItem(
                              activity: activity,
                            );
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Lỗi tải hoạt động: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    // Mock data for weekly chart
    final weeklyData = [
      {'week': 'Tuần 1', 'activities': 1},
      {'week': 'Tuần 2', 'activities': 2},
      {'week': 'Tuần 3', 'activities': 0},
      {'week': 'Tuần 4', 'activities': 3},
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
                        color: kBlue,
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
      {'month': 'T1', 'activities': 2},
      {'month': 'T2', 'activities': 4},
      {'month': 'T3', 'activities': 3},
      {'month': 'T4', 'activities': 6},
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
                        color: kGreen,
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

  int _getActiveActivitiesCount(List<Map<String, dynamic>> activities) {
    final now = DateTime.now();
    return activities.where((activity) {
      final status = activity['status'] as int?;
      final startTime = DateTime.tryParse(activity['start_time']?.toString() ?? '');
      final endTime = DateTime.tryParse(activity['end_time']?.toString() ?? '');
      
      if (status == null || startTime == null || endTime == null) return false;
      
      return status == 2 && now.isAfter(startTime) && now.isBefore(endTime);
    }).length;
  }

  int _getCompletedActivitiesCount(List<Map<String, dynamic>> activities) {
    return activities.where((activity) {
      final status = activity['status'] as int?;
      return status == 3; // Completed status
    }).length;
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
  });

  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final name = activity['name'] ?? 'Hoạt động';
    final startTime = DateTime.tryParse(activity['start_time']?.toString() ?? '');
    final endTime = DateTime.tryParse(activity['end_time']?.toString() ?? '');
    final status = activity['status'] as int?;
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => context.push('/manager/activity/${activity['id']}'),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                    Row(
                      children: [
                        Text(
                          'Trạng thái: ',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
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

  String _getStatusText(int? status) {
    switch (status) {
      case 1: return 'Chưa bắt đầu';
      case 2: return 'Đang diễn ra';
      case 3: return 'Đã hoàn thành';
      case 4: return 'Đã hủy';
      default: return 'Không xác định';
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 1: return Colors.blue;
      case 2: return kGreen;
      case 3: return Colors.orange;
      case 4: return Colors.red;
      default: return Colors.grey;
    }
  }
}
