import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/change_password_service.dart';

class ChangePasswordState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final bool isPasswordChanged;

  const ChangePasswordState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.isPasswordChanged = false,
  });

  ChangePasswordState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    bool? isPasswordChanged,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      isPasswordChanged: isPasswordChanged ?? this.isPasswordChanged,
    );
  }
}

class ChangePasswordNotifier extends StateNotifier<ChangePasswordState> {
  ChangePasswordNotifier() : super(const ChangePasswordState());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final result = await ChangePasswordService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (result['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: result['message'],
          isPasswordChanged: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result['message'],
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Có lỗi xảy ra: ${e.toString()}',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(
      error: null,
      successMessage: null,
      isPasswordChanged: false,
    );
  }

  void reset() {
    state = const ChangePasswordState();
  }
}

final changePasswordProvider = StateNotifierProvider<ChangePasswordNotifier, ChangePasswordState>((ref) {
  return ChangePasswordNotifier();
});

/// Provider cho kiểm tra độ mạnh mật khẩu
final passwordStrengthProvider = StateProvider.family<Map<String, dynamic>, String>((ref, password) {
  return ChangePasswordService.validatePasswordStrength(password);
});
