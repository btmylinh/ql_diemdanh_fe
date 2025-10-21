import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme.dart';
import '../data/registrations_providers.dart';
import '../../auth/user_provider.dart';

class BatchRegistrationsScreen extends ConsumerStatefulWidget {
  const BatchRegistrationsScreen({super.key});

  @override
  ConsumerState<BatchRegistrationsScreen> createState() => _BatchRegistrationsScreenState();
}

class _BatchRegistrationsScreenState extends ConsumerState<BatchRegistrationsScreen> {
  final _searchController = TextEditingController();
  String? _statusFilter;
  int _currentPage = 1;
  final int _pageSize = 20;
  final Set<int> _selectedRegistrations = {};
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
    print('[BATCH_REGISTRATIONS] Loading registrations with params: page=$_currentPage, limit=$_pageSize, search=${_searchController.text.trim()}, status=$_statusFilter');
    ref.invalidate(allRegistrationsProvider({
      'page': _currentPage,
      'limit': _pageSize,
      'search': _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      'status': _statusFilter,
    }));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    // Remove debug print to avoid infinite loop
    
    final registrationsAsync = ref.watch(allRegistrationsProvider({
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
        title: Text('Quản lý hàng loạt (${_selectedRegistrations.length} đã chọn)'),
        elevation: 0,
        actions: [
          if (_selectedRegistrations.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () => _showBatchActionDialog('approve'),
              tooltip: 'Duyệt hàng loạt',
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => _showBatchActionDialog('reject'),
              tooltip: 'Từ chối hàng loạt',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showBatchActionDialog('delete'),
              tooltip: 'Xóa hàng loạt',
            ),
          ],
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
          
          // Batch Actions Bar
          if (_selectedRegistrations.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedRegistrations.length} đăng ký đã được chọn',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedRegistrations.clear());
                    },
                    child: const Text('Bỏ chọn tất cả'),
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
    print('[BATCH_REGISTRATIONS] Building registrations table with data: ${data.keys}');
    final registrations = data['registrations'] as List<dynamic>? ?? [];
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
    final totalPages = pagination['totalPages'] as int? ?? 1;
    
    print('[BATCH_REGISTRATIONS] Registrations count: ${registrations.length}');
    print('[BATCH_REGISTRATIONS] Pagination: $pagination');

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
              'Chưa có ai đăng ký tham gia hoạt động',
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
                value: _selectedRegistrations.length == registrations.length && registrations.isNotEmpty,
                tristate: true,
                onChanged: (value) {
                  if (value == true) {
                    setState(() {
                      _selectedRegistrations.clear();
                      for (final registration in registrations) {
                        _selectedRegistrations.add(registration['id'] as int);
                      }
                    });
                  } else {
                    setState(() => _selectedRegistrations.clear());
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('MSSV', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Hoạt động', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Ngày đăng ký', style: TextStyle(fontWeight: FontWeight.bold))),
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
    final activity = registration['activity'] as Map<String, dynamic>? ?? {};
    final status = registration['status'] as String? ?? '0';
    final createdAt = registration['created_at'] as String? ?? '';
    final registrationId = registration['id'] as int? ?? 0;
    final isSelected = _selectedRegistrations.contains(registrationId);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.withValues(alpha: 0.05) : null,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _selectedRegistrations.add(registrationId);
                } else {
                  _selectedRegistrations.remove(registrationId);
                }
              });
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
              activity['name'] ?? 'N/A',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              overflow: TextOverflow.ellipsis,
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

  void _showBatchActionDialog(String action) {
    if (_selectedRegistrations.isEmpty) return;

    String title;
    String content;
    String confirmText;
    Color confirmColor;

    switch (action) {
      case 'approve':
        title = 'Duyệt hàng loạt';
        content = 'Bạn có chắc chắn muốn duyệt ${_selectedRegistrations.length} đăng ký đã chọn?';
        confirmText = 'Duyệt';
        confirmColor = Colors.green;
        break;
      case 'reject':
        title = 'Từ chối hàng loạt';
        content = 'Bạn có chắc chắn muốn từ chối ${_selectedRegistrations.length} đăng ký đã chọn?';
        confirmText = 'Từ chối';
        confirmColor = Colors.orange;
        break;
      case 'delete':
        title = 'Xóa hàng loạt';
        content = 'Bạn có chắc chắn muốn xóa ${_selectedRegistrations.length} đăng ký đã chọn? Hành động này không thể hoàn tác.';
        confirmText = 'Xóa';
        confirmColor = Colors.red;
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performBatchAction(action);
            },
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _performBatchAction(String action) {
    final notifier = ref.read(registrationManagementProvider.notifier);
    
    switch (action) {
      case 'approve':
        notifier.batchUpdateRegistrationStatuses('1');
        break;
      case 'reject':
        notifier.batchUpdateRegistrationStatuses('0');
        break;
      case 'delete':
        notifier.batchDeleteRegistrations();
        break;
    }
    
    setState(() => _selectedRegistrations.clear());
    _loadRegistrations();
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
