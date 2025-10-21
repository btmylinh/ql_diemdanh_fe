import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class UserState {
  final Map<String, dynamic>? user;
  final bool loading;
  final String? error;

  const UserState({
    this.user,
    this.loading = false,
    this.error,
  });

  UserState copyWith({
    Map<String, dynamic>? user,
    bool? loading,
    String? error,
  }) {
    return UserState(
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }

  String? get role => user?['role']?.toString();
  String? get name => user?['name'];
  String? get email => user?['email'];
  bool get isStudent => role?.toLowerCase() == 'student';
  bool get isManager => role?.toLowerCase() == 'manager';
  bool get isAdmin => role?.toLowerCase() == 'admin';
  bool get canCreateActivity => isManager || isAdmin;
  bool get canManageUsers => isAdmin;
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(this.ref) : super(const UserState()) {
    _loadUser();
  }
  
  final Ref ref;
  final _storage = const FlutterSecureStorage();

  Future<void> _loadUser() async {
    state = state.copyWith(loading: true);
    try {
      final userJson = await _storage.read(key: 'user_json');
      if (userJson != null) {
        final user = Map<String, dynamic>.from(jsonDecode(userJson));
        state = state.copyWith(user: user, loading: false);
        debugPrint('[USER] Loaded user: ${user['name']} (${user['role']})'); // Debug log
      } else {
        state = state.copyWith(loading: false);
        debugPrint('[USER] No user data found'); // Debug log
      }
    } catch (e) {
      state = state.copyWith(error: 'Không thể tải thông tin user', loading: false);
      debugPrint('[USER] Error loading user: $e'); // Debug log
    }
  }

  void setUser(Map<String, dynamic> user) {
    state = state.copyWith(user: user);
  }

  void clearUser() {
    state = const UserState();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(ref),
);
