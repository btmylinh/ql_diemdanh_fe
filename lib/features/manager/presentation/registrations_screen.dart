import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_saver/file_saver.dart';
import '../../../theme.dart';
import '../data/registrations_providers.dart';

class RegistrationsScreen extends ConsumerStatefulWidget {
  const RegistrationsScreen({super.key});

  @override
  ConsumerState<RegistrationsScreen> createState() => _RegistrationsScreenState();
}

class _RegistrationsScreenState extends ConsumerState<RegistrationsScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load registrations once when the screen is first built
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadRegistrations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRegistrations() {
    final activityId = int.tryParse(GoRouterState.of(context).pathParameters['id'] ?? '0') ?? 0;
    ref.invalidate(activityRegistrationsProvider({
      'activityId': activityId,
      'page': _currentPage,
      'limit': _pageSize,
      'search': _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      'status': _statusFilter,
    }));
  }

  @override
  Widget build(BuildContext context) {
    final activityId = int.tryParse(GoRouterState.of(context).pathParameters['id'] ?? '0') ?? 0;
    final registrationsAsync = ref.watch(activityRegistrationsProvider({
      'activityId': activityId,
      'page': _currentPage,
      'limit': _pageSize,
      'search': _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      'status': _statusFilter,
    }));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        title: const Text('Quản lý đăng ký'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportToCSV(activityId),
            tooltip: 'Xuất CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegistrations,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Tìm kiếm theo tên, email, MSSV...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _loadRegistrations(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  hint: const Text('Trạng thái'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả')),
                    DropdownMenuItem(value: '1', child: Text('Đã đăng ký')),
                    DropdownMenuItem(value: '0', child: Text('Đã hủy')),
                  ],
                  onChanged: (value) {
                    setState(() => _statusFilter = value);
                    _loadRegistrations();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadRegistrations,
                  icon: const Icon(Icons.search),
                  label: const Text('Tìm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Registrations Table
          Expanded(
            child: registrationsAsync.when(
              data: (data) => _buildRegistrationsTable(data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationsTable(Map<String, dynamic> data) {
    final registrations = data['registrations'] as List<dynamic>? ?? [];
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
    // final total = pagination['total'] as int? ?? 0; // TODO: Use for statistics display
    final totalPages = pagination['totalPages'] as int? ?? 1;

    if (registrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có đăng ký nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa có ai đăng ký tham gia hoạt động này',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.grey[100],
          child: Row(
            children: [
              Checkbox(
                value: false, // TODO: Implement select all
                onChanged: (value) {
                  // TODO: Implement select all
                },
              ),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('MSSV', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Lớp', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Ngày đăng ký', style: TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 40), // Actions column
            ],
          ),
        ),
        
        // Table Body
        Expanded(
          child: ListView.builder(
            itemCount: registrations.length,
            itemBuilder: (context, index) {
              final registration = registrations[index] as Map<String, dynamic>;
              return _buildRegistrationRow(registration);
            },
          ),
        ),
        
        // Pagination
        if (totalPages > 1) _buildPagination(totalPages),
      ],
    );
  }

  Widget _buildRegistrationRow(Map<String, dynamic> registration) {
    final user = registration['user'] as Map<String, dynamic>? ?? {};
    final status = registration['status'] as String? ?? '0';
    final createdAt = registration['created_at'] as String? ?? '';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: false, // TODO: Implement selection
            onChanged: (value) {
              // TODO: Implement selection
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              user['name'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user['email'] ?? 'N/A',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              user['mssv'] ?? 'N/A',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              user['class'] ?? 'N/A',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 1,
            child: _buildStatusChip(status),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _formatDate(createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleRegistrationAction(value, registration),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'approve',
                child: Row(
                  children: [
                    Icon(Icons.check, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Duyệt'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reject',
                child: Row(
                  children: [
                    Icon(Icons.close, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Từ chối'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    switch (status) {
      case '1':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'Đã đăng ký',
            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        );
      case '0':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'Đã hủy',
            style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'Không xác định',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        );
    }
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1 ? () {
              setState(() => _currentPage--);
              _loadRegistrations();
            } : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Trang $_currentPage / $totalPages'),
          IconButton(
            onPressed: _currentPage < totalPages ? () {
              setState(() => _currentPage++);
              _loadRegistrations();
            } : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Lỗi tải dữ liệu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadRegistrations,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _handleRegistrationAction(String action, Map<String, dynamic> registration) {
    final registrationId = registration['id'] as int? ?? 0;
    
    switch (action) {
      case 'approve':
        _updateRegistrationStatus(registrationId, '1');
        break;
      case 'reject':
        _updateRegistrationStatus(registrationId, '0');
        break;
      case 'delete':
        _deleteRegistration(registrationId);
        break;
    }
  }

  void _updateRegistrationStatus(int registrationId, String status) {
    ref.read(registrationManagementProvider.notifier).updateRegistrationStatus(registrationId, status);
    _loadRegistrations();
  }

  void _deleteRegistration(int registrationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa đăng ký này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(registrationManagementProvider.notifier).deleteRegistration(registrationId);
              _loadRegistrations();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV(int activityId) async {
    try {
      final csvData = await ref.read(registrationManagementProvider.notifier).exportRegistrationsToCSV(activityId);
      if (csvData != null) {
        // Save file using file_saver
        await FileSaver.instance.saveAs(
          name: 'registrations_${DateTime.now().millisecondsSinceEpoch}.csv',
          bytes: Uint8List.fromList(csvData),
          ext: 'csv',
          mimeType: MimeType.csv,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xuất CSV thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất CSV: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}