import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/api_client.dart';

class ChangePasswordService {
  static final Dio _dio = buildDio();

  /// Đổi mật khẩu
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (newPassword != confirmPassword) {
        throw Exception('Mật khẩu mới và xác nhận mật khẩu không khớp');
      }

      if (newPassword.length < 6) {
        throw Exception('Mật khẩu mới phải có ít nhất 6 ký tự');
      }

      final response = await _dio.put('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      return {
        'success': true,
        'message': response.data['message'] ?? 'Đổi mật khẩu thành công',
        'data': response.data,
      };
    } on DioException catch (e) {
      String errorMessage = 'Có lỗi xảy ra khi đổi mật khẩu';
      
      if (e.response?.statusCode == 400) {
        errorMessage = e.response?.data['message'] ?? 'Mật khẩu hiện tại không đúng';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại';
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Lỗi máy chủ, vui lòng thử lại sau';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Kết nối mạng không ổn định, vui lòng thử lại';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Không thể kết nối đến máy chủ';
      }

      debugPrint('Change password error: ${e.message}');
      return {
        'success': false,
        'message': errorMessage,
        'error': e.toString(),
      };
    } catch (e) {
      debugPrint('Change password error: $e');
      return {
        'success': false,
        'message': 'Có lỗi xảy ra: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  /// Kiểm tra độ mạnh mật khẩu
  static Map<String, dynamic> validatePasswordStrength(String password) {
    final hasMinLength = password.length >= 6;
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasNumbers = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int score = 0;
    if (hasMinLength) score++;
    if (hasUpperCase) score++;
    if (hasLowerCase) score++;
    if (hasNumbers) score++;
    if (hasSpecialChar) score++;

    String strength = 'Yếu';
    Color strengthColor = Colors.red;
    
    if (score >= 4) {
      strength = 'Mạnh';
      strengthColor = Colors.green;
    } else if (score >= 3) {
      strength = 'Trung bình';
      strengthColor = Colors.orange;
    }

    return {
      'score': score,
      'strength': strength,
      'strengthColor': strengthColor,
      'hasMinLength': hasMinLength,
      'hasUpperCase': hasUpperCase,
      'hasLowerCase': hasLowerCase,
      'hasNumbers': hasNumbers,
      'hasSpecialChar': hasSpecialChar,
    };
  }
}
