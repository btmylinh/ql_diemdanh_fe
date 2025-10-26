import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PeriodicReportService {
  static const String _keyPrefix = 'periodic_report_';
  static const String _lastGeneratedKey = 'last_generated';
  static const String _reportDataKey = 'report_data';

  /// Tự động tạo báo cáo định kỳ
  static Future<void> generatePeriodicReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Kiểm tra xem đã tạo báo cáo hôm nay chưa
      final lastGenerated = prefs.getString(_lastGeneratedKey);
      if (lastGenerated != null) {
        final lastDate = DateTime.tryParse(lastGenerated);
        if (lastDate != null && 
            lastDate.year == now.year && 
            lastDate.month == now.month && 
            lastDate.day == now.day) {
          debugPrint('Báo cáo định kỳ đã được tạo hôm nay');
          return;
        }
      }

      // Tạo báo cáo cho các kỳ khác nhau
      await _generateWeeklyReport();
      await _generateMonthlyReport();
      await _generateYearlyReport();

      // Lưu thời gian tạo báo cáo cuối cùng
      await prefs.setString(_lastGeneratedKey, now.toIso8601String());
      
      debugPrint('Báo cáo định kỳ đã được tạo thành công');
    } catch (e) {
      debugPrint('Lỗi khi tạo báo cáo định kỳ: $e');
    }
  }

  /// Tạo báo cáo tuần
  static Future<void> _generateWeeklyReport() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final reportData = {
      'period': 'weekly',
      'start_date': startOfWeek.toIso8601String(),
      'end_date': endOfWeek.toIso8601String(),
      'generated_at': now.toIso8601String(),
      'summary': {
        'total_activities': 0,
        'total_registrations': 0,
        'total_attendances': 0,
        'total_points': 0,
      },
      'trends': {
        'activity_creation': [],
        'registration_trends': [],
        'attendance_trends': [],
      },
    };

    await _saveReportData('weekly', reportData);
  }

  /// Tạo báo cáo tháng
  static Future<void> _generateMonthlyReport() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    final reportData = {
      'period': 'monthly',
      'start_date': startOfMonth.toIso8601String(),
      'end_date': endOfMonth.toIso8601String(),
      'generated_at': now.toIso8601String(),
      'summary': {
        'total_activities': 0,
        'total_registrations': 0,
        'total_attendances': 0,
        'total_points': 0,
        'active_users': 0,
        'new_users': 0,
      },
      'trends': {
        'activity_creation': [],
        'registration_trends': [],
        'attendance_trends': [],
        'user_growth': [],
      },
      'top_activities': [],
      'user_engagement': {},
    };

    await _saveReportData('monthly', reportData);
  }

  /// Tạo báo cáo năm
  static Future<void> _generateYearlyReport() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    
    final reportData = {
      'period': 'yearly',
      'start_date': startOfYear.toIso8601String(),
      'end_date': endOfYear.toIso8601String(),
      'generated_at': now.toIso8601String(),
      'summary': {
        'total_activities': 0,
        'total_registrations': 0,
        'total_attendances': 0,
        'total_points': 0,
        'active_users': 0,
        'new_users': 0,
        'growth_rate': 0.0,
      },
      'trends': {
        'activity_creation': [],
        'registration_trends': [],
        'attendance_trends': [],
        'user_growth': [],
        'seasonal_patterns': [],
      },
      'top_activities': [],
      'user_engagement': {},
      'performance_metrics': {},
    };

    await _saveReportData('yearly', reportData);
  }

  /// Lưu dữ liệu báo cáo
  static Future<void> _saveReportData(String period, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_keyPrefix}${period}_${DateTime.now().millisecondsSinceEpoch}';
    await prefs.setString(key, jsonEncode(data));
  }

  /// Lấy báo cáo định kỳ
  static Future<Map<String, dynamic>?> getPeriodicReport(String period) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('${_keyPrefix}${period}_')).toList();
      
      if (keys.isEmpty) return null;
      
      // Lấy báo cáo mới nhất
      keys.sort((a, b) => b.compareTo(a));
      final latestKey = keys.first;
      final data = prefs.getString(latestKey);
      
      if (data != null) {
        return jsonDecode(data);
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khi lấy báo cáo định kỳ: $e');
      return null;
    }
  }

  /// Lấy tất cả báo cáo định kỳ
  static Future<List<Map<String, dynamic>>> getAllPeriodicReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith(_keyPrefix)).toList();
      
      final reports = <Map<String, dynamic>>[];
      
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          final report = jsonDecode(data);
          reports.add(report);
        }
      }
      
      // Sắp xếp theo thời gian tạo
      reports.sort((a, b) {
        final aTime = DateTime.tryParse(a['generated_at'] ?? '');
        final bTime = DateTime.tryParse(b['generated_at'] ?? '');
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      return reports;
    } catch (e) {
      debugPrint('Lỗi khi lấy tất cả báo cáo định kỳ: $e');
      return [];
    }
  }

  /// Xóa báo cáo cũ (giữ lại 30 ngày)
  static Future<void> cleanupOldReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith(_keyPrefix)).toList();
      
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      for (final key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          final report = jsonDecode(data);
          final generatedAt = DateTime.tryParse(report['generated_at'] ?? '');
          
          if (generatedAt != null && generatedAt.isBefore(cutoffDate)) {
            await prefs.remove(key);
            debugPrint('Đã xóa báo cáo cũ: $key');
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi dọn dẹp báo cáo cũ: $e');
    }
  }

  /// Kiểm tra xem có cần tạo báo cáo mới không
  static Future<bool> shouldGenerateNewReport() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastGenerated = prefs.getString(_lastGeneratedKey);
      
      if (lastGenerated == null) return true;
      
      final lastDate = DateTime.tryParse(lastGenerated);
      if (lastDate == null) return true;
      
      final now = DateTime.now();
      return !(lastDate.year == now.year && 
               lastDate.month == now.month && 
               lastDate.day == now.day);
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra báo cáo: $e');
      return true;
    }
  }

  /// Lên lịch tạo báo cáo tự động
  static Future<void> schedulePeriodicReports() async {
    // Kiểm tra và tạo báo cáo nếu cần
    final shouldGenerate = await shouldGenerateNewReport();
    if (shouldGenerate) {
      await generatePeriodicReports();
    }
    
    // Dọn dẹp báo cáo cũ
    await cleanupOldReports();
  }
}
