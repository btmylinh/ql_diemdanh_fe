import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../config.dart';

final periodicReportProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  return await PeriodicReportService.getReport(
    period: params['period'] as String,
    startDate: params['startDate'] as DateTime,
    endDate: params['endDate'] as DateTime,
  );
});

class PeriodicReportService {
  static final ApiClient _apiClient = ApiClient();

  static Future<Map<String, dynamic>> getReport({
    required String period,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final queryParams = {
        'period': period,
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
      };
      
      final response = await _apiClient.get('/reports/periodic', queryParams);
      final data = response['data'] as Map<String, dynamic>? ?? {};
      
      return data;
    } catch (e) {
      print('Error getting periodic report: $e');
      rethrow;
    }
  }

  static Future<void> generateReport({DateTime? date}) async {
    try {
      final body = <String, dynamic>{};
      if (date != null) {
        body['date'] = date.toIso8601String();
      }
      
      await _apiClient.post('/reports/periodic/generate', body);
    } catch (e) {
      print('Error generating report: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getStoredReports({int limit = 20}) async {
    try {
      final response = await _apiClient.get('/reports/periodic/stored', {'limit': limit.toString()});
      final data = response['data'] as List<dynamic>? ?? [];
      return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (e) {
      print('Error getting stored reports: $e');
      rethrow;
    }
  }
}

