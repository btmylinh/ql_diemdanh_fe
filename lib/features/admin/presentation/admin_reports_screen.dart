import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../theme.dart';
import '../data/reports_provider.dart';
import 'widgets/chart_widgets.dart';
import '../../manager/data/periodic_reports_provider.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPeriod; // 'weekly', 'monthly', 'yearly'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportsState = ref.watch(reportsStateProvider);
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);

    // Listen to reports state changes
    ref.listen<ReportsState>(reportsStateProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? ''),
            backgroundColor: next.isSuccess ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.analytics),
            tooltip: 'Chọn báo cáo định kỳ',
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                // Lưu lựa chọn định kỳ
                if (value == 'weekly') {
                  // Set date range for weekly
                  final now = DateTime.now();
                  _startDate = now.subtract(Duration(days: now.weekday - 1));
                  _endDate = _startDate!.add(const Duration(days: 6));
                } else if (value == 'monthly') {
                  // Set date range for monthly
                  final now = DateTime.now();
                  _startDate = DateTime(now.year, now.month, 1);
                  _endDate = DateTime(now.year, now.month + 1, 0);
                } else if (value == 'yearly') {
                  // Set date range for yearly
                  final now = DateTime.now();
                  _startDate = DateTime(now.year, 1, 1);
                  _endDate = DateTime(now.year, 12, 31);
                }
                
                // Update TabController length
                _tabController.dispose();
                if (_selectedPeriod != null) {
                  _tabController = TabController(length: 1, vsync: this);
                } else {
                  _tabController = TabController(length: 3, vsync: this);
                }
                
                // Update date range in provider
                ref.read(reportsStateProvider.notifier).setDateRange(_startDate, _endDate);
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'weekly',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_week, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Báo cáo tuần'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'monthly',
                child: Row(
                  children: [
                    Icon(Icons.calendar_view_month, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Báo cáo tháng'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'yearly',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Báo cáo năm'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Lọc dữ liệu',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: _selectedPeriod != null 
            ? const [
                Tab(icon: Icon(Icons.dashboard), text: 'Tổng quan'),
              ]
            : const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.people), text: 'Người dùng'),
            Tab(icon: Icon(Icons.check_circle), text: 'Điểm danh'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: _selectedPeriod != null
              ? [
                  _buildOverviewTab(dashboardStatsAsync),
                ]
              : [
                  _buildOverviewTab(dashboardStatsAsync),
                  _buildUsersTab(),
                  _buildAttendancesTab(),
                ],
          ),
          // Loading overlay
          if (reportsState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang xử lý...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AsyncValue<Map<String, dynamic>> statsAsync) {
    // Nếu có _selectedPeriod, gọi API periodic report
    if (_selectedPeriod != null && _startDate != null && _endDate != null) {
      final periodicReportAsync = ref.watch(periodicReportProvider({
        'period': _selectedPeriod!,
        'startDate': _startDate!,
        'endDate': _endDate!,
      }));
      
      return periodicReportAsync.when(
        data: (report) => _buildPeriodicReportView(report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Hiển thị báo cáo thường
    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selection display
            if (_selectedPeriod != null)
              Card(
                color: kBlue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        _selectedPeriod == 'weekly' 
                          ? Icons.calendar_view_week 
                          : _selectedPeriod == 'monthly' 
                            ? Icons.calendar_view_month 
                            : Icons.calendar_today,
                        color: kBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedPeriod == 'weekly'
                          ? 'Báo cáo tuần'
                          : _selectedPeriod == 'monthly'
                            ? 'Báo cáo tháng'
                            : 'Báo cáo năm',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: kBlue,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _tabController.dispose();
                            _tabController = TabController(length: 3, vsync: this);
                            _startDate = null;
                            _endDate = null;
                            _selectedPeriod = null;
                          });
                          ref.read(reportsStateProvider.notifier).setDateRange(null, null);
                        },
                        child: const Text('Xóa bộ lọc'),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Date range display
            if (_startDate != null && _endDate != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Khoảng thời gian: ${_formatDateRange()}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Stats cards
            Text(
              'Thống kê tổng quan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                StatsCard(
                  title: 'Tổng hoạt động',
                  value: '${stats['totalActivities'] ?? 0}',
                  icon: Icons.event,
                  color: Colors.blue,
                ),
                StatsCard(
                  title: 'Hoạt động đang diễn ra',
                  value: '${stats['activeActivities'] ?? 0}',
                  icon: Icons.play_circle,
                  color: Colors.green,
                ),
                StatsCard(
                  title: 'Tổng người dùng',
                  value: '${stats['totalUsers'] ?? 0}',
                  icon: Icons.people,
                  color: Colors.purple,
                ),
                StatsCard(
                  title: 'Tổng điểm danh',
                  value: '${stats['totalAttendances'] ?? 0}',
                  icon: Icons.check_circle,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Charts section
            Text(
              'Biểu đồ thống kê',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Attendance pie chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hoạt động theo trạng thái',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ref.watch(activitiesByStatusProvider).when(
                      data: (data) => ActivitiesStatusPieChart(data: data),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Lỗi: $error'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User role bar chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Top hoạt động được đăng ký nhiều nhất',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ref.watch(topActivitiesProvider(10)).when(
                      data: (data) => TopActivitiesBarChart(data: data),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Lỗi: $error'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Lỗi: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(dashboardStatsProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê người dùng',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final topActivitiesAsync = ref.watch(topActivitiesProvider(5));
              return topActivitiesAsync.when(
                data: (data) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Top 5 hoạt động phổ biến',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TopActivitiesBarChart(data: data),
                      ],
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Lỗi: $error'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAttendancesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thống kê điểm danh',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, child) {
              final registrationsTrendAsync = ref.watch(registrationsTrendProvider((start: _startDate, end: _endDate)));
              return registrationsTrendAsync.when(
                data: (data) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Xu hướng điểm danh theo thời gian',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        RegistrationsTrendChart(data: data),
                      ],
                    ),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('Lỗi: $error'),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bộ lọc thời gian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Từ ngày'),
              subtitle: Text(_startDate != null 
                ? DateFormat('dd/MM/yyyy').format(_startDate!)
                : 'Chọn ngày bắt đầu'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Đến ngày'),
              subtitle: Text(_endDate != null 
                ? DateFormat('dd/MM/yyyy').format(_endDate!)
                : 'Chọn ngày kết thúc'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _startDate = null;
                _endDate = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Xóa bộ lọc'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(reportsStateProvider.notifier).setDateRange(_startDate, _endDate);
              Navigator.pop(context);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }


  String _formatDateRange() {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
    } else if (_startDate != null) {
      return 'Từ ${DateFormat('dd/MM/yyyy').format(_startDate!)}';
    } else if (_endDate != null) {
      return 'Đến ${DateFormat('dd/MM/yyyy').format(_endDate!)}';
    }
    return 'Tất cả thời gian';
  }

  Widget _buildPeriodicReportView(Map<String, dynamic> report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          Card(
            color: kBlue.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPeriod == 'weekly' 
                      ? ' Báo cáo tuần'
                      : _selectedPeriod == 'monthly'
                        ? ' Báo cáo tháng' 
                        : ' Báo cáo năm',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Khoảng thời gian: ${_formatDateRange()}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              StatsCard(
                title: 'Hoạt động được tạo',
                value: '${report['activitiesCreated'] ?? 0}',
                icon: Icons.event,
                color: Colors.blue,
              ),
              StatsCard(
                title: 'Tổng hoạt động',
                value: '${report['totalActivities'] ?? 0}',
                icon: Icons.event_note,
                color: Colors.purple,
              ),
              StatsCard(
                title: 'Hoạt động đang diễn ra',
                value: '${report['activeActivities'] ?? 0}',
                icon: Icons.play_circle,
                color: Colors.green,
              ),
              StatsCard(
                title: 'Hoạt động hoàn thành',
                value: '${report['completedActivities'] ?? 0}',
                icon: Icons.check_circle,
                color: Colors.orange,
              ),
              StatsCard(
                title: 'Đăng ký mới',
                value: '${report['registrations'] ?? 0}',
                icon: Icons.person_add,
                color: Colors.blue,
              ),
              StatsCard(
                title: 'Điểm danh',
                value: '${report['attendances'] ?? 0}',
                icon: Icons.checklist,
                color: Colors.green,
              ),
              StatsCard(
                title: 'Người dùng mới',
                value: '${report['newUsers'] ?? 0}',
                icon: Icons.group_add,
                color: Colors.purple,
              ),
              StatsCard(
                title: 'Tổng người dùng',
                value: '${report['totalUsers'] ?? 0}',
                icon: Icons.people,
                color: Colors.indigo,
              ),
            ],
          ),
        ],
      ),
    );
  }

}
