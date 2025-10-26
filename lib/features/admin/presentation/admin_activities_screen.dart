import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';
import '../data/admin_activities_provider.dart';

class AdminActivitiesScreen extends ConsumerStatefulWidget {
  const AdminActivitiesScreen({super.key});

  @override
  ConsumerState<AdminActivitiesScreen> createState() => _AdminActivitiesScreenState();
}

class _AdminActivitiesScreenState extends ConsumerState<AdminActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
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
    
    // Show error in SnackBar if there's an error
    if (activitiesState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${activitiesState.error}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () {
                ref.read(adminActivitiesProvider.notifier).loadActivities();
              },
            ),
          ),
        );
        // Clear error after showing
        ref.read(adminActivitiesProvider.notifier).state = 
            ref.read(adminActivitiesProvider.notifier).state.copyWith(error: null);
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hoạt động'),
        backgroundColor: kBlue,
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
              tooltip: 'Xóa các hoạt động đã chọn',
            ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportActivities(),
            tooltip: 'Xuất dữ liệu hoạt động',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminActivitiesProvider.notifier).loadActivities();
            },
            tooltip: 'Làm mới danh sách',
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
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    activity['location'] ?? 'Chưa có địa điểm',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(_formatDateTime(activity['start_time'])),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${activity['registered_count'] ?? 0}/${activity['max_participants'] ?? '∞'}'),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    activity['creator']?['name'] ?? 'Unknown',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
              value: 'registrations',
              child: Row(
                children: [
                  Icon(Icons.people, size: 20),
                  SizedBox(width: 8),
                  Text('Danh sách đăng ký'),
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
      case 'registrations':
        _showActivityRegistrations(activity);
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
              Text('Thời gian bắt đầu: ${_formatDateTime(activity['start_time'])}'),
              Text('Thời gian kết thúc: ${_formatDateTime(activity['end_time'])}'),
              Text('Hạn đăng ký: ${_formatDateTime(activity['registration_deadline'])}'),
              Text('Số lượng: ${activity['registered_count'] ?? 0}/${activity['max_participants'] ?? '∞'}'),
              Text('Điểm rèn luyện: ${activity['training_points'] ?? 0}'),
              Text('Tạo bởi: ${activity['creator']?['name'] ?? 'Unknown'}'),
              Text('Ngày tạo: ${_formatDateTime(activity['created_at'])}'),
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

  void _showActivityRegistrations(Map<String, dynamic> activity) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Call API to get registrations
      final response = await ref.read(adminActivitiesProvider.notifier).getActivityRegistrations(activity['id']);

      Navigator.pop(context); // Close loading dialog

      if (response['registrations'] != null) {
        final registrations = List<Map<String, dynamic>>.from(response['registrations']);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Danh sách đăng ký'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: registrations.isEmpty
                  ? const Center(
                      child: Text('Chưa có sinh viên nào đăng ký'),
                    )
                  : ListView.builder(
                      itemCount: registrations.length,
                      itemBuilder: (context, index) {
                        final registration = registrations[index];
                        final student = registration['user'] ?? registration['student'] ?? {};
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: Text(
                                student['name']?.substring(0, 1).toUpperCase() ?? '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(student['name'] ?? 'Unknown'),
                            subtitle: Text('${student['mssv'] ?? 'N/A'}  ${student['class'] ?? 'N/A'}'),
                           
                          ),
                        );
                      },
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải danh sách đăng ký')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  void _showEditActivityDialog(Map<String, dynamic> activity) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: activity['name'] ?? '');
    final descriptionController = TextEditingController(text: activity['description'] ?? '');
    final locationController = TextEditingController(text: activity['location'] ?? '');
    final maxParticipantsController = TextEditingController(text: activity['max_participants']?.toString() ?? '');
    final trainingPointsController = TextEditingController(text: activity['training_points']?.toString() ?? '0');
    
    DateTime? startTime = activity['start_time'] != null ? DateTime.parse(activity['start_time'].toString()) : null;
    DateTime? endTime = activity['end_time'] != null ? DateTime.parse(activity['end_time'].toString()) : null;
    DateTime? registrationDeadline = activity['registration_deadline'] != null ? DateTime.parse(activity['registration_deadline'].toString()) : null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Chỉnh sửa hoạt động'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên hoạt động *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Tên hoạt động không được để trống';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Địa điểm',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: maxParticipantsController,
                          decoration: const InputDecoration(
                            labelText: 'Số lượng tối đa',
                            border: OutlineInputBorder(),
                            hintText: 'Để trống = không giới hạn',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final num = int.tryParse(value);
                              if (num == null || num < 1) {
                                return 'Số lượng phải là số nguyên dương';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: trainingPointsController,
                          decoration: const InputDecoration(
                            labelText: 'Điểm rèn luyện',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Điểm rèn luyện không được để trống';
                            }
                            final num = int.tryParse(value);
                            if (num == null || num < 0) {
                              return 'Điểm rèn luyện phải là số >= 0';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Thời gian bắt đầu:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startTime ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: startTime != null ? TimeOfDay.fromDateTime(startTime!) : TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            startTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule),
                          const SizedBox(width: 8),
                          Text(startTime != null 
                            ? '${startTime!.day}/${startTime!.month}/${startTime!.year} ${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}'
                            : 'Chọn thời gian bắt đầu'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Thời gian kết thúc:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endTime ?? (startTime ?? DateTime.now()),
                        firstDate: startTime ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: endTime != null ? TimeOfDay.fromDateTime(endTime!) : TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            endTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule),
                          const SizedBox(width: 8),
                          Text(endTime != null 
                            ? '${endTime!.day}/${endTime!.month}/${endTime!.year} ${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}'
                            : 'Chọn thời gian kết thúc'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Hạn đăng ký:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: registrationDeadline ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: registrationDeadline != null ? TimeOfDay.fromDateTime(registrationDeadline!) : TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            registrationDeadline = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                          });
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule),
                          const SizedBox(width: 8),
                          Text(registrationDeadline != null 
                            ? '${registrationDeadline!.day}/${registrationDeadline!.month}/${registrationDeadline!.year} ${registrationDeadline!.hour.toString().padLeft(2, '0')}:${registrationDeadline!.minute.toString().padLeft(2, '0')}'
                            : 'Chọn hạn đăng ký'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  if (startTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu')),
                    );
                    return;
                  }
                  if (endTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng chọn thời gian kết thúc')),
                    );
                    return;
                  }
                  if (endTime!.isBefore(startTime!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thời gian kết thúc phải sau thời gian bắt đầu')),
                    );
                    return;
                  }
                  
                  final activityData = {
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                    'location': locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                    'start_time': startTime!.toIso8601String(),
                    'end_time': endTime!.toIso8601String(),
                    'registration_deadline': registrationDeadline?.toIso8601String(),
                    'max_participants': maxParticipantsController.text.trim().isEmpty ? null : int.parse(maxParticipantsController.text.trim()),
                    'training_points': int.parse(trainingPointsController.text.trim()),
                  };
                  
                  // Close edit dialog first
                  Navigator.pop(context);
                  
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                  
                  try {
                    final success = await ref.read(adminActivitiesProvider.notifier).updateActivity(activity['id'], activityData);
                    
                    // Close loading dialog
                    Navigator.pop(context);
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật hoạt động thành công')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cập nhật hoạt động thất bại')),
                      );
                    }
                  } catch (e) {
                    // Close loading dialog if there's an error
                    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${e.toString()}')),
                    );
                  }
                }
              },
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
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
                onChanged: (value) async {
                  if (value != null) {
                    Navigator.pop(context);
                    
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                    
                    try {
                      final success = await ref.read(adminActivitiesProvider.notifier).changeActivityStatus(activity['id'], value);
                      
                      Navigator.pop(context); // Close loading dialog
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thay đổi trạng thái thành công')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thay đổi trạng thái thất bại')),
                        );
                      }
                    } catch (e) {
                      Navigator.pop(context); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: ${e.toString()}')),
                      );
                    }
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
        content: Text('Bạn có chắc chắn muốn xóa hoạt động "${activity['name']}"?\n\nViệc này sẽ xóa tất cả đăng ký và điểm danh liên quan!\n\nHành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                final success = await ref.read(adminActivitiesProvider.notifier).deleteActivity(activity['id']);
                
                Navigator.pop(context); // Close loading dialog
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa hoạt động thành công')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa hoạt động thất bại')),
                  );
                }
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                );
              }
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
        content: Text('Bạn có chắc chắn muốn xóa ${_selectedActivities.length} hoạt động đã chọn?\n\nViệc này sẽ xóa tất cả đăng ký và điểm danh liên quan!\n\nHành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                final success = await ref.read(adminActivitiesProvider.notifier).bulkDeleteActivities(_selectedActivities.toList());
                
                Navigator.pop(context); // Close loading dialog
                
                if (success) {
              setState(() {
                _selectedActivities.clear();
              });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa các hoạt động thành công')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Xóa các hoạt động thất bại')),
                  );
                }
              } catch (e) {
                Navigator.pop(context); // Close loading dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }

  void _exportActivities() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      await ref.read(adminActivitiesProvider.notifier).exportActivities();
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xuất dữ liệu hoạt động thành công')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xuất dữ liệu thất bại: ${e.toString()}')),
      );
    }
  }
}
