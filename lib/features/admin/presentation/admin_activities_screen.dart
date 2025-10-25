import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/admin_activities_provider.dart';

class AdminActivitiesScreen extends ConsumerStatefulWidget {
  const AdminActivitiesScreen({super.key});

  @override
  ConsumerState<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends ConsumerState<AdminActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';
  Set<int> _selectedActivities = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminActivitiesProvider.notifier).loadActivities();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activitiesState = ref.watch(adminActivitiesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hoạt động'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          if (_selectedActivities.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showBulkDeleteDialog(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminActivitiesProvider.notifier).loadActivities();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm hoạt động...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          ref.read(adminActivitiesProvider.notifier).searchActivities(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                        DropdownMenuItem(value: '0', child: Text('Đang mở đăng ký')),
                        DropdownMenuItem(value: '1', child: Text('Đang diễn ra')),
                        DropdownMenuItem(value: '2', child: Text('Đã kết thúc')),
                        DropdownMenuItem(value: '3', child: Text('Đã hủy')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                        ref.read(adminActivitiesProvider.notifier).filterByStatus(value!);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: _sortBy,
                      items: const [
                        DropdownMenuItem(value: 'created_at', child: Text('Ngày tạo')),
                        DropdownMenuItem(value: 'start_time', child: Text('Thời gian bắt đầu')),
                        DropdownMenuItem(value: 'name', child: Text('Tên hoạt động')),
                        DropdownMenuItem(value: 'registered_count', child: Text('Số lượng đăng ký')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                        });
                        ref.read(adminActivitiesProvider.notifier).sortActivities(value!, _sortOrder);
                      },
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _sortOrder,
                      items: const [
                        DropdownMenuItem(value: 'desc', child: Text('Giảm dần')),
                        DropdownMenuItem(value: 'asc', child: Text('Tăng dần')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortOrder = value!;
                        });
                        ref.read(adminActivitiesProvider.notifier).sortActivities(_sortBy, value!);
                      },
                    ),
                    const Spacer(),
                    if (_selectedActivities.isNotEmpty)
                      Text('${_selectedActivities.length} đã chọn'),
                  ],
                ),
              ],
            ),
          ),
          // Activities list
          Expanded(
            child: activitiesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : activitiesState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Lỗi: ${activitiesState.error}',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(adminActivitiesProvider.notifier).loadActivities();
                              },
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : activitiesState.activities.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.event_busy, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Không có hoạt động nào',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: activitiesState.activities.length,
                            itemBuilder: (context, index) {
                              final activity = activitiesState.activities[index];
                              return _buildActivityCard(activity);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final isSelected = _selectedActivities.contains(activity['id']);
    final status = activity['status'] ?? 0;
    final statusInfo = _getStatusInfo(status);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedActivities.add(activity['id']);
            } else {
              _selectedActivities.remove(activity['id']);
            }
          });
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                activity['name'] ?? 'Không có tên',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusInfo['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusInfo['color']),
              ),
              child: Text(
                statusInfo['text'],
                style: TextStyle(
                  color: statusInfo['color'],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity['description'] != null)
              Text(
                activity['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(activity['location'] ?? 'Chưa có địa điểm'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(_formatDateTime(activity['start_time'])),
                const Text(' - '),
                Text(_formatDateTime(activity['end_time'])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${activity['registered_count'] ?? 0}/${activity['max_participants'] ?? '∞'} người'),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Tạo bởi: ${activity['creator']?['name'] ?? 'Unknown'}'),
              ],
            ),
          ],
        ),
        secondary: PopupMenuButton<String>(
          onSelected: (value) => _handleActivityAction(value, activity),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('Xem chi tiết'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'status',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 20),
                  const SizedBox(width: 8),
                  Text('Thay đổi trạng thái'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(int status) {
    switch (status) {
      case 0:
        return {'text': 'Mở đăng ký', 'color': Colors.blue};
      case 1:
        return {'text': 'Đang diễn ra', 'color': Colors.green};
      case 2:
        return {'text': 'Đã kết thúc', 'color': Colors.grey};
      case 3:
        return {'text': 'Đã hủy', 'color': Colors.red};
      default:
        return {'text': 'Unknown', 'color': Colors.grey};
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'Chưa có';
    try {
      final DateTime dt = DateTime.parse(dateTime.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _handleActivityAction(String action, Map<String, dynamic> activity) {
    switch (action) {
      case 'view':
        _showActivityDetails(activity);
        break;
      case 'edit':
        _showEditActivityDialog(activity);
        break;
      case 'status':
        _showChangeStatusDialog(activity);
        break;
      case 'delete':
        _showDeleteActivityDialog(activity);
        break;
    }
  }

  void _showActivityDetails(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity['name'] ?? 'Chi tiết hoạt động'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activity['description'] != null) ...[
                const Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(activity['description']),
                const SizedBox(height: 16),
              ],
              const Text('Thông tin:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Địa điểm: ${activity['location'] ?? 'Chưa có'}'),
              Text('Thời gian: ${_formatDateTime(activity['start_time'])} - ${_formatDateTime(activity['end_time'])}'),
              Text('Số lượng: ${activity['registered_count'] ?? 0}/${activity['max_participants'] ?? '∞'}'),
              Text('Điểm rèn luyện: ${activity['training_points'] ?? 0}'),
              Text('Tạo bởi: ${activity['creator']?['name'] ?? 'Unknown'}'),
            ],
          ),
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

  void _showEditActivityDialog(Map<String, dynamic> activity) {
    // TODO: Implement edit activity dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tính năng chỉnh sửa hoạt động đang phát triển')),
    );
  }

  void _showChangeStatusDialog(Map<String, dynamic> activity) {
    final currentStatus = activity['status'] ?? 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi trạng thái'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chọn trạng thái mới:'),
            const SizedBox(height: 16),
            ...List.generate(4, (index) {
              final statusInfo = _getStatusInfo(index);
              return RadioListTile<int>(
                title: Text(statusInfo['text']),
                value: index,
                groupValue: currentStatus,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context);
                    ref.read(adminActivitiesProvider.notifier).changeActivityStatus(activity['id'], value);
                  }
                },
              );
            }),
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

  void _showDeleteActivityDialog(Map<String, dynamic> activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa hoạt động'),
        content: Text('Bạn có chắc chắn muốn xóa hoạt động "${activity['name']}"?\n\nHành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(adminActivitiesProvider.notifier).deleteActivity(activity['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhiều hoạt động'),
        content: Text('Bạn có chắc chắn muốn xóa ${_selectedActivities.length} hoạt động đã chọn?\n\nHành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(adminActivitiesProvider.notifier).bulkDeleteActivities(_selectedActivities.toList());
              setState(() {
                _selectedActivities.clear();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}
