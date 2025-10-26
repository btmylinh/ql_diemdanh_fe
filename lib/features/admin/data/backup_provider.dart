import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) => BackupService());

final backupStateProvider = StateNotifierProvider<BackupStateNotifier, BackupState>((ref) {
  return BackupStateNotifier(ref.read(backupServiceProvider));
});

class BackupState {
  final bool isLoading;
  final String? message;
  final bool isSuccess;
  final String? filePath;
  final List<String>? warnings;
  final Map<String, dynamic>? metadata;
  final double? progress;

  const BackupState({
    this.isLoading = false,
    this.message,
    this.isSuccess = false,
    this.filePath,
    this.warnings,
    this.metadata,
    this.progress,
  });

  BackupState copyWith({
    bool? isLoading,
    String? message,
    bool? isSuccess,
    String? filePath,
    List<String>? warnings,
    Map<String, dynamic>? metadata,
    double? progress,
  }) {
    return BackupState(
      isLoading: isLoading ?? this.isLoading,
      message: message ?? this.message,
      isSuccess: isSuccess ?? this.isSuccess,
      filePath: filePath ?? this.filePath,
      warnings: warnings ?? this.warnings,
      metadata: metadata ?? this.metadata,
      progress: progress ?? this.progress,
    );
  }
}

class BackupStateNotifier extends StateNotifier<BackupState> {
  final BackupService _backupService;

  BackupStateNotifier(this._backupService) : super(const BackupState());

  Future<void> createBackup() async {
    state = state.copyWith(isLoading: true, progress: 0.0);
    
    try {
      // Simulate progress updates
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        state = state.copyWith(progress: i / 100.0);
      }

      final result = await _backupService.createBackup();
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: result.success,
        message: result.message,
        filePath: result.filePath,
        metadata: result.metadata,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        message: 'Lỗi không mong muốn: ${e.toString()}',
        progress: 0.0,
      );
    }
  }

  Future<void> restoreFromFile() async {
    state = state.copyWith(isLoading: true, progress: 0.0);
    
    try {
      // Simulate progress updates
      for (int i = 0; i <= 100; i += 20) {
        await Future.delayed(const Duration(milliseconds: 200));
        state = state.copyWith(progress: i / 100.0);
      }

      final result = await _backupService.restoreFromFile();
      
      state = state.copyWith(
        isLoading: false,
        isSuccess: result.success,
        message: result.message,
        warnings: result.warnings,
        metadata: result.metadata,
        progress: 1.0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        message: 'Lỗi không mong muốn: ${e.toString()}',
        progress: 0.0,
      );
    }
  }


  void clearState() {
    state = const BackupState();
  }
}
