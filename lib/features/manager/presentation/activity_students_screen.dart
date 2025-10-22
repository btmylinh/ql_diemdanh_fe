import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';
import '../data/registrations_providers.dart';

class ActivityStudentsScreen extends ConsumerStatefulWidget {
  const ActivityStudentsScreen({super.key});

  @override
  ConsumerState<ActivityStudentsScreen> createState() => _ActivityStudentsScreenState();
}

class _ActivityStudentsScreenState extends ConsumerState<ActivityStudentsScreen> {
  int? _activityId;
  String _activityName = '';
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_activityId == null) {
      final pathParams = GoRouterState.of(context).pathParameters;
      _activityId = int.tryParse(pathParams['id'] ?? '0');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activityId == null || _activityId == 0) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          title: const Text('Lỗi'),
        ),
        body: const Center(
          child: Text('Không tìm thấy hoạt động'),
        ),
      );
    }

    final registrationsAsync = ref.watch(activityRegistrationsProvider((
      activityId: _activityId!,
      page: 1,
      limit: 100,
      search: _searchQuery,
      status: '1', // Chỉ hiển thị đăng ký đã duyệt
    )));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        title: Text('Danh sách sinh viên - $_activityName'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog();
            },
            tooltip: 'Tìm kiếm',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = null;
              });
              ref.invalidate(activityRegistrationsProvider((
                activityId: _activityId!,
                page: 1,
                limit: 100,
                search: null,
                status: '1',
              )));
            },
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body: registrationsAsync.when(
        data: (data) => _buildStudentsList(data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error.toString()),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tìm kiếm sinh viên'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Nhập tên, MSSV hoặc email...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text.trim().isEmpty 
                  ? null 
                  : _searchController.text.trim();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(Map<String, dynamic> data) {
    final registrations = data['registrations'] as List<dynamic>? ?? [];
    final activity = data['activity'] as Map<String, dynamic>? ?? {};
    
    // Cập nhật tên hoạt động nếu có
    if (activity['name'] != null && _activityName.isEmpty) {
      setState(() {
        _activityName = activity['name'] as String;
      });
    }
    
    if (registrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có sinh viên nào đăng ký',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sinh viên sẽ xuất hiện ở đây khi đăng ký tham gia hoạt động',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with stats
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: kBlue, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Tổng số sinh viên: ${registrations.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_searchQuery != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 16, color: kBlue),
                      const SizedBox(width: 4),
                      Text(
                        'Tìm kiếm: "$_searchQuery"',
                        style: TextStyle(
                          color: kBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = null;
                          });
                        },
                        child: Icon(Icons.close, size: 16, color: kBlue),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Students List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: registrations.length,
            itemBuilder: (context, index) {
              final registration = registrations[index] as Map<String, dynamic>;
              final user = registration['user'] as Map<String, dynamic>? ?? {};
              
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  // Compact avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: kBlue.withOpacity(0.1),
                    child: Text(
                      (user['mssv'] as String? ?? 'N/A').substring(0, 2).toUpperCase(),
                      style: TextStyle(
                        color: kBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Compact info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] as String? ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'MSSV: ${user['mssv'] ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            if (user['class'] != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '• Lớp: ${user['class']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Compact status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Đã đăng ký',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
            },
          ),
        ),
      ],
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
            onPressed: () {
              ref.invalidate(activityRegistrationsProvider((
                activityId: _activityId!,
                page: 1,
                limit: 100,
                search: null,
                status: '1',
              )));
            },
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
}
