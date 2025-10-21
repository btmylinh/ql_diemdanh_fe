import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'auth_repository.dart';
import 'user_provider.dart';

final authRepoProvider = Provider((ref) => AuthRepository());

class AuthState {
  const AuthState({this.loading = false, this.error});
  final bool loading;
  final String? error;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref) : super(const AuthState());
  final Ref ref;

  Future<bool> login(String email, String password) async {
    try {
      state = const AuthState(loading: true);
      debugPrint('[AUTH] Attempting login for: $email'); // Debug log
      final user = await ref.read(authRepoProvider).login(email, password);
      debugPrint('[AUTH] Login successful, user: $user'); // Debug log
      ref.read(userProvider.notifier).setUser(user);
      state = const AuthState();
      return true;
    } catch (e) {
      debugPrint('[AUTH] Login failed: $e'); // Debug log
      final message = e is Exception ? e.toString() : 'Đăng nhập thất bại';
      state = AuthState(error: message.replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<bool> register(Map<String, String?> data) async {
    try {
      state = const AuthState(loading: true);
      final user = await ref.read(authRepoProvider).register(
        email: data['email']!,
        password: data['password']!,
        name: data['name'],
        mssv: data['mssv'],
        clazz: data['class'],
        phone: data['phone'],
      );
      ref.read(userProvider.notifier).setUser(user);
      state = const AuthState();
      return true;
    } catch (e) {
      final message = e is Exception ? e.toString() : 'Đăng ký thất bại';
      state = AuthState(error: message.replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> bootstrapMe() async {
    try {
      final user = await ref.read(authRepoProvider).me();
      ref.read(userProvider.notifier).setUser(user);
    } catch (_) {
      // ignore silently if token invalid
    }
  }

  Future<void> logout() async {
    await ref.read(authRepoProvider).logout();
    ref.read(userProvider.notifier).clearUser();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);

