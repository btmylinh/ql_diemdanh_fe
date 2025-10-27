import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../core/api_client.dart';

class AdminUsersState {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String roleFilter;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.roleFilter = 'all',
  });

  AdminUsersState copyWith({
    List<Map<String, dynamic>>? users,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? roleFilter,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
    );
  }
}

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  AdminUsersNotifier(this.ref) : super(const AdminUsersState());

  final Ref ref;
  final ApiClient _apiClient = ApiClient();

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final queryParams = <String, String>{
        'page': '1',
        'limit': '100',
        if (state.searchQuery.isNotEmpty) 'search': state.searchQuery,
        if (state.roleFilter != 'all') 'role': state.roleFilter,
      };

      final response = await _apiClient.get('/users', queryParams);
      
      if (response['data'] != null) {
        final users = List<Map<String, dynamic>>.from(response['data']);
        state = state.copyWith(users: users, isLoading: false);
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể tải danh sách người dùng',
          isLoading: false,
        );
      }
    } catch (e) {
      debugPrint('[ADMIN_USERS] Error loading users: $e');
      state = state.copyWith(
        error: 'Lỗi kết nối: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  void searchUsers(String query) {
    state = state.copyWith(searchQuery: query);
    loadUsers();
  }

  void filterByRole(String role) {
    state = state.copyWith(roleFilter: role);
    loadUsers();
  }

  Future<Map<String, dynamic>?> createUser(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.post('/users', payload);
      if (response['data'] != null) {
        // prepend new user
        final updated = [response['data'] as Map<String, dynamic>, ...state.users];
        state = state.copyWith(users: updated, error: null);
        return response['data'];
      }
      // Parse error message from backend
      String errorMsg = 'Không thể tạo người dùng';
      if (response['message']) {
        errorMsg = response['message'];
      } else if (response['error']?['message']) {
        errorMsg = response['error']['message'];
      }
      state = state.copyWith(error: errorMsg);
      return null;
    } catch (e) {
      state = state.copyWith(error: 'Lỗi: ${e.toString()}');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateUser(dynamic userId, Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.put('/users/$userId', payload);
      if (response['data'] != null) {
        final updatedUsers = state.users
            .map<Map<String, dynamic>>((u) => u['id'] == userId
                ? {...u, ...(response['data'] as Map<String, dynamic>)}
                : u)
            .toList();
        
        state = state.copyWith(users: updatedUsers);
        return response['data'];
      }
      state = state.copyWith(error: response['message'] ?? 'Không thể cập nhật người dùng');
      return null;
    } catch (e) {
      debugPrint('[ADMIN_USERS] Error updating user: $e');
      state = state.copyWith(error: 'Lỗi: ${e.toString()}');
      return null;
    }
  }

  Future<void> deleteUser(dynamic userId) async {
    try {
      final response = await _apiClient.delete('/users/$userId');

      if (response['message'] != null) {
        // Remove user from local state
        final updatedUsers = state.users.where((u) => u['id'] != userId).toList();
        state = state.copyWith(users: updatedUsers);
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể xóa người dùng',
        );
      }
    } catch (e) {
      debugPrint('[ADMIN_USERS] Error deleting user: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
    }
  }

  Future<bool> updateUserRole(dynamic userId, String newRole) async {
    try {
      final response = await _apiClient.put(
        '/users/$userId',
        {'role': newRole},
      );

      if (response['data'] != null) {
        // Update user in local state
        final updatedUsers = state.users.map((u) {
          if (u['id'] == userId) {
            return {...u, 'role': newRole};
          }
          return u;
        }).toList();
        
        state = state.copyWith(users: updatedUsers);
        return true;
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể cập nhật vai trò người dùng',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[ADMIN_USERS] Error updating user role: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> resetUserPassword(dynamic userId, String newPassword) async {
    try {
      final response = await _apiClient.put(
        '/users/$userId/reset-password',
        {'password': newPassword},
      );

      if (response['message'] != null) {
        return true;
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể reset mật khẩu',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[ADMIN_USERS] Error resetting user password: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> toggleUserStatus(dynamic userId) async {
    try {
      // Get current user status
      final currentUser = state.users.firstWhere((u) => u['id'] == userId);
      final currentStatus = currentUser['status'] ?? 1;
      
      // Toggle between active (1) and inactive (0)
      final newStatus = currentStatus == 1 ? 0 : 1;
      
      final response = await _apiClient.patch(
        '/users/$userId/status',
        {'status': newStatus},
      );

      if (response['data'] != null) {
        // Update user in local state
        final updatedUsers = state.users.map((u) {
          if (u['id'] == userId) {
            return {...u, 'status': newStatus};
          }
          return u;
        }).toList();
        state = state.copyWith(users: updatedUsers);
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể thay đổi trạng thái người dùng',
        );
      }
    } catch (e) {
      debugPrint('[ADMIN_USERS] Error toggling user status: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
    }
  }

  Future<bool> changeUserStatus(dynamic userId, int status) async {
    try {
      final response = await _apiClient.patch(
        '/users/$userId/status',
        {'status': status},
      );

      if (response['data'] != null) {
        // Update user in local state
        final updatedUsers = state.users.map((u) {
          if (u['id'] == userId) {
            return {...u, 'status': status};
          }
          return u;
        }).toList();
        
        state = state.copyWith(users: updatedUsers);
        return true;
      } else {
        state = state.copyWith(
          error: response['message'] ?? 'Không thể thay đổi trạng thái người dùng',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[ADMIN_USERS] Error changing user status: $e');
      state = state.copyWith(
        error: 'Lỗi: ${e.toString()}',
      );
      return false;
    }
  }
}

final adminUsersProvider = StateNotifierProvider<AdminUsersNotifier, AdminUsersState>(
  (ref) => AdminUsersNotifier(ref),
);
