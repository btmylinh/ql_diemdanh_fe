import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../theme.dart';
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
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showPeriodicReportsDialog(context),
            tooltip: 'Báo cáo định kỳ',
          ),
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

  void _showPeriodicReportsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Báo cáo định kỳ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn loại báo cáo định kỳ:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_view_week, color: Colors.blue),
              title: const Text('Báo cáo tuần'),
              subtitle: const Text('Thống kê hoạt động theo tuần'),
              onTap: () {
                Navigator.pop(context);
                _showPeriodicReportDetails('weekly');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_view_month, color: Colors.green),
              title: const Text('Báo cáo tháng'),
              subtitle: const Text('Thống kê hoạt động theo tháng'),
              onTap: () {
                Navigator.pop(context);
                _showPeriodicReportDetails('monthly');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.orange),
              title: const Text('Báo cáo năm'),
              subtitle: const Text('Thống kê hoạt động theo năm'),
              onTap: () {
                Navigator.pop(context);
                _showPeriodicReportDetails('yearly');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.purple),
              title: const Text('Cài đặt tự động'),
              subtitle: const Text('Cấu hình tạo báo cáo tự động'),
              onTap: () {
                Navigator.pop(context);
                _showAutoReportSettings(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showPeriodicReportDetails(String period) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Báo cáo ${_getPeriodTitle(period)}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thống kê ${_getPeriodTitle(period).toLowerCase()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildPeriodicReportContent(period),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () => _exportPeriodicReport(period),
            child: const Text('Xuất báo cáo'),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodicReportContent(String period) {
    // Mock data - trong thực tế sẽ lấy từ provider
    final mockData = _getMockPeriodicData(period);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Tổng hoạt động',
                  '${mockData['total_activities']}',
                  Icons.event,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Đăng ký',
                  '${mockData['total_registrations']}',
                  Icons.app_registration,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Điểm danh',
                  '${mockData['total_attendances']}',
                  Icons.check_circle,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryCard(
                  'Điểm rèn luyện',
                  '${mockData['total_points']}',
                  Icons.star,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Trends Chart
          Text(
            'Xu hướng',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Biểu đồ xu hướng ${_getPeriodTitle(period).toLowerCase()}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoReportSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cài đặt báo cáo tự động'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Tự động tạo báo cáo tuần'),
              subtitle: const Text('Tạo báo cáo vào cuối mỗi tuần'),
              value: true,
              onChanged: (value) {
                // TODO: Implement auto report settings
              },
            ),
            SwitchListTile(
              title: const Text('Tự động tạo báo cáo tháng'),
              subtitle: const Text('Tạo báo cáo vào cuối mỗi tháng'),
              value: true,
              onChanged: (value) {
                // TODO: Implement auto report settings
              },
            ),
            SwitchListTile(
              title: const Text('Tự động tạo báo cáo năm'),
              subtitle: const Text('Tạo báo cáo vào cuối mỗi năm'),
              value: false,
              onChanged: (value) {
                // TODO: Implement auto report settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Gửi báo cáo qua email'),
              subtitle: const Text('Tự động gửi báo cáo cho quản trị viên'),
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Implement email settings
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Save settings
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  String _getPeriodTitle(String period) {
    switch (period) {
      case 'weekly': return 'Tuần';
      case 'monthly': return 'Tháng';
      case 'yearly': return 'Năm';
      default: return 'Kỳ';
    }
  }

  Map<String, dynamic> _getMockPeriodicData(String period) {
    switch (period) {
      case 'weekly':
        return {
          'total_activities': 15,
          'total_registrations': 120,
          'total_attendances': 95,
          'total_points': 285,
        };
      case 'monthly':
        return {
          'total_activities': 65,
          'total_registrations': 520,
          'total_attendances': 410,
          'total_points': 1230,
        };
      case 'yearly':
        return {
          'total_activities': 780,
          'total_registrations': 6240,
          'total_attendances': 4920,
          'total_points': 14760,
        };
      default:
        return {
          'total_activities': 0,
          'total_registrations': 0,
          'total_attendances': 0,
          'total_points': 0,
        };
    }
  }

  void _exportPeriodicReport(String period) {
    // TODO: Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang xuất báo cáo ${_getPeriodTitle(period).toLowerCase()}...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
