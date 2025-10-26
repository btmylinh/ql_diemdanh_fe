import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:characters/characters.dart';
import 'dart:async';

import '../../../theme.dart';
import '../data/admin_users_provider.dart';

/// -----------------------
/// Models & Helpers
/// -----------------------

enum UserRole { admin, manager, student, unknown }

extension UserRoleX on UserRole {
  static UserRole parse(dynamic raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    switch (s) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'student':
        return UserRole.student;
      default:
        return UserRole.unknown;
    }
  }

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.manager:
        return 'Manager';
      case UserRole.student:
        return 'Student';
      case UserRole.unknown:
        return 'Unknown';
    }
  }

  Color get color {
    switch (this) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.student:
        return Colors.green;
      case UserRole.unknown:
        return Colors.grey;
    }
  }
}

enum UserStatus {
  inactive(0),
  active(1),
  locked(2),
  unknown(-1);

  final int code;
  const UserStatus(this.code);

  static UserStatus fromInt(dynamic raw) {
    final v = raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? -1;
    return UserStatus.values.firstWhere(
      (e) => e.code == v,
      orElse: () => UserStatus.unknown,
    );
  }
}

extension UserStatusX on UserStatus {
  String get label {
    switch (this) {
      case UserStatus.active:
        return 'Hoạt động';
      case UserStatus.inactive:
        return 'Không hoạt động';
      case UserStatus.locked:
        return 'Khóa tài khoản';
      case UserStatus.unknown:
        return 'Không xác định';
    }
  }

  Color get color {
    switch (this) {
      case UserStatus.active:
        return Colors.green;
      case UserStatus.inactive:
        return Colors.red;
      case UserStatus.locked:
        return Colors.orange;
      case UserStatus.unknown:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case UserStatus.active:
        return Icons.check_circle;
      case UserStatus.inactive:
        return Icons.cancel;
      case UserStatus.locked:
        return Icons.lock;
      case UserStatus.unknown:
        return Icons.help;
    }
  }
}

/// -----------------------
/// Screen
/// -----------------------

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'all';
  String _selectedStatus = 'all';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminUsersProvider.notifier).loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Lọc người dùng',
            onPressed: () => _showFilterDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm người dùng',
            onPressed: _showAddUserDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập tên, email hoặc mã số sinh viên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(adminUsersProvider.notifier).searchUsers('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                  ref.read(adminUsersProvider.notifier).searchUsers(value);
                });
              },
            ),
          ),
          Expanded(
            child: usersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : usersState.error != null
                    ? _buildError(usersState.error!)
                    : usersState.users.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            itemCount: usersState.users.length,
                            itemBuilder: (context, index) {
                              final user =
                                  usersState.users[index] as Map<String, dynamic>;
                              return _buildUserCard(user);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  /// -----------------------
  /// Search & Filter Bar (optional UI not used in build)
  /// -----------------------
  Widget _buildSearchFilterBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.search, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Tìm kiếm & Lọc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Input
          StatefulBuilder(
            builder: (context, setState) {
              return TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Nhập tên, email hoặc mã số sinh viên...',
                  prefixIcon: Icon(Icons.person_search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            ref.read(adminUsersProvider.notifier).searchUsers('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.blue[400]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() {});
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(const Duration(milliseconds: 500), () {
                    ref.read(adminUsersProvider.notifier).searchUsers(value);
                  });
                },
              );
            },
          ),

          const SizedBox(height: 16),

          // Role Filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vai trò',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Row(
                          children: [
                            Icon(Icons.people,
                                size: 18, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Tất cả vai trò'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Admin'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'manager',
                        child: Row(
                          children: [
                            Icon(Icons.manage_accounts,
                                size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Manager'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'student',
                        child: Row(
                          children: [
                            Icon(Icons.school,
                                size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Student'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedRole = value);
                      ref
                          .read(adminUsersProvider.notifier)
                          .filterByRole(value);
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Clear filters
          Consumer(
            builder: (context, ref, child) {
              final hasActiveFilters =
                  _searchController.text.isNotEmpty || _selectedRole != 'all';

              return hasActiveFilters
                  ? ElevatedButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _selectedRole = 'all';
                        });
                        ref
                            .read(adminUsersProvider.notifier)
                            .searchUsers('');
                        ref
                            .read(adminUsersProvider.notifier)
                            .filterByRole('all');
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Xóa tất cả bộ lọc'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.grey[700],
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  /// -----------------------
  /// States
  /// -----------------------
  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Lỗi: $message',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(adminUsersProvider.notifier).loadUsers(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Không có người dùng nào',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  /// -----------------------
  /// User Card
  /// -----------------------
  Widget _buildUserCard(Map<String, dynamic> user) {
    final status = UserStatus.fromInt(user['status'] ?? 1);
    final role = UserRoleX.parse(user['role']);
    final name = user['name']?.toString().trim();
    final displayName = (name == null || name.isEmpty) ? 'Không có tên' : name;
    final mssv = user['mssv']?.toString() ?? '';
    final className = user['class']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: () => _showUserDetailDialog(user),
        leading: CircleAvatar(
          backgroundColor: role.color,
          child: Text(
            displayName.characters.first.toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color:
                          status == UserStatus.active ? null : Colors.grey,
                    ),
                  ),
                  if (mssv.isNotEmpty)
                    Text(
                      mssv,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: role.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: role.color),
              ),
              child: Text(
                role.label,
                style: TextStyle(
                  color: role.color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (className.isNotEmpty)
              Text('Lớp: $className',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(status.icon, size: 14, color: status.color),
                const SizedBox(width: 4),
                Text(
                  status.label,
                  style: TextStyle(
                    color: status.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing:
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  /// -----------------------
  /// Dialogs
  /// -----------------------

  void _showUserDetailDialog(Map<String, dynamic> user) {
    final status = UserStatus.fromInt(user['status'] ?? 1);
    final role = UserRoleX.parse(user['role']);
    final name = (user['name']?.toString() ?? '').trim();
    final email = user['email']?.toString() ?? '';
    final mssv = user['mssv']?.toString() ?? '';
    final className = user['class']?.toString() ?? '';
    final phone = user['phone']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: role.color,
              child: Text(
                (name.isEmpty ? 'K' : name.characters.first).toUpperCase(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.isEmpty ? 'Không có tên' : name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(role.label,
                      style: TextStyle(
                          color: role.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Email', email),
              if (mssv.isNotEmpty) _buildInfoRow('MSSV', mssv),
              if (className.isNotEmpty) _buildInfoRow('Lớp', className),
              if (phone.isNotEmpty) _buildInfoRow('SĐT', phone),
              const SizedBox(height: 8),
              _buildInfoRow('Trạng thái', status.label,
                  valueColor: status.color),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng')),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditUserDialog(user);
                },
                icon: const Icon(Icons.edit, color: Colors.blue),
                tooltip: 'Chỉnh sửa',
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showResetPasswordDialog(user);
                },
                icon:
                    const Icon(Icons.lock_reset, color: Colors.orange),
                tooltip: 'Reset mật khẩu',
              ),
              IconButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (_) => ChangeRoleDialog(
                      currentRole: UserRoleX.parse(user['role']).name,
                      user: user,
                    ),
                  );
                  if (selected != null) {
                    final ok = await ref
                        .read(adminUsersProvider.notifier)
                        .updateUserRole(user['id'], selected);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Đổi quyền thành công'
                            : 'Không thể đổi quyền'),
                        backgroundColor:
                            ok ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.swap_horiz, color: Colors.purple),
                tooltip: 'Đổi quyền',
              ),
              IconButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final selected = await showDialog<int>(
                    context: context,
                    builder: (_) => ChangeStatusDialog(
                      currentStatus: status.code,
                      user: user,
                    ),
                  );
                  if (selected != null && selected != status.code) {
                    final ok = await ref
                        .read(adminUsersProvider.notifier)
                        .changeUserStatus(user['id'], selected);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok
                            ? 'Thay đổi trạng thái thành công'
                            : 'Không thể thay đổi trạng thái'),
                        backgroundColor:
                            ok ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
                icon: Icon(status.icon, color: status.color),
                tooltip: 'Thay đổi trạng thái',
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showDeleteUserDialog(user);
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Xóa vĩnh viễn',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final mssvCtrl = TextEditingController();
    final classCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'student';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm người dùng'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Họ và tên *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tên'
                          : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    final emailRegex = RegExp(r'^\S+@\S+\.\S+$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu *',
                    hintText:
                        'Để trống sẽ dùng mật khẩu mặc định: 123456',
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null;
                    if (v.length < 6) {
                      return 'Mật khẩu ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(
                        value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                        value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(
                        value: 'student', child: Text('Student')),
                  ],
                  onChanged: (v) => setState(() => role = v ?? 'student'),
                  decoration:
                      const InputDecoration(labelText: 'Vai trò *'),
                ),
                TextFormField(
                    controller: mssvCtrl,
                    decoration:
                        const InputDecoration(labelText: 'MSSV')),
                TextFormField(
                    controller: classCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Lớp')),
                TextFormField(
                  controller: phoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'SĐT'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final payload = {
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'password':
                    passCtrl.text.isEmpty ? '123456' : passCtrl.text,
                'role': role,
                if (mssvCtrl.text.trim().isNotEmpty)
                  'mssv': mssvCtrl.text.trim(),
                if (classCtrl.text.trim().isNotEmpty)
                  'class': classCtrl.text.trim(),
                if (phoneCtrl.text.trim().isNotEmpty)
                  'phone': phoneCtrl.text.trim(),
              };
              final res = await ref
                  .read(adminUsersProvider.notifier)
                  .createUser(payload);
              if (!mounted) return;
              if (res != null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tạo người dùng thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể tạo người dùng'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    ).then((_) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      passCtrl.dispose();
      mssvCtrl.dispose();
      classCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl =
        TextEditingController(text: user['name']?.toString() ?? '');
    final emailCtrl =
        TextEditingController(text: user['email']?.toString() ?? '');
    final passCtrl = TextEditingController();
    final mssvCtrl =
        TextEditingController(text: user['mssv']?.toString() ?? '');
    final classCtrl =
        TextEditingController(text: user['class']?.toString() ?? '');
    final phoneCtrl =
        TextEditingController(text: user['phone']?.toString() ?? '');
    String role = UserRoleX.parse(user['role']).name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa người dùng'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Họ và tên *'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Vui lòng nhập tên'
                          : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    final emailRegex = RegExp(r'^\S+@\S+\.\S+$');
                    if (!emailRegex.hasMatch(v.trim())) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới (để trống nếu không đổi)',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(
                        value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                        value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(
                        value: 'student', child: Text('Student')),
                  ],
                  onChanged: (v) => setState(() => role = v ?? role),
                  decoration:
                      const InputDecoration(labelText: 'Vai trò *'),
                ),
                TextFormField(
                    controller: mssvCtrl,
                    decoration:
                        const InputDecoration(labelText: 'MSSV')),
                TextFormField(
                    controller: classCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Lớp')),
                TextFormField(
                  controller: phoneCtrl,
                  decoration:
                      const InputDecoration(labelText: 'SĐT'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final payload = {
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'role': role,
                if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
                'mssv': mssvCtrl.text.trim().isEmpty
                    ? null
                    : mssvCtrl.text.trim(),
                'class': classCtrl.text.trim().isEmpty
                    ? null
                    : classCtrl.text.trim(),
                'phone': phoneCtrl.text.trim().isEmpty
                    ? null
                    : phoneCtrl.text.trim(),
              }..removeWhere((k, v) => v == null);
              final res = await ref
                  .read(adminUsersProvider.notifier)
                  .updateUser(user['id'], payload);
              if (!mounted) return;
              if (res != null) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cập nhật người dùng thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể cập nhật người dùng'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    ).then((_) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      passCtrl.dispose();
      mssvCtrl.dispose();
      classCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới *',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng nhập mật khẩu mới';
                  }
                  if (v.length < 6) {
                    return 'Mật khẩu ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Xác nhận mật khẩu *',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (v != passwordCtrl.text) {
                    return 'Mật khẩu xác nhận không khớp';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final success = await ref
                  .read(adminUsersProvider.notifier)
                  .resetUserPassword(user['id'], passwordCtrl.text);
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Reset mật khẩu thành công'
                      : 'Không thể reset mật khẩu'),
                  backgroundColor:
                      success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    ).then((_) {
      passwordCtrl.dispose();
      confirmPasswordCtrl.dispose();
    });
  }

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn người dùng "${user['name']}"?\n\nHành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color.fromARGB(255, 238, 151, 145),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(adminUsersProvider.notifier)
                  .deleteUser(user['id']);
            },
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }

  /// Filter dialog (đÃ di chuyển ra đúng class)
  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Lọc người dùng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vai trò:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'all', child: Text('Tất cả vai trò')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(
                      value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(
                      value: 'student', child: Text('Student')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 24),
              const Text('Trạng thái:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'all', child: Text('Tất cả trạng thái')),
                  DropdownMenuItem(value: '1', child: Text('Hoạt động')),
                  DropdownMenuItem(
                      value: '0', child: Text('Không hoạt động')),
                  DropdownMenuItem(
                      value: '2', child: Text('Chờ xác nhận')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedStatus = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(adminUsersProvider.notifier).filterByRole(_selectedRole);
                // TODO: Implement status filter
              },
              child: const Text('Áp dụng'),
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------
/// Dialog Widgets
/// -----------------------

class ChangeRoleDialog extends StatefulWidget {
  final String currentRole; // 'admin' | 'manager' | 'student'
  final Map<String, dynamic> user;

  const ChangeRoleDialog({
    super.key,
    required this.currentRole,
    required this.user,
  });

  @override
  State<ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends State<ChangeRoleDialog> {
  late String selectedRole;

  @override
  void initState() {
    super.initState();
    selectedRole = widget.currentRole;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi quyền người dùng'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          RadioListTile<String>(
            title: const Text('Admin'),
            subtitle: const Text('Quyền quản trị cao nhất'),
            value: 'admin',
            groupValue: selectedRole,
            onChanged: (v) => setState(() => selectedRole = v!),
          ),
          RadioListTile<String>(
            title: const Text('Manager'),
            subtitle: const Text('Quyền quản lý hoạt động'),
            value: 'manager',
            groupValue: selectedRole,
            onChanged: (v) => setState(() => selectedRole = v!),
          ),
          RadioListTile<String>(
            title: const Text('Student'),
            subtitle: const Text('Quyền sinh viên'),
            value: 'student',
            groupValue: selectedRole,
            onChanged: (v) => setState(() => selectedRole = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedRole),
          child: const Text('Đổi quyền'),
        ),
      ],
    );
  }
}

class ChangeStatusDialog extends StatefulWidget {
  final int currentStatus; // 0|1|2
  final Map<String, dynamic> user;

  const ChangeStatusDialog({
    super.key,
    required this.currentStatus,
    required this.user,
  });

  @override
  State<ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends State<ChangeStatusDialog> {
  late int selectedStatus;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thay đổi trạng thái người dùng'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Thay đổi trạng thái cho người dùng: ${widget.user['name']}'),
          const SizedBox(height: 16),
          const Text('Chọn trạng thái mới:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          RadioListTile<int>(
            title: const Text('Hoạt động'),
            subtitle: const Text('Tài khoản có thể đăng nhập và sử dụng'),
            value: 1,
            groupValue: selectedStatus,
            onChanged: (v) => setState(() => selectedStatus = v!),
          ),
          RadioListTile<int>(
            title: const Text('Không hoạt động'),
            subtitle: const Text('Tài khoản bị vô hiệu hóa'),
            value: 0,
            groupValue: selectedStatus,
            onChanged: (v) => setState(() => selectedStatus = v!),
          ),
          RadioListTile<int>(
            title: const Text('Khóa tài khoản'),
            subtitle: const Text('Tài khoản bị khóa do vi phạm'),
            value: 2,
            groupValue: selectedStatus,
            onChanged: (v) => setState(() => selectedStatus = v!),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedStatus),
          child: const Text('Thay đổi'),
        ),
      ],
    );
  }
}
