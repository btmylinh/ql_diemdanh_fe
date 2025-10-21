import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';
import '../data/activities_providers.dart';
import '../../auth/user_provider.dart';

class ActivitiesListScreen extends ConsumerStatefulWidget {
  const ActivitiesListScreen({super.key});

  @override
  ConsumerState<ActivitiesListScreen> createState() => _ActivitiesListScreenState();
}

class _ActivitiesListScreenState extends ConsumerState<ActivitiesListScreen> {
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
    // Only load activities once when the screen is first built
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadActivities();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadActivities() {
    print('[ACTIVITIES_LIST] Loading activities with params: page=$_currentPage, limit=$_pageSize, search=${_searchController.text.trim()}, status=$_statusFilter');
    ref.invalidate(myActivitiesProvider({
      'page': _currentPage,
      'limit': _pageSize,
      'q': _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      'status': _statusFilter != null ? int.tryParse(_statusFilter!) : null,
    }));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    
    // Use a fixed key to avoid infinite rebuilds
    final activitiesAsync = ref.watch(myActivitiesProvider({
      'page': _currentPage,
      'limit': _pageSize,
      'q': _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      'status': _statusFilter != null ? int.tryParse(_statusFilter!) : null,
    }));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        title: const Text('Hoạt động của tôi'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/manager/activity/new'),
            tooltip: 'Tạo hoạt động mới',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
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
                      hintText: 'Tìm kiếm theo tên hoạt động...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _loadActivities(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _statusFilter,
                  hint: const Text('Trạng thái'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả')),
                    DropdownMenuItem(value: '1', child: Text('Đang diễn ra')),
                    DropdownMenuItem(value: '2', child: Text('Sắp diễn ra')),
                    DropdownMenuItem(value: '3', child: Text('Đã hoàn thành')),
                    DropdownMenuItem(value: '0', child: Text('Đã hủy')),
                  ],
                  onChanged: (value) {
                    setState(() => _statusFilter = value);
                    _loadActivities();
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadActivities,
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
          
          // Activities List
          Expanded(
            child: activitiesAsync.when(
              data: (data) => _buildActivitiesList(data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorWidget(error.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/manager/activity/new'),
        backgroundColor: kBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActivitiesList(Map<String, dynamic> data) {
    print('[ACTIVITIES_LIST] Building activities list with data: ${data.keys}');
    final activities = data['activities'] as List<dynamic>? ?? [];
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
    final totalPages = pagination['totalPages'] as int? ?? 1;
    
    print('[ACTIVITIES_LIST] Activities count: ${activities.length}');
    print('[ACTIVITIES_LIST] Pagination: $pagination');

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có hoạt động nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tạo hoạt động đầu tiên của bạn',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/manager/activity/new'),
              icon: const Icon(Icons.add),
              label: const Text('Tạo hoạt động'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Activities List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index] as Map<String, dynamic>;
              return _buildActivityCard(activity);
            },
          ),
        ),
        
        // Pagination
        if (totalPages > 1) _buildPagination(totalPages),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final id = activity['id'] as int? ?? 0;
    final name = activity['name'] as String? ?? 'N/A';
    final description = activity['description'] as String? ?? '';
    final location = activity['location'] as String? ?? '';
    final startTime = activity['start_time'] as String? ?? '';
    // final endTime = activity['end_time'] as String? ?? ''; // TODO: Use for duration display
    final status = activity['status'] as int? ?? 0;
    final registeredCount = activity['registered_count'] as int? ?? 0;
    final maxParticipants = activity['max_participants'] as int?;
    final trainingPoints = activity['training_points'] as int? ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/manager/activity/$id/edit'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              
              if (description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Details
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location.isNotEmpty ? location : 'Chưa có địa điểm',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(startTime),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    maxParticipants != null 
                      ? '$registeredCount/$maxParticipants người đăng ký'
                      : '$registeredCount người đăng ký',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              
              if (trainingPoints > 0) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$trainingPoints điểm rèn luyện',
                      style: TextStyle(color: Colors.amber[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/manager/activity/$id/registrations'),
                      icon: const Icon(Icons.people, size: 16),
                      label: const Text('Đăng ký'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kBlue,
                        side: BorderSide(color: kBlue),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/manager/activity/$id/attendance'),
                      icon: const Icon(Icons.qr_code_scanner, size: 16),
                      label: const Text('Điểm danh'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(int status) {
    switch (status) {
      case 1:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'Đang diễn ra',
            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        );
      case 2:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'Sắp diễn ra',
            style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        );
      case 3:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: const Text(
            'Đã hoàn thành',
            style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        );
      case 0:
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
              _loadActivities();
            } : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Trang $_currentPage / $totalPages'),
          IconButton(
            onPressed: _currentPage < totalPages ? () {
              setState(() => _currentPage++);
              _loadActivities();
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
            onPressed: _loadActivities,
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

  String _formatDateTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }
}
