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
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _form,
              child: ListView(children: [
                Text('Tạo tài khoản sinh viên', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                _tf('Họ tên', _name, icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Họ tên là bắt buộc' : null),
                const SizedBox(height: 12),
                _tf('Email', _email, icon: Icons.email_outlined,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null),
                const SizedBox(height: 12),
                _tf('MSSV', _mssv, icon: Icons.badge_outlined),
                const SizedBox(height: 12),
                _tf('Lớp', _clazz, icon: Icons.class_outlined),
                const SizedBox(height: 12),
                _tf('Số điện thoại', _phone, icon: Icons.phone_outlined),
                const SizedBox(height: 12),
                _pf('Mật khẩu', _password),
                const SizedBox(height: 12),
                _pf('Nhập lại mật khẩu', _confirm),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: state.loading ? null : () async {
                      if (_form.currentState!.validate()) {
                        if (_password.text != _confirm.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mật khẩu nhập lại không khớp')),
                          );
                          return;
                        }
                        final ok = await ref.read(authControllerProvider.notifier).register({
                          'email': _email.text.trim(),
                          'password': _password.text,
                          'name': _name.text,
                          'mssv': _mssv.text.isEmpty ? null : _mssv.text,
                          'class': _clazz.text.isEmpty ? null : _clazz.text,
                          'phone': _phone.text.isEmpty ? null : _phone.text,
                        });
                        if (ok && mounted) context.go('/'); 
                      }
                    },
                    child: state.loading ? const CircularProgressIndicator() : const Text('Đăng ký'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Đã có tài khoản? Đăng nhập', style: TextStyle(color: kGreen)),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 8),
                  Text(state.error!, style: const TextStyle(color: Colors.red)),
                ]
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tf(String label, TextEditingController c, {IconData? icon, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, color: kGreen),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }

  Widget _pf(String label, TextEditingController c) {
    return TextFormField(
      controller: c,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: kGreen),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      validator: (v) => (v == null || v.length < 6) ? 'Ít nhất 6 ký tự' : null,
    );
  }
}
