import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../theme.dart';
import '../data/attendances_providers.dart';
import '../data/activities_providers.dart';

class AttendanceSessionScreen extends ConsumerStatefulWidget {
  const AttendanceSessionScreen({super.key});

  @override
  ConsumerState<AttendanceSessionScreen> createState() => _AttendanceSessionScreenState();
}

class _AttendanceSessionScreenState extends ConsumerState<AttendanceSessionScreen> {
  String? _activityId;
  int? _activityIdInt;
  
  bool _isSessionActive = false;
  String _currentPIN = '';
  Timer? _pinTimer;
  Timer? _sessionTimer;
  Timer? _refreshTimer;
  int _sessionDuration = 0; // in seconds
  String _qrData = '';
  
  final Random _random = Random();
  final TextEditingController _manualCheckinController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_activityId == null) {
      _activityId = GoRouterState.of(context).pathParameters['id'] ?? '0';
      _activityIdInt = int.tryParse(_activityId!) ?? 0;
      _generateQRData();
    }
  }

  @override
  void dispose() {
    _pinTimer?.cancel();
    _sessionTimer?.cancel();
    _refreshTimer?.cancel();
    _manualCheckinController.dispose();
    super.dispose();
  }

  void _generateQRData() {
    if (_activityId != null) {
      setState(() {
        _qrData = 'attendance://${_activityId}';
      });
    }
  }

  void _generatePIN() {
    setState(() {
      _currentPIN = _generateRandomPIN();
    });
  }

  String _generateRandomPIN() {
    return (100000 + _random.nextInt(900000)).toString();
  }

  void _startSession() {
    if (_isSessionActive) return;
    
    setState(() {
      _isSessionActive = true;
      _sessionDuration = 0;
    });
    
    _generatePIN();
    
    // PIN rotation every 30 seconds
    _pinTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _generatePIN();
    });
    
    // Session timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sessionDuration++;
      });
    });
    
    // Refresh attendance data every 5 seconds
    if (_activityIdInt != null) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        ref.invalidate(activityAttendancesProvider({
          'activityId': _activityIdInt!,
          'page': 1,
          'limit': 100,
        }));
      });
    }
  }

  void _stopSession() {
    setState(() {
      _isSessionActive = false;
    });
    
    _pinTimer?.cancel();
    _sessionTimer?.cancel();
    _refreshTimer?.cancel();
  }

  void _showManualCheckinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Điểm danh thủ công'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _manualCheckinController,
              decoration: const InputDecoration(
                labelText: 'MSSV hoặc Email',
                hintText: 'Nhập MSSV hoặc email của sinh viên',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tìm kiếm sinh viên để điểm danh thủ công',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement manual checkin search
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
            child: const Text('Tìm kiếm'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activityId == null || _activityIdInt == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          title: const Text('Phiên điểm danh'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Kiểm tra điều kiện hiển thị QR code
    final activityAsync = ref.watch(activityProvider(_activityIdInt!));
    
    return activityAsync.when(
      data: (activity) {
        final now = DateTime.now();
        final startTime = DateTime.parse(activity['start_time']);
        final status = activity['status'] as int;
        
        // Chỉ cho phép khi status = 2 (ongoing) VÀ đã đến giờ bắt đầu
        if (status != 2 || now.isBefore(startTime)) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: kBlue,
              foregroundColor: Colors.white,
              title: const Text('Phiên điểm danh'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 64,
                    color: Colors.orange[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status != 2 
                      ? 'Hoạt động chưa bắt đầu'
                      : 'Chưa đến giờ bắt đầu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chỉ có thể điểm danh khi hoạt động đang diễn ra',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        return _buildAttendanceSessionContent();
      },
      loading: () => Scaffold(
        appBar: AppBar(
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          title: const Text('Phiên điểm danh'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(
          backgroundColor: kBlue,
          foregroundColor: Colors.white,
          title: const Text('Phiên điểm danh'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Lỗi tải dữ liệu hoạt động',
                style: TextStyle(color: Colors.red[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAttendanceSessionContent() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        title: const Text('Phiên điểm danh'),
        elevation: 0,
        actions: [
          if (_isSessionActive)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopSession,
              tooltip: 'Dừng phiên điểm danh',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Session Status Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: _isSessionActive 
                        ? [Colors.green.withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.05)]
                        : [Colors.grey.withValues(alpha: 0.1), Colors.grey.withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isSessionActive ? Icons.play_circle : Icons.pause_circle,
                          color: _isSessionActive ? Colors.green : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSessionActive ? 'Phiên điểm danh đang hoạt động' : 'Phiên điểm danh đã dừng',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _isSessionActive ? Colors.green[700] : Colors.grey[700],
                                ),
                              ),
                              if (_isSessionActive) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Thời gian: ${_formatDuration(_sessionDuration)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isSessionActive) ...[
                      // Current PIN Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Mã PIN hiện tại',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentPIN,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Thay đổi sau 30 giây',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // QR Code Display
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Mã QR điểm danh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quét mã QR này để điểm danh',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hoặc nhập mã PIN: $_currentPIN',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSessionActive ? null : _startSession,
                    icon: Icon(_isSessionActive ? Icons.play_arrow : Icons.play_arrow),
                    label: Text(_isSessionActive ? 'Đang chạy' : 'Bắt đầu phiên'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSessionActive ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSessionActive ? _stopSession : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Dừng phiên'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Realtime Attendance List
            if (_isSessionActive) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Danh sách điểm danh (Realtime)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.person_add),
                            onPressed: _showManualCheckinDialog,
                            tooltip: 'Điểm danh thủ công',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAttendanceList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Instructions
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Hướng dẫn sử dụng',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem('1', 'Nhấn "Bắt đầu phiên" để khởi động phiên điểm danh'),
                    _buildInstructionItem('2', 'Hiển thị mã QR hoặc PIN cho sinh viên quét/nhập'),
                    _buildInstructionItem('3', 'PIN sẽ tự động thay đổi sau mỗi 30 giây'),
                    _buildInstructionItem('4', 'Danh sách điểm danh sẽ cập nhật realtime'),
                    _buildInstructionItem('5', 'Nhấn "Dừng phiên" để kết thúc phiên điểm danh'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    if (_activityIdInt == null) {
      return const Center(child: Text('Đang tải...'));
    }
    
    final attendancesAsync = ref.watch(activityAttendancesProvider({
      'activityId': _activityIdInt!,
      'page': 1,
      'limit': 100,
    }));

    return attendancesAsync.when(
      data: (data) {
        final attendances = data['attendances'] as List<dynamic>? ?? [];
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        final totalAttendances = stats['totalAttendances'] as int? ?? 0;
        
        return Column(
          children: [
            // Stats row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Tổng điểm danh', '$totalAttendances', Colors.green),
                  _buildStatItem('Hôm nay', '${attendances.length}', Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Attendance list
            if (attendances.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Chưa có ai điểm danh',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sinh viên sẽ xuất hiện ở đây khi điểm danh',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 200,
                child: ListView.builder(
                  itemCount: attendances.length,
                  itemBuilder: (context, index) {
                    final attendance = attendances[index] as Map<String, dynamic>;
                    return _buildAttendanceItem(attendance);
                  },
                ),
              ),
          ],
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 8),
            Text(
              'Lỗi tải dữ liệu',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString(),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceItem(Map<String, dynamic> attendance) {
    final user = attendance['user'] as Map<String, dynamic>? ?? {};
    final name = user['name'] as String? ?? 'N/A';
    final mssv = user['mssv'] as String? ?? 'N/A';
    final checkinTime = attendance['checkinTime'] as String? ?? '';
    final method = attendance['method'] as String? ?? 'qr';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            child: Icon(
              method == 'qr' ? Icons.qr_code_scanner : Icons.person,
              color: Colors.green[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'MSSV: $mssv',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCheckinTime(checkinTime),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                method == 'qr' ? 'QR Code' : 'Thủ công',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCheckinTime(String timeString) {
    try {
      final time = DateTime.parse(timeString);
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inMinutes < 1) {
        return 'Vừa xong';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} phút trước';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} giờ trước';
      } else {
        return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}