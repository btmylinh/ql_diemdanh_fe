import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/api_client.dart';

class BackupService {
  final ApiClient _apiClient = ApiClient();

  /// Tạo bản sao lưu trên server (gọi backend /backup/create)
  Future<BackupResult> createBackup({String? name}) async {
    try {
      final resp = await _apiClient.post('/backup/create', {
        if (name != null) 'name': name,
      });

      final metadata = (resp['data']?['metadata'] as Map?)?.cast<String, dynamic>();

      return BackupResult(
        success: true,
        message: resp['message'] ?? 'Đã tạo sao lưu trên server',
        filePath: resp['data']?['filePath'] as String?,
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
      final restored = resp['data']?['restored'];

      return BackupResult(
        success: true,
        message: resp['message'] ?? 'Khôi phục thành công trên server',
        metadata: (restored is Map ? restored.cast<String, dynamic>() : null),
      );

    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Lỗi khi khôi phục: ${e.toString()}',
      );
    }
  }


  /// Danh sách backups trên server
  Future<List<dynamic>> listServerBackups() async {
    final resp = await _apiClient.get('/backup/list');
    return (resp['data'] as List?) ?? const [];
  }

  /// Tải backup lưu trên server về máy
  Future<BackupResult> downloadServerBackup(String id) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/server_backup_$id.json';
      // Download backup JSON from server
      final resp = await _apiClient.get('/backup/$id');
      final file = File(filePath);
      await file.writeAsString(jsonEncode(resp));
      return BackupResult(success: true, message: 'Đã tải backup', filePath: file.path);
    } catch (e) {
      return BackupResult(success: false, message: 'Lỗi tải backup: ${e.toString()}');
    }
  }

  /// Khôi phục từ backup id lưu trên server
  Future<BackupResult> restoreFromServerBackupId(String id) async {
    try {
      final resp = await _apiClient.post('/backup/$id/restore', {});
      return BackupResult(success: true, message: resp['message'] ?? 'Khôi phục thành công', metadata: resp['data']);
    } catch (e) {
      return BackupResult(success: false, message: 'Lỗi khôi phục: ${e.toString()}');
    }
  }

  /// Xóa bản sao lưu từ server
  Future<bool> deleteBackup(String backupId) async {
    try {
      await _apiClient.delete('/backup/$backupId');
      return true;
    } catch (e) {
      print('Lỗi khi xóa backup: $e');
      return false;
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
