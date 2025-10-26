import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/periodic_report_service.dart';

/// Provider cho báo cáo định kỳ
final periodicReportProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await PeriodicReportService.getAllPeriodicReports();
});

/// Provider cho báo cáo tuần
final weeklyReportProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await PeriodicReportService.getPeriodicReport('weekly');
});

/// Provider cho báo cáo tháng
final monthlyReportProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await PeriodicReportService.getPeriodicReport('monthly');
});

/// Provider cho báo cáo năm
final yearlyReportProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return await PeriodicReportService.getPeriodicReport('yearly');
});

/// Provider cho trạng thái tạo báo cáo
final reportGenerationStateProvider = StateProvider<bool>((ref) => false);

/// Provider cho lịch tạo báo cáo tự động
final reportSchedulerProvider = FutureProvider<void>((ref) async {
  await PeriodicReportService.schedulePeriodicReports();
});

/// Notifier cho quản lý báo cáo định kỳ
class PeriodicReportNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  PeriodicReportNotifier() : super(const AsyncValue.loading());

  /// Tải tất cả báo cáo
  Future<void> loadReports() async {
    state = const AsyncValue.loading();
    try {
      final reports = await PeriodicReportService.getAllPeriodicReports();
      state = AsyncValue.data(reports);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Tạo báo cáo mới
  Future<void> generateReports() async {
    try {
      await PeriodicReportService.generatePeriodicReports();
      await loadReports(); // Tải lại danh sách báo cáo
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Lấy báo cáo theo kỳ
  Future<Map<String, dynamic>?> getReportByPeriod(String period) async {
    return await PeriodicReportService.getPeriodicReport(period);
  }

  /// Kiểm tra xem có cần tạo báo cáo mới không
  Future<bool> shouldGenerateNewReport() async {
    return await PeriodicReportService.shouldGenerateNewReport();
  }

  /// Dọn dẹp báo cáo cũ
  Future<void> cleanupOldReports() async {
    await PeriodicReportService.cleanupOldReports();
    await loadReports(); // Tải lại danh sách báo cáo
  }
}

/// Provider cho PeriodicReportNotifier
final periodicReportNotifierProvider = StateNotifierProvider<PeriodicReportNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return PeriodicReportNotifier();
});

/// Provider cho báo cáo theo vai trò
final roleBasedReportProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, role) async {
  // Tùy theo vai trò, trả về dữ liệu báo cáo phù hợp
  switch (role) {
    case 'student':
      return {
        'role': 'student',
        'title': 'Báo cáo cá nhân',
        'metrics': {
          'registrations': 0,
          'attendances': 0,
          'points': 0,
          'activities_joined': 0,
        },
        'trends': {
          'weekly_participation': [],
          'monthly_participation': [],
        },
      };
    case 'manager':
      return {
        'role': 'manager',
        'title': 'Báo cáo quản lý',
        'metrics': {
          'activities_created': 0,
          'total_registrations': 0,
          'total_attendances': 0,
          'active_activities': 0,
        },
        'trends': {
          'activity_creation': [],
          'registration_trends': [],
        },
      };
    case 'admin':
      return {
        'role': 'admin',
        'title': 'Báo cáo hệ thống',
        'metrics': {
          'total_users': 0,
          'total_activities': 0,
          'total_registrations': 0,
          'total_attendances': 0,
          'system_health': 'good',
        },
        'trends': {
          'user_growth': [],
          'activity_trends': [],
          'system_performance': [],
        },
      };
    default:
      return {};
  }
});

/// Provider cho thống kê tổng quan
final overviewStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Mock data - trong thực tế sẽ gọi API
  return {
    'total_activities': 150,
    'active_activities': 25,
    'total_users': 500,
    'total_registrations': 1200,
    'total_attendances': 800,
    'total_points': 2400,
    'growth_rate': 15.5,
    'engagement_rate': 75.2,
  };
});

/// Provider cho xu hướng theo thời gian
final timeTrendsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Mock data - trong thực tế sẽ gọi API
  return {
    'weekly': {
      'activities': [5, 8, 3, 12, 7, 9, 6],
      'registrations': [15, 25, 10, 35, 20, 28, 18],
      'attendances': [12, 20, 8, 30, 16, 25, 15],
    },
    'monthly': {
      'activities': [25, 30, 35, 28, 32, 40],
      'registrations': [120, 150, 180, 140, 160, 200],
      'attendances': [100, 125, 150, 120, 140, 175],
    },
    'yearly': {
      'activities': [300, 350, 400, 450],
      'registrations': [1500, 1800, 2100, 2400],
      'attendances': [1200, 1450, 1700, 1950],
    },
  };
});

/// Provider cho top hoạt động
final topActivitiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Mock data - trong thực tế sẽ gọi API
  return [
    {
      'id': 1,
      'name': 'Hội thảo công nghệ',
      'registrations': 150,
      'attendances': 120,
      'points': 300,
    },
    {
      'id': 2,
      'name': 'Workshop lập trình',
      'registrations': 120,
      'attendances': 100,
      'points': 250,
    },
    {
      'id': 3,
      'name': 'Cuộc thi hackathon',
      'registrations': 80,
      'attendances': 70,
      'points': 200,
    },
  ];
});

/// Provider cho thống kê người dùng
final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Mock data - trong thực tế sẽ gọi API
  return {
    'total_users': 500,
    'active_users': 350,
    'new_users_this_month': 50,
    'user_engagement': 75.2,
    'role_distribution': {
      'students': 400,
      'managers': 80,
      'admins': 20,
    },
    'activity_participation': {
      'high': 120,
      'medium': 200,
      'low': 180,
    },
  };
});
