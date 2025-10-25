import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/reports_provider.dart';
import 'widgets/chart_widgets.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.timeline), text: 'Hoạt động'),
            Tab(icon: Icon(Icons.people), text: 'Người dùng'),
            Tab(icon: Icon(Icons.check_circle), text: 'Điểm danh'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(dashboardStatsAsync),
              _buildActivitiesTab(),
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
    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range display
            if (_startDate != null || _endDate != null)
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
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                          ref.read(reportsStateProvider.notifier).setDateRange(null, null);
                        },
                        child: const Text('Xóa bộ lọc'),
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

  Widget _buildActivitiesTab() {
    return Consumer(
      builder: (context, ref, child) {
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thống kê hoạt động theo thời gian',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xu hướng đăng ký theo thời gian',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ref.watch(registrationsTrendProvider((start: _startDate, end: _endDate))).when(
                        data: (data) => RegistrationsTrendChart(data: data),
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
              ElevatedButton.icon(
                onPressed: () => _generateReport('activities'),
                icon: const Icon(Icons.description),
                label: const Text('Tạo báo cáo chi tiết'),
              ),
            ],
          ),
        );
      },
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _generateReport('users'),
            icon: const Icon(Icons.description),
            label: const Text('Tạo báo cáo chi tiết'),
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
              final activitiesByStatusAsync = ref.watch(activitiesByStatusProvider);
              return activitiesByStatusAsync.when(
                data: (data) => Card(
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
                        ActivitiesStatusPieChart(data: data),
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
          ElevatedButton.icon(
            onPressed: () => _generateReport('attendances'),
            icon: const Icon(Icons.description),
            label: const Text('Tạo báo cáo chi tiết'),
          ),
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

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xuất báo cáo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn loại báo cáo cần xuất:'),
            const SizedBox(height: 16),
            ...['activities', 'users', 'attendances', 'registrations'].map((type) =>
              ListTile(
                leading: Icon(_getReportIcon(type)),
                title: Text(_getReportTitle(type)),
                onTap: () {
                  Navigator.pop(context);
                  _exportReport(type);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
        ],
      ),
    );
  }

  void _generateReport(String reportType) {
    ref.read(reportsStateProvider.notifier).generateReport(
      reportType: reportType,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _exportReport(String reportType) async {
    // First generate the report
    await ref.read(reportsStateProvider.notifier).generateReport(
      reportType: reportType,
      startDate: _startDate,
      endDate: _endDate,
    );

    // Then export to CSV
    final reportsState = ref.read(reportsStateProvider);
    if (reportsState.reportData != null) {
      final data = reportsState.reportData!['data'] as List<dynamic>? ?? [];
      final csvData = data.cast<Map<String, dynamic>>();
      
      await ref.read(reportsStateProvider.notifier).exportToCSV(
        reportType: reportType,
        data: csvData,
        startDate: _startDate,
        endDate: _endDate,
      );
    }
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

  IconData _getReportIcon(String type) {
    switch (type) {
      case 'activities': return Icons.event;
      case 'users': return Icons.people;
      case 'attendances': return Icons.check_circle;
      case 'registrations': return Icons.app_registration;
      default: return Icons.description;
    }
  }

  String _getReportTitle(String type) {
    switch (type) {
      case 'activities': return 'Báo cáo hoạt động';
      case 'users': return 'Báo cáo người dùng';
      case 'attendances': return 'Báo cáo điểm danh';
      case 'registrations': return 'Báo cáo đăng ký';
      default: return 'Báo cáo';
    }
  }
}
