import 'package:flutter/foundation.dart';
import '../../admin/data/reports_service.dart';

class PeriodicReportService {
  final ReportsService _reportsService = ReportsService();

  /// Lấy báo cáo định kỳ từ backend
  static Future<Map<String, dynamic>?> getPeriodicReport(String period, DateTime startDate, DateTime endDate) async {
    try {
      final reportsService = ReportsService();
      final data = await reportsService.getPeriodicReport(
        period: period,
        startDate: startDate,
        endDate: endDate,
      );
      return data;
    } catch (e) {
      debugPrint('Lỗi khi lấy báo cáo định kỳ: $e');
      return null;
    }
  }

  /// Lấy tất cả báo cáo định kỳ từ backend
  static Future<List<Map<String, dynamic>>> getAllPeriodicReports() async {
    try {
      final reportsService = ReportsService();
      final reports = await reportsService.getStoredPeriodicReports();
      return reports;
    } catch (e) {
      debugPrint('Lỗi khi lấy tất cả báo cáo định kỳ: $e');
      return [];
    }
  }

  /// Lưu báo cáo định kỳ vào backend
  static Future<void> savePeriodicReport(Map<String, dynamic> reportData) async {
    try {
      final reportsService = ReportsService();
      await reportsService.savePeriodicReport(reportData);
    } catch (e) {
      debugPrint('Lỗi khi lưu báo cáo định kỳ: $e');
    }
  }

  /// Lấy báo cáo định kỳ (method chính để frontend gọi)
  static Future<Map<String, dynamic>?> getReport({
    required String period,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await getPeriodicReport(period, startDate, endDate);
  }

  /// Tự động tạo báo cáo định kỳ
  static Future<void> generatePeriodicReports() async {
    try {
      debugPrint('Tạo báo cáo định kỳ...');
      
      final now = DateTime.now();
      
      // Tạo báo cáo tuần
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      final weeklyData = await getPeriodicReport('weekly', startOfWeek, endOfWeek);
      if (weeklyData != null) {
        await savePeriodicReport({
          'period': 'weekly',
          'startDate': startOfWeek.toIso8601String(),
          'endDate': endOfWeek.toIso8601String(),
          'summary': weeklyData['summary'],
          'trends': weeklyData['trendsByDay'],
        });
      }

      // Tạo báo cáo tháng
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final monthlyData = await getPeriodicReport('monthly', startOfMonth, endOfMonth);
      if (monthlyData != null) {
        await savePeriodicReport({
          'period': 'monthly',
          'startDate': startOfMonth.toIso8601String(),
          'endDate': endOfMonth.toIso8601String(),
          'summary': monthlyData['summary'],
          'trends': monthlyData['trendsByDay'],
        });
      }

      // Tạo báo cáo năm
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year, 12, 31);
      
      final yearlyData = await getPeriodicReport('yearly', startOfYear, endOfYear);
      if (yearlyData != null) {
        await savePeriodicReport({
          'period': 'yearly',
          'startDate': startOfYear.toIso8601String(),
          'endDate': endOfYear.toIso8601String(),
          'summary': yearlyData['summary'],
          'trends': yearlyData['trendsByDay'],
        });
      }

      debugPrint('Báo cáo định kỳ đã được tạo thành công');
    } catch (e) {
      debugPrint('Lỗi khi tạo báo cáo định kỳ: $e');
    }
  }

  /// Lên lịch tạo báo cáo tự động
  static Future<void> schedulePeriodicReports() async {
      await generatePeriodicReports();
    }
    
  /// Kiểm tra xem có cần tạo báo cáo mới không
  static Future<bool> shouldGenerateNewReport() async {
    // Luôn trả về true để lấy dữ liệu mới nhất từ backend
    return true;
  }

  /// Xóa báo cáo cũ (không cần nữa vì backend quản lý)
  static Future<void> cleanupOldReports() async {
    // Backend đã quản lý việc này
  }
}