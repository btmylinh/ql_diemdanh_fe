import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api_client.dart';

class BackupService {
  final ApiClient _apiClient = ApiClient();

  /// Tạo bản sao lưu trên server (gọi backend /backup)
  Future<BackupResult> createBackup({String? name}) async {
    try {
      final resp = await _apiClient.post('/backup', {
        if (name != null) 'name': name,
      });

      final metadata = (resp['metadata'] as Map?)?.cast<String, dynamic>();

      return BackupResult(
        success: true,
        message: 'Đã tạo sao lưu trên server',
        filePath: resp['filePath'] as String?,
        metadata: metadata,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Lỗi khi tạo sao lưu: ${e.toString()}',
      );
    }
  }

  /// Khôi phục dữ liệu từ file sao lưu: gửi JSON lên backend /backup/restore
  Future<BackupResult> restoreFromFile() async {
    try {
      // Chọn file sao lưu
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return BackupResult(
          success: false,
          message: 'Không có file nào được chọn',
        );
      }

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final backupData = jsonDecode(content);

      // Gửi toàn bộ JSON lên backend để xử lý khôi phục atomically
      final resp = await _apiClient.post('/backup/restore', backupData);
      final restored = resp['result']?['restored'];

      return BackupResult(
        success: true,
        message: 'Khôi phục thành công trên server',
        metadata: (restored is Map ? restored.cast<String, dynamic>() : null),
      );

    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Lỗi khi khôi phục: ${e.toString()}',
      );
    }
  }

  /// Xuất báo cáo thống kê
  Future<BackupResult> exportReport(String reportType) async {
    try {
      final storagePermission = await Permission.storage.request();
      if (!storagePermission.isGranted) {
        return BackupResult(
          success: false,
          message: 'Cần cấp quyền truy cập storage để xuất báo cáo',
        );
      }

      Map<String, dynamic> reportData = {};
      String fileName = '';

      switch (reportType) {
        case 'activities':
          reportData = await _apiClient.get('/activities');
          fileName = 'activities_report_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        case 'users':
          reportData = await _apiClient.get('/users');
          fileName = 'users_report_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        case 'attendances':
          reportData = await _apiClient.get('/attendances');
          fileName = 'attendances_report_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        default:
          return BackupResult(
            success: false,
            message: 'Loại báo cáo không hợp lệ',
          );
      }

      // Tạo báo cáo với metadata
      final report = {
        'type': reportType,
        'generatedAt': DateTime.now().toIso8601String(),
        'data': reportData,
        'summary': _generateReportSummary(reportData, reportType),
      };

      // Lưu và xuất file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonEncode(report));

      return BackupResult(
        success: true,
        message: 'Xuất báo cáo thành công! File đã được lưu tại: ${file.path}',
        filePath: file.path,
      );

    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Lỗi khi xuất báo cáo: ${e.toString()}',
      );
    }
  }

  /// Danh sách backups trên server
  Future<List<dynamic>> listServerBackups() async {
    final resp = await _apiClient.get('/backup');
    return (resp['backups'] as List?) ?? const [];
  }

  /// Tải backup lưu trên server về máy
  Future<BackupResult> downloadServerBackup(int id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/server_backup_$id.json';
      // Download backup JSON from server
      final resp = await _apiClient.get('/backup/$id/download');
      final file = File(filePath);
      await file.writeAsString(jsonEncode(resp));
      return BackupResult(success: true, message: 'Đã tải backup', filePath: file.path);
    } catch (e) {
      return BackupResult(success: false, message: 'Lỗi tải backup: ${e.toString()}');
    }
  }

  /// Khôi phục từ backup id lưu trên server
  Future<BackupResult> restoreFromServerBackupId(int id) async {
    try {
      final resp = await _apiClient.post('/backup/$id/restore', {});
      return BackupResult(success: true, message: 'Khôi phục thành công', metadata: resp['result']);
    } catch (e) {
      return BackupResult(success: false, message: 'Lỗi khôi phục: ${e.toString()}');
    }
  }


  /// Generate summary for reports
  Map<String, dynamic> _generateReportSummary(Map<String, dynamic> data, String type) {
    final items = data['data'] as List<dynamic>? ?? [];
    
    switch (type) {
      case 'activities':
        return {
          'totalActivities': items.length,
          'activeActivities': items.where((a) => a['status'] == 'active').length,
          'completedActivities': items.where((a) => a['status'] == 'completed').length,
        };
      case 'users':
        return {
          'totalUsers': items.length,
          'adminUsers': items.where((u) => u['role'] == 'admin').length,
          'managerUsers': items.where((u) => u['role'] == 'manager').length,
          'studentUsers': items.where((u) => u['role'] == 'student').length,
        };
      case 'attendances':
        return {
          'totalAttendances': items.length,
          'presentCount': items.where((a) => a['status'] == 'present').length,
          'absentCount': items.where((a) => a['status'] == 'absent').length,
        };
      default:
        return {'total': items.length};
    }
  }
}

class BackupResult {
  final bool success;
  final String message;
  final String? filePath;
  final List<String>? warnings;
  final Map<String, dynamic>? metadata;

  BackupResult({
    required this.success,
    required this.message,
    this.filePath,
    this.warnings,
    this.metadata,
  });
}
