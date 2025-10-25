import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/api_client.dart';

class ReportsService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy dữ liệu thống kê tổng quan từ backend reports API
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _apiClient.get('/reports/overview');
      final data = response['data'] as Map<String, dynamic>? ?? {};
      
      // Transform backend data to match frontend expectations
      return {
        'totalActivities': data['activities']?['total'] ?? 0,
        'activeActivities': data['activities']?['active'] ?? 0,
        'upcomingActivities': data['activities']?['upcoming'] ?? 0,
        'completedActivities': data['activities']?['completed'] ?? 0,
        'totalUsers': data['users']?['total'] ?? 0,
        'adminUsers': data['users']?['admin'] ?? 0,
        'managerUsers': data['users']?['manager'] ?? 0,
        'studentUsers': data['users']?['student'] ?? 0,
        'totalRegistrations': data['registrations']?['total'] ?? 0,
        'totalAttendances': data['attendances']?['total'] ?? 0,
      };
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu thống kê: ${e.toString()}');
    }
  }

  /// Lấy dữ liệu cho biểu đồ đăng ký theo thời gian từ backend
  Future<List<Map<String, dynamic>>> getRegistrationsTrend({DateTime? start, DateTime? end}) async {
    try {
      final queryParams = <String, String>{};
      if (start != null) queryParams['start'] = start.toIso8601String();
      if (end != null) queryParams['end'] = end.toIso8601String();
      
      final response = await _apiClient.get('/reports/registrations-trend', queryParams);
      final data = response['data'] as List<dynamic>? ?? [];
      
      return data.map((item) => {
        'date': item['date'],
        'count': item['count'],
      }).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu xu hướng đăng ký: ${e.toString()}');
    }
  }

  /// Lấy dữ liệu cho biểu đồ hoạt động theo trạng thái từ backend
  Future<List<Map<String, dynamic>>> getActivitiesByStatus() async {
    try {
      final response = await _apiClient.get('/reports/activities-status');
      final data = response['data'] as List<dynamic>? ?? [];
      
      return data.map((item) => {
        'status': item['status'],
        'count': item['count'],
        'label': _getStatusLabel(item['status'].toString()),
      }).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu hoạt động theo trạng thái: ${e.toString()}');
    }
  }

  /// Lấy dữ liệu cho biểu đồ top hoạt động từ backend
  Future<List<Map<String, dynamic>>> getTopActivities({int limit = 10}) async {
    try {
      final response = await _apiClient.get('/reports/top-activities', {'limit': limit.toString()});
      final data = response['data'] as List<dynamic>? ?? [];
      
      return data.map((item) => {
        'id': item['id'],
        'name': item['name'],
        'registrations': item['registrations'],
      }).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy dữ liệu top hoạt động: ${e.toString()}');
    }
  }

  /// Lấy dữ liệu chi tiết cho báo cáo
  Future<Map<String, dynamic>> getDetailedReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      switch (reportType) {
        case 'activities':
          return await _getActivitiesReport(startDate, endDate);
        case 'users':
          return await _getUsersReport(startDate, endDate);
        case 'attendances':
          return await _getAttendancesReport(startDate, endDate);
        case 'registrations':
          return await _getRegistrationsReport(startDate, endDate);
        default:
          throw Exception('Loại báo cáo không hợp lệ');
      }
    } catch (e) {
      throw Exception('Lỗi khi tạo báo cáo chi tiết: ${e.toString()}');
    }
  }

  /// Xuất báo cáo ra file CSV
  Future<String> exportToCSV({
    required String reportType,
    required List<Map<String, dynamic>> data,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${reportType}_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      // Tạo header cho CSV
      List<String> headers = _getCSVHeaders(reportType);
      
      // Tạo dữ liệu CSV
      List<List<dynamic>> csvData = [headers];
      
      for (final row in data) {
        List<dynamic> csvRow = _formatRowForCSV(row, reportType);
        csvData.add(csvRow);
      }

      // Ghi file CSV
      final csvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(csvString);

      return file.path;
    } catch (e) {
      throw Exception('Lỗi khi xuất CSV: ${e.toString()}');
    }
  }

  // Helper methods
  String _getStatusLabel(String status) {
    switch (status) {
      case '0': return 'Hoàn thành';
      case '1': return 'Đang diễn ra';
      case '2': return 'Sắp diễn ra';
      case 'present': return 'Có mặt';
      case 'absent': return 'Vắng mặt';
      case 'late': return 'Đi muộn';
      default: return status;
    }
  }


  Future<Map<String, dynamic>> _getActivitiesReport(DateTime? startDate, DateTime? endDate) async {
    final activities = await _apiClient.get('/activities');
    final activitiesList = activities['data'] as List<dynamic>? ?? [];

    List<dynamic> filteredActivities = activitiesList;
    
    if (startDate != null || endDate != null) {
      filteredActivities = activitiesList.where((activity) {
        final startTime = activity['startTime'] as String?;
        if (startTime == null) return false;
        
        final activityDate = DateTime.tryParse(startTime);
        if (activityDate == null) return false;
        
        if (startDate != null && activityDate.isBefore(startDate)) return false;
        if (endDate != null && activityDate.isAfter(endDate)) return false;
        
        return true;
      }).toList();
    }

    return {
      'data': filteredActivities,
      'total': filteredActivities.length,
      'summary': {
        'upcoming': filteredActivities.where((a) => a['status'] == 'upcoming').length,
        'active': filteredActivities.where((a) => a['status'] == 'active').length,
        'completed': filteredActivities.where((a) => a['status'] == 'completed').length,
        'cancelled': filteredActivities.where((a) => a['status'] == 'cancelled').length,
      }
    };
  }

  Future<Map<String, dynamic>> _getUsersReport(DateTime? startDate, DateTime? endDate) async {
    final users = await _apiClient.get('/users');
    final usersList = users['data'] as List<dynamic>? ?? [];

    return {
      'data': usersList,
      'total': usersList.length,
      'summary': {
        'admin': usersList.where((u) => u['role'] == 'admin').length,
        'manager': usersList.where((u) => u['role'] == 'manager').length,
        'student': usersList.where((u) => u['role'] == 'student').length,
      }
    };
  }

  Future<Map<String, dynamic>> _getAttendancesReport(DateTime? startDate, DateTime? endDate) async {
    final attendances = await _apiClient.get('/attendances');
    final attendancesList = attendances['data'] as List<dynamic>? ?? [];

    List<dynamic> filteredAttendances = attendancesList;
    
    if (startDate != null || endDate != null) {
      filteredAttendances = attendancesList.where((attendance) {
        final checkedInAt = attendance['checkedInAt'] as String?;
        if (checkedInAt == null) return false;
        
        final attendanceDate = DateTime.tryParse(checkedInAt);
        if (attendanceDate == null) return false;
        
        if (startDate != null && attendanceDate.isBefore(startDate)) return false;
        if (endDate != null && attendanceDate.isAfter(endDate)) return false;
        
        return true;
      }).toList();
    }

    return {
      'data': filteredAttendances,
      'total': filteredAttendances.length,
      'summary': {
        'present': filteredAttendances.where((a) => a['status'] == 'present').length,
        'absent': filteredAttendances.where((a) => a['status'] == 'absent').length,
        'late': filteredAttendances.where((a) => a['status'] == 'late').length,
      }
    };
  }

  Future<Map<String, dynamic>> _getRegistrationsReport(DateTime? startDate, DateTime? endDate) async {
    final registrations = await _apiClient.get('/registrations');
    final registrationsList = registrations['data'] as List<dynamic>? ?? [];

    List<dynamic> filteredRegistrations = registrationsList;
    
    if (startDate != null || endDate != null) {
      filteredRegistrations = registrationsList.where((registration) {
        final registeredAt = registration['registeredAt'] as String?;
        if (registeredAt == null) return false;
        
        final registrationDate = DateTime.tryParse(registeredAt);
        if (registrationDate == null) return false;
        
        if (startDate != null && registrationDate.isBefore(startDate)) return false;
        if (endDate != null && registrationDate.isAfter(endDate)) return false;
        
        return true;
      }).toList();
    }

    return {
      'data': filteredRegistrations,
      'total': filteredRegistrations.length,
      'summary': {
        'total': filteredRegistrations.length,
      }
    };
  }

  List<String> _getCSVHeaders(String reportType) {
    switch (reportType) {
      case 'activities':
        return ['ID', 'Tiêu đề', 'Mô tả', 'Thời gian bắt đầu', 'Thời gian kết thúc', 'Trạng thái', 'Địa điểm'];
      case 'users':
        return ['ID', 'Tên', 'Email', 'Vai trò', 'Ngày tạo'];
      case 'attendances':
        return ['ID', 'User ID', 'Activity ID', 'Trạng thái', 'Thời gian điểm danh'];
      case 'registrations':
        return ['ID', 'User ID', 'Activity ID', 'Thời gian đăng ký'];
      default:
        return [];
    }
  }

  List<dynamic> _formatRowForCSV(Map<String, dynamic> row, String reportType) {
    switch (reportType) {
      case 'activities':
        return [
          row['id'] ?? '',
          row['title'] ?? '',
          row['description'] ?? '',
          row['startTime'] ?? '',
          row['endTime'] ?? '',
          row['status'] ?? '',
          row['location'] ?? '',
        ];
      case 'users':
        return [
          row['id'] ?? '',
          row['name'] ?? '',
          row['email'] ?? '',
          row['role'] ?? '',
          row['createdAt'] ?? '',
        ];
      case 'attendances':
        return [
          row['id'] ?? '',
          row['userId'] ?? '',
          row['activityId'] ?? '',
          row['status'] ?? '',
          row['checkedInAt'] ?? '',
        ];
      case 'registrations':
        return [
          row['id'] ?? '',
          row['userId'] ?? '',
          row['activityId'] ?? '',
          row['registeredAt'] ?? '',
        ];
      default:
        return [];
    }
  }
}
