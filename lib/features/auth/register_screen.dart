import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _mssv = TextEditingController();
  final _clazz = TextEditingController();
  final _phone = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Scaffold(
      body: Stack(
        children: [

          // Form đăng ký giữa màn hình
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
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
                        // Logo 
                        Image.asset(
                          'assets/dtm.png',
                          height: 90,
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'ĐĂNG KÝ TÀI KHOẢN SINH VIÊN',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: kGreen,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        //  Form fields
                        _tf('Họ tên', _name,
                            icon: Icons.person_outline,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Họ tên là bắt buộc' : null),
                        const SizedBox(height: 12),

                        _tf('Email', _email,
                            icon: Icons.email_outlined,
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'Email không hợp lệ'
                                : null),
                        const SizedBox(height: 12),

                        _tf('Mã số sinh viên (MSSV)', _mssv, icon: Icons.badge_outlined),
                        const SizedBox(height: 12),

                        _tf('Lớp', _clazz, icon: Icons.class_outlined),
                        const SizedBox(height: 12),

                        _tf('Số điện thoại', _phone, icon: Icons.phone_outlined),
                        const SizedBox(height: 12),

                        _pf('Mật khẩu', _password),
                        const SizedBox(height: 12),

                        _pf('Nhập lại mật khẩu', _confirm),
                        const SizedBox(height: 20),

                        //  Nút đăng ký
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
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
                                      if (_password.text != _confirm.text) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Mật khẩu nhập lại không khớp')),
                                        );
                                        return;
                                      }
                                      final ok = await ref
                                          .read(authControllerProvider.notifier)
                                          .register({
                                        'email': _email.text.trim(),
                                        'password': _password.text,
                                        'name': _name.text,
                                        'mssv':
                                            _mssv.text.isEmpty ? null : _mssv.text.trim(),
                                        'class':
                                            _clazz.text.isEmpty ? null : _clazz.text.trim(),
                                        'phone':
                                            _phone.text.isEmpty ? null : _phone.text.trim(),
                                      });
                                      if (ok && mounted) context.go('/login');
                                    }
                                  },
                            icon: const Icon(Icons.app_registration_rounded,
                                color: Colors.white),
                            label: state.loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Đăng ký',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        //  Liên kết đến đăng nhập
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text(
                            'Đã có tài khoản? Đăng nhập',
                            style: TextStyle(color: kGreen, fontWeight: FontWeight.w500),
                          ),
                        ),

                        if (state.error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            state.error!,
                            style: const TextStyle(color: Colors.red),
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

  // ---------------------- TEXTFIELD ----------------------
  Widget _tf(String label, TextEditingController c,
      {IconData? icon, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, color: kGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ---------------------- PASSWORD FIELD ----------------------
  Widget _pf(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: kGreen),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey[700]),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      validator: (v) => (v == null || v.length < 6) ? 'Ít nhất 6 ký tự' : null,
    );
  }
}
