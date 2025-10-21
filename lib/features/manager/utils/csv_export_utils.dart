import 'dart:convert';

class CSVExportUtils {
  // Export registrations to CSV format
  static String exportRegistrationsToCSV(List<Map<String, dynamic>> registrations) {
    if (registrations.isEmpty) {
      return 'Tên,Email,MSSV,Lớp,Hoạt động,Trạng thái,Ngày đăng ký\n';
    }

    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Tên,Email,MSSV,Lớp,Hoạt động,Trạng thái,Ngày đăng ký');
    
    // CSV Data
    for (final registration in registrations) {
      final user = registration['user'] as Map<String, dynamic>? ?? {};
      final activity = registration['activity'] as Map<String, dynamic>? ?? {};
      final status = registration['status'] as String? ?? '0';
      final createdAt = registration['created_at'] as String? ?? '';
      
      final name = _escapeCSVField(user['name'] ?? 'N/A');
      final email = _escapeCSVField(user['email'] ?? 'N/A');
      final mssv = _escapeCSVField(user['mssv'] ?? 'N/A');
      final className = _escapeCSVField(user['class'] ?? 'N/A');
      final activityName = _escapeCSVField(activity['name'] ?? 'N/A');
      final statusText = _getStatusText(status);
      final dateText = _formatDateForCSV(createdAt);
      
      buffer.writeln('$name,$email,$mssv,$className,$activityName,$statusText,$dateText');
    }
    
    return buffer.toString();
  }

  // Export activities to CSV format
  static String exportActivitiesToCSV(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return 'Tên,Mô tả,Địa điểm,Thời gian bắt đầu,Thời gian kết thúc,Số lượng tối đa,Điểm rèn luyện,Hạn đăng ký,Trạng thái,Người tạo,Ngày tạo\n';
    }

    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Tên,Mô tả,Địa điểm,Thời gian bắt đầu,Thời gian kết thúc,Số lượng tối đa,Điểm rèn luyện,Hạn đăng ký,Trạng thái,Người tạo,Ngày tạo');
    
    // CSV Data
    for (final activity in activities) {
      final creator = activity['creator'] as Map<String, dynamic>? ?? {};
      
      final name = _escapeCSVField(activity['name'] ?? 'N/A');
      final description = _escapeCSVField(activity['description'] ?? '');
      final location = _escapeCSVField(activity['location'] ?? '');
      final startTime = _formatDateForCSV(activity['start_time'] ?? '');
      final endTime = _formatDateForCSV(activity['end_time'] ?? '');
      final maxParticipants = activity['max_participants']?.toString() ?? 'Không giới hạn';
      final trainingPoints = activity['training_points']?.toString() ?? '0';
      final registrationDeadline = _formatDateForCSV(activity['registration_deadline'] ?? '');
      final statusText = _getActivityStatusText(activity['status'] as int? ?? 0);
      final creatorName = _escapeCSVField(creator['name'] ?? 'N/A');
      final createdAt = _formatDateForCSV(activity['created_at'] ?? '');
      
      buffer.writeln('$name,$description,$location,$startTime,$endTime,$maxParticipants,$trainingPoints,$registrationDeadline,$statusText,$creatorName,$createdAt');
    }
    
    return buffer.toString();
  }

  // Export attendance to CSV format
  static String exportAttendanceToCSV(List<Map<String, dynamic>> attendances) {
    if (attendances.isEmpty) {
      return 'Tên,MSSV,Lớp,Email,Hoạt động,Thời gian điểm danh,Trạng thái\n';
    }

    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Tên,MSSV,Lớp,Email,Hoạt động,Thời gian điểm danh,Trạng thái');
    
    // CSV Data
    for (final attendance in attendances) {
      final user = attendance['user'] as Map<String, dynamic>? ?? {};
      final activity = attendance['activity'] as Map<String, dynamic>? ?? {};
      final status = attendance['status'] as String? ?? '0';
      final createdAt = attendance['created_at'] as String? ?? '';
      
      final name = _escapeCSVField(user['name'] ?? 'N/A');
      final mssv = _escapeCSVField(user['mssv'] ?? 'N/A');
      final className = _escapeCSVField(user['class'] ?? 'N/A');
      final email = _escapeCSVField(user['email'] ?? 'N/A');
      final activityName = _escapeCSVField(activity['name'] ?? 'N/A');
      final dateText = _formatDateForCSV(createdAt);
      final statusText = _getAttendanceStatusText(status);
      
      buffer.writeln('$name,$mssv,$className,$email,$activityName,$dateText,$statusText');
    }
    
    return buffer.toString();
  }

  // Helper methods
  static String _escapeCSVField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _formatDateForCSV(String dateString) {
    if (dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  static String _getStatusText(String status) {
    switch (status) {
      case '1':
        return 'Đã đăng ký';
      case '0':
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  static String _getActivityStatusText(int status) {
    switch (status) {
      case 1:
        return 'Đang diễn ra';
      case 2:
        return 'Sắp diễn ra';
      case 3:
        return 'Đã hoàn thành';
      case 0:
        return 'Đã hủy';
      default:
        return 'Không xác định';
    }
  }

  static String _getAttendanceStatusText(String status) {
    switch (status) {
      case '1':
        return 'Có mặt';
      case '0':
        return 'Vắng mặt';
      default:
        return 'Không xác định';
    }
  }

  // Convert CSV string to bytes for file saving
  static List<int> csvStringToBytes(String csvString) {
    return utf8.encode(csvString);
  }

  // Generate filename with timestamp
  static String generateFilename(String prefix, String extension) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${prefix}_$timestamp.$extension';
  }
}
