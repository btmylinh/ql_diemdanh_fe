import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../../theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: Stack(
        children: [

          // Form đăng nhập ở giữa
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _form,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo hoặc hình biểu tượng
                        Image.asset(
                          'assets/dtm.png',
                          height: 90,
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'HỆ THỐNG HOẠT ĐỘNG KHOA CNTT',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                color: kGreen,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 24),

                        // 
                        // Email
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            if (state.error != null) {
                              ref.read(authControllerProvider.notifier).clearError();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined, color: kGreen),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Vui lòng nhập email hợp lệ'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        TextFormField(
                          controller: _password,
                          obscureText: _obscure,
                          onChanged: (value) {
                            if (state.error != null) {
                              ref.read(authControllerProvider.notifier).clearError();
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock_outline, color: kGreen),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey[700],
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 6) ? 'Mật khẩu ít nhất 6 ký tự' : null,
                        ),
                        const SizedBox(height: 24),

                        //  Nút đăng nhập
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: state.loading
                                ? null
                                : () async {
                                    if (_form.currentState!.validate()) {
                                      final ok = await ref
                                          .read(authControllerProvider.notifier)
                                          .login(_email.text.trim(), _password.text);
                                      if (!mounted) return;
                                      if (ok) {
                                        context.go('/home');
                                      }
                                    }
                                  },
                            child: state.loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        //  Đăng ký
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text(
                            'Chưa có tài khoản? Đăng ký ngay',
                            style: TextStyle(color: kGreen),
                          ),
                        ),

                        if (state.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  state.error!.contains('kết nối') || state.error!.contains('mạng')
                                      ? Icons.wifi_off
                                      : Icons.error_outline,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
