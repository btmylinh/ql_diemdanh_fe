
class BackupValidationService {
  /// Validate backup data structure
  static bool validateBackupStructure(Map<String, dynamic> data) {
    try {
      // Check required top-level keys
      if (!data.containsKey('version') || 
          !data.containsKey('createdAt') || 
          !data.containsKey('data') ||
          !data.containsKey('metadata')) {
        return false;
      }

      // Check data structure
      final dataSection = data['data'] as Map<String, dynamic>?;
      if (dataSection == null) return false;

      // Check if all required data sections exist
      final requiredSections = ['activities', 'users', 'registrations', 'attendances'];
      for (final section in requiredSections) {
        if (!dataSection.containsKey(section)) return false;
        
        final sectionData = dataSection[section];
        if (sectionData is! Map<String, dynamic>) return false;
        if (!sectionData.containsKey('data')) return false;
        if (sectionData['data'] is! List) return false;
      }

      // Check metadata structure
      final metadata = data['metadata'] as Map<String, dynamic>?;
      if (metadata == null) return false;

      final requiredMetadata = ['totalActivities', 'totalUsers', 'totalRegistrations', 'totalAttendances'];
      for (final key in requiredMetadata) {
        if (!metadata.containsKey(key)) return false;
        if (metadata[key] is! int) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate individual data items
  static List<String> validateDataItems(List<dynamic> items, String dataType) {
    final errors = <String>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map<String, dynamic>) {
        errors.add('$dataType[$i]: Invalid data structure');
        continue;
      }

      switch (dataType) {
        case 'activities':
          _validateActivity(item, i, errors);
          break;
        case 'users':
          _validateUser(item, i, errors);
          break;
        case 'registrations':
          _validateRegistration(item, i, errors);
          break;
        case 'attendances':
          _validateAttendance(item, i, errors);
          break;
      }
    }

    return errors;
  }

  static void _validateActivity(Map<String, dynamic> activity, int index, List<String> errors) {
    final requiredFields = ['id', 'title', 'description', 'startTime', 'endTime', 'status'];
    for (final field in requiredFields) {
      if (!activity.containsKey(field)) {
        errors.add('Activity[$index]: Missing required field "$field"');
      }
    }

    // Validate status
    final status = activity['status'] as String?;
    if (status != null && !['upcoming', 'active', 'completed', 'cancelled'].contains(status)) {
      errors.add('Activity[$index]: Invalid status "$status"');
    }

    // Validate dates
    final startTime = activity['startTime'] as String?;
    final endTime = activity['endTime'] as String?;
    
    if (startTime != null && DateTime.tryParse(startTime) == null) {
      errors.add('Activity[$index]: Invalid startTime format');
    }
    
    if (endTime != null && DateTime.tryParse(endTime) == null) {
      errors.add('Activity[$index]: Invalid endTime format');
    }
  }

  static void _validateUser(Map<String, dynamic> user, int index, List<String> errors) {
    final requiredFields = ['id', 'name', 'email', 'role'];
    for (final field in requiredFields) {
      if (!user.containsKey(field)) {
        errors.add('User[$index]: Missing required field "$field"');
      }
    }

    // Validate role
    final role = user['role'] as String?;
    if (role != null && !['admin', 'manager', 'student'].contains(role)) {
      errors.add('User[$index]: Invalid role "$role"');
    }

    // Validate email format
    final email = user['email'] as String?;
    if (email != null && !_isValidEmail(email)) {
      errors.add('User[$index]: Invalid email format');
    }
  }

  static void _validateRegistration(Map<String, dynamic> registration, int index, List<String> errors) {
    final requiredFields = ['id', 'userId', 'activityId', 'registeredAt'];
    for (final field in requiredFields) {
      if (!registration.containsKey(field)) {
        errors.add('Registration[$index]: Missing required field "$field"');
      }
    }

    // Validate dates
    final registeredAt = registration['registeredAt'] as String?;
    if (registeredAt != null && DateTime.tryParse(registeredAt) == null) {
      errors.add('Registration[$index]: Invalid registeredAt format');
    }
  }

  static void _validateAttendance(Map<String, dynamic> attendance, int index, List<String> errors) {
    final requiredFields = ['id', 'userId', 'activityId', 'status', 'checkedInAt'];
    for (final field in requiredFields) {
      if (!attendance.containsKey(field)) {
        errors.add('Attendance[$index]: Missing required field "$field"');
      }
    }

    // Validate status
    final status = attendance['status'] as String?;
    if (status != null && !['present', 'absent', 'late'].contains(status)) {
      errors.add('Attendance[$index]: Invalid status "$status"');
    }

    // Validate dates
    final checkedInAt = attendance['checkedInAt'] as String?;
    if (checkedInAt != null && DateTime.tryParse(checkedInAt) == null) {
      errors.add('Attendance[$index]: Invalid checkedInAt format');
    }
  }

  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Get backup file size in human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if backup is compatible with current system
  static bool isBackupCompatible(Map<String, dynamic> data) {
    final version = data['version'] as String?;
    if (version == null) return false;
    
    // For now, accept version 1.0.0
    return version == '1.0.0';
  }
}
