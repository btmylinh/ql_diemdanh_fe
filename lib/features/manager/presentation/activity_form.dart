import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';
import '../data/activities_providers.dart';

class ActivityFormScreen extends ConsumerStatefulWidget {
  const ActivityFormScreen({super.key});

  @override
  ConsumerState<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends ConsumerState<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _trainingPointsController = TextEditingController();
  
  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? _registrationDeadline;
  int _status = 1; // Default to draft
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Check if we're editing an existing activity
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = GoRouterState.of(context);
      final activityId = router.pathParameters['id'];
      if (activityId != null) {
        _loadActivity(int.parse(activityId));
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _trainingPointsController.dispose();
    super.dispose();
  }

  Future<void> _loadActivity(int id) async {
    try {
      final activity = await ref.read(activityProvider(id).future);
      _nameController.text = activity['name'] ?? '';
      _descriptionController.text = activity['description'] ?? '';
      _locationController.text = activity['location'] ?? '';
      _maxParticipantsController.text = activity['max_participants']?.toString() ?? '';
      _trainingPointsController.text = activity['training_points']?.toString() ?? '0';
      
      if (activity['start_time'] != null) {
        _startTime = DateTime.parse(activity['start_time']);
      }
      if (activity['end_time'] != null) {
        _endTime = DateTime.parse(activity['end_time']);
      }
      if (activity['registration_deadline'] != null) {
        _registrationDeadline = DateTime.parse(activity['registration_deadline']);
      }
      
      _status = activity['status'] ?? 1;
      
      setState(() {
        // Trigger UI rebuild to show loaded data
      });
      
      ref.read(activityFormProvider.notifier).setEditing(true);
      ref.read(activityFormProvider.notifier).setActivity(activity);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải hoạt động: $e')),
        );
      }
    }
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartTime ? (_startTime ?? DateTime.now()) : (_endTime ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: isStartTime 
          ? TimeOfDay.fromDateTime(_startTime ?? DateTime.now())
          : TimeOfDay.fromDateTime(_endTime ?? DateTime.now()),
      );
      
      if (time != null) {
        final DateTime selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        
        setState(() {
          if (isStartTime) {
            _startTime = selectedDateTime;
            // Auto-set end time to 2 hours later if not set
            if (_endTime == null) {
              _endTime = selectedDateTime.add(const Duration(hours: 2));
            }
            // Clear registration deadline if it's now after or equal to start time
            if (_registrationDeadline != null && 
                (_registrationDeadline!.isAfter(selectedDateTime) || _registrationDeadline!.isAtSameMomentAs(selectedDateTime))) {
              _registrationDeadline = null;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hạn chót đăng ký đã được xóa vì sau thời gian bắt đầu mới')),
              );
            }
          } else {
            _endTime = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _selectRegistrationDeadline() async {
    // Ensure we have a start time before allowing deadline selection
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu trước khi đặt hạn chót đăng ký')),
      );
      return;
    }
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _registrationDeadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: _startTime!.subtract(const Duration(minutes: 1)), // Must be at least 1 minute before start time
    );
    
    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_registrationDeadline ?? DateTime.now()),
      );
      
      if (time != null) {
        final DateTime selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        
        setState(() {
          _registrationDeadline = selectedDateTime;
        });
      }
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn thời gian bắt đầu và kết thúc')),
      );
      return;
    }
    
    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian kết thúc phải sau thời gian bắt đầu')),
      );
      return;
    }
    
    // Validate registration deadline
    if (_registrationDeadline != null) {
      if (_registrationDeadline!.isAfter(_startTime!) || _registrationDeadline!.isAtSameMomentAs(_startTime!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hạn chót đăng ký phải trước thời gian bắt đầu hoạt động')),
        );
        return;
      }
      if (_registrationDeadline!.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hạn chót đăng ký không được ở quá khứ')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    final formState = ref.read(activityFormProvider);
    final data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'start_time': _startTime!.toIso8601String(),
      'end_time': _endTime!.toIso8601String(),
      'max_participants': _maxParticipantsController.text.isNotEmpty 
        ? int.parse(_maxParticipantsController.text) 
        : null,
      'training_points': _trainingPointsController.text.isNotEmpty 
        ? int.parse(_trainingPointsController.text) 
        : 0,
      'registration_deadline': _registrationDeadline?.toIso8601String(),
      'status': formState.isEditing ? _status : 1, // Let backend determine status based on time
    };
    

    try {
      if (formState.isEditing) {
        final router = GoRouterState.of(context);
        final activityId = int.parse(router.pathParameters['id']!);
        await ref.read(activityFormProvider.notifier).updateActivity(activityId, data);
      } else {
        await ref.read(activityFormProvider.notifier).createActivity(data);
      }
      
      if (mounted) {
        // Invalidate providers to refresh data
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(myActivitiesProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(formState.isEditing ? 'Cập nhật hoạt động thành công!' : 'Tạo hoạt động thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(activityFormProvider);
    final isEditing = formState.isEditing;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        title: Text(isEditing ? 'Chỉnh sửa hoạt động' : 'Tạo hoạt động mới'),
        elevation: 0,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteDialog(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông tin cơ bản',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Activity Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên hoạt động *',
                          hintText: 'Nhập tên hoạt động',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên hoạt động';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả',
                          hintText: 'Nhập mô tả hoạt động',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // Location
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Địa điểm',
                          hintText: 'Nhập địa điểm tổ chức',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Max Participants
                      TextFormField(
                        controller: _maxParticipantsController,
                        decoration: const InputDecoration(
                          labelText: 'Số lượng tối đa',
                          hintText: 'Để trống khi không giới hạn',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final num = int.tryParse(value);
                            if (num == null || num <= 0) {
                              return 'Số lượng phải là số nguyên dương';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Training Points
                      TextFormField(
                        controller: _trainingPointsController,
                        decoration: const InputDecoration(
                          labelText: 'Điểm rèn luyện',
                          hintText: 'Nhập điểm rèn luyện',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.star),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final num = int.tryParse(value);
                            if (num == null || num < 0) {
                              return 'Điểm rèn luyện phải là số nguyên không âm';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Time and Status Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thời gian',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Start Time
                      ListTile(
                        leading: const Icon(Icons.play_circle_outline),
                        title: const Text('Thời gian bắt đầu *'),
                        subtitle: Text(_startTime != null 
                          ? '${_startTime!.day}/${_startTime!.month}/${_startTime!.year} ${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
                          : 'Chọn thời gian bắt đầu'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _selectDateTime(true),
                      ),
                      
                      const Divider(),
                      
                      // End Time
                      ListTile(
                        leading: const Icon(Icons.stop_circle),
                        title: const Text('Thời gian kết thúc *'),
                        subtitle: Text(_endTime != null 
                          ? '${_endTime!.day}/${_endTime!.month}/${_endTime!.year} ${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                          : 'Chọn thời gian kết thúc'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _selectDateTime(false),
                      ),
                      
                      const Divider(),
                      
                      // Registration Deadline
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Hạn chót đăng ký'),
                        subtitle: Text(_registrationDeadline != null 
                          ? '${_registrationDeadline!.day}/${_registrationDeadline!.month}/${_registrationDeadline!.year} ${_registrationDeadline!.hour.toString().padLeft(2, '0')}:${_registrationDeadline!.minute.toString().padLeft(2, '0')}'
                          : _startTime != null 
                            ? 'Chọn hạn chót đăng ký (phải trước ${_startTime!.day}/${_startTime!.month}/${_startTime!.year})'
                            : 'Chọn hạn chót đăng ký (tùy chọn)'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_registrationDeadline != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() => _registrationDeadline = null);
                                },
                              ),
                            const Icon(Icons.arrow_forward_ios),
                          ],
                        ),
                        onTap: () => _selectRegistrationDeadline(),
                      ),
                      
                      const Divider(),
                      
                      // Status - Only show when editing existing activity
                      if (isEditing) ...[
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('Trạng thái'),
                          subtitle: Text(_getStatusText(_status)),
                          trailing: DropdownButton<int>(
                            value: _status,
                            onChanged: (value) {
                              setState(() => _status = value!);
                            },
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Sắp diễn ra')),
                              DropdownMenuItem(value: 2, child: Text('Đang diễn ra')),
                              DropdownMenuItem(value: 3, child: Text('Đã hoàn thành')),
                              DropdownMenuItem(value: 4, child: Text('Đã hủy')),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Show info about default status when creating new activity
                       
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveActivity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        isEditing ? 'Cập nhật hoạt động' : 'Tạo hoạt động',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(int status) {
    switch (status) {
      case 1: return 'Sắp diễn ra';
      case 2: return 'Đang diễn ra';
      case 3: return 'Đã hoàn thành';
      case 4: return 'Đã hủy';
      default: return 'Không xác định';
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa hoạt động này? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteActivity();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteActivity() async {
    setState(() => _isLoading = true);
    
    try {
      final router = GoRouterState.of(context);
      final activityId = int.parse(router.pathParameters['id']!);
      await ref.read(activityFormProvider.notifier).deleteActivity(activityId);
      
      if (mounted) {
        // Invalidate dashboard stats to refresh statistics
        ref.invalidate(dashboardStatsProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Xóa hoạt động thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa hoạt động: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}