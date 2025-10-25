import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'reports_service.dart';

final reportsServiceProvider = Provider<ReportsService>((ref) => ReportsService());

final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(reportsServiceProvider);
  return await service.getDashboardStats();
});

final registrationsTrendProvider = FutureProvider.family<List<Map<String, dynamic>>, ({DateTime? start, DateTime? end})>((ref, params) async {
  final service = ref.read(reportsServiceProvider);
  return await service.getRegistrationsTrend(start: params.start, end: params.end);
});

final activitiesByStatusProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(reportsServiceProvider);
  return await service.getActivitiesByStatus();
});

final topActivitiesProvider = FutureProvider.family<List<Map<String, dynamic>>, int>((ref, limit) async {
  final service = ref.read(reportsServiceProvider);
  return await service.getTopActivities(limit: limit);
});

final reportsStateProvider = StateNotifierProvider<ReportsStateNotifier, ReportsState>((ref) {
  return ReportsStateNotifier(ref.read(reportsServiceProvider));
});

class ReportsState {
  final bool isLoading;
  final String? message;
  final bool isSuccess;
  final String? filePath;
  final Map<String, dynamic>? reportData;
  final DateTime? startDate;
  final DateTime? endDate;
  final String selectedReportType;

  const ReportsState({
    this.isLoading = false,
    this.message,
    this.isSuccess = false,
    this.filePath,
    this.reportData,
    this.startDate,
    this.endDate,
    this.selectedReportType = 'activities',
  });

  ReportsState copyWith({
    bool? isLoading,
    String? message,
    bool? isSuccess,
    String? filePath,
    Map<String, dynamic>? reportData,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedReportType,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      isSuccess: isSuccess ?? this.isSuccess,
      filePath: filePath ?? this.filePath,
      reportData: reportData ?? this.reportData,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedReportType: selectedReportType ?? this.selectedReportType,
    );
  }
}

class ReportsStateNotifier extends StateNotifier<ReportsState> {
  final ReportsService _reportsService;

  ReportsStateNotifier(this._reportsService) : super(const ReportsState());

  Future<void> generateReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(
      isLoading: true,
      selectedReportType: reportType,
      startDate: startDate,
      endDate: endDate,
    );

    try {
      final reportData = await _reportsService.getDetailedReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        reportData: reportData,
        message: 'Báo cáo đã được tạo thành công',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        message: 'Lỗi khi tạo báo cáo: ${e.toString()}',
      );
    }
  }

  Future<void> exportToCSV({
    required String reportType,
    required List<Map<String, dynamic>> data,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final filePath = await _reportsService.exportToCSV(
        reportType: reportType,
        data: data,
        startDate: startDate,
        endDate: endDate,
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        filePath: filePath,
        message: 'Xuất CSV thành công! File đã được lưu tại: $filePath',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        message: 'Lỗi khi xuất CSV: ${e.toString()}',
      );
    }
  }

  void clearState() {
    state = const ReportsState();
  }

  void setDateRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  void setReportType(String reportType) {
    state = state.copyWith(selectedReportType: reportType);
  }
}
