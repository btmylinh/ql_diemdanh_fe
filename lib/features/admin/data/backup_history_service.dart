import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class BackupHistoryService {
  static const String _historyFileName = 'backup_history.json';

  /// Lưu thông tin backup vào lịch sử
  static Future<void> saveBackupInfo({
    required String fileName,
    required String filePath,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final historyFile = File('${directory.path}/$_historyFileName');
      
      List<Map<String, dynamic>> history = [];
      
      // Đọc lịch sử hiện tại nếu có
      if (await historyFile.exists()) {
        final content = await historyFile.readAsString();
        history = List<Map<String, dynamic>>.from(jsonDecode(content));
      }
      
      // Thêm thông tin backup mới
      history.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'fileName': fileName,
        'filePath': filePath,
        'createdAt': DateTime.now().toIso8601String(),
        'metadata': metadata,
      });
      
      // Giữ tối đa 50 bản sao lưu gần nhất
      if (history.length > 50) {
        history = history.take(50).toList();
      }
      
      // Lưu lịch sử
      await historyFile.writeAsString(jsonEncode(history));
    } catch (e) {
      print('Lỗi khi lưu lịch sử backup: $e');
    }
  }

  /// Lấy danh sách lịch sử backup
  static Future<List<Map<String, dynamic>>> getBackupHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final historyFile = File('${directory.path}/$_historyFileName');
      
      if (!await historyFile.exists()) {
        return [];
      }
      
      final content = await historyFile.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(content));
    } catch (e) {
      print('Lỗi khi đọc lịch sử backup: $e');
      return [];
    }
  }

  /// Xóa một bản sao lưu khỏi lịch sử
  static Future<bool> deleteBackupFromHistory(String backupId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final historyFile = File('${directory.path}/$_historyFileName');
      
      if (!await historyFile.exists()) {
        return false;
      }
      
      final content = await historyFile.readAsString();
      List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(jsonDecode(content));
      
      // Tìm và xóa backup
      final backupToDelete = history.firstWhere(
        (backup) => backup['id'] == backupId,
        orElse: () => <String, dynamic>{},
      );
      
      if (backupToDelete.isNotEmpty) {
        // Xóa file backup nếu tồn tại
        final filePath = backupToDelete['filePath'] as String?;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
        
        // Xóa khỏi lịch sử
        history.removeWhere((backup) => backup['id'] == backupId);
        
        // Lưu lịch sử đã cập nhật
        await historyFile.writeAsString(jsonEncode(history));
        return true;
      }
      
      return false;
    } catch (e) {
      print('Lỗi khi xóa backup khỏi lịch sử: $e');
      return false;
    }
  }

  /// Xóa tất cả lịch sử backup
  static Future<void> clearBackupHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final historyFile = File('${directory.path}/$_historyFileName');
      
      if (await historyFile.exists()) {
        await historyFile.delete();
      }
    } catch (e) {
      print('Lỗi khi xóa lịch sử backup: $e');
    }
  }

  /// Kiểm tra xem file backup có tồn tại không
  static Future<bool> isBackupFileValid(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      
      // Kiểm tra nội dung file có phải JSON hợp lệ không
      final content = await file.readAsString();
      final data = jsonDecode(content);
      
      // Kiểm tra cấu trúc cơ bản
      return data is Map<String, dynamic> &&
             data.containsKey('version') &&
             data.containsKey('createdAt') &&
             data.containsKey('data');
    } catch (e) {
      return false;
    }
  }
}
