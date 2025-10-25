import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/admin_users_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'all';
  bool _showInactive = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddUserDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm theo tên, email, MSSV...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (value) {
                          ref.read(adminUsersProvider.notifier).searchUsers(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Tất cả vai trò')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'manager', child: Text('Manager')),
                        DropdownMenuItem(value: 'student', child: Text('Student')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                        ref.read(adminUsersProvider.notifier).filterByRole(value!);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: _showInactive,
                      onChanged: (value) {
                        setState(() {
                          _showInactive = value!;
                        });
                        ref.read(adminUsersProvider.notifier).toggleShowInactive(value!);
                      },
                    ),
                    const Text('Hiển thị tài khoản bị vô hiệu hóa'),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        ref.read(adminUsersProvider.notifier).loadUsers();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Users list
          Expanded(
            child: usersState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : usersState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Lỗi: ${usersState.error}',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(adminUsersProvider.notifier).loadUsers();
                              },
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : usersState.users.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Không có người dùng nào',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: usersState.users.length,
                            itemBuilder: (context, index) {
                              final user = usersState.users[index];
                              return _buildUserCard(user);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isActive = user['status'] == 1;
    final role = user['role']?.toString().toLowerCase() ?? 'student';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role),
          child: Text(
            user['name']?.toString().substring(0, 1).toUpperCase() ?? '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user['name'] ?? 'Không có tên',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? null : Colors.grey,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getRoleColor(role)),
              ),
              child: Text(
                _getRoleDisplayName(role),
                style: TextStyle(
                  color: _getRoleColor(role),
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
            Text(user['email'] ?? ''),
            if (user['mssv'] != null) Text('MSSV: ${user['mssv']}'),
            if (user['class'] != null) Text('Lớp: ${user['class']}'),
            if (user['phone'] != null) Text('SĐT: ${user['phone']}'),
            Row(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: isActive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? 'Hoạt động' : 'Bị vô hiệu hóa',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Chỉnh sửa'),
                ],
              ),
            ),
            PopupMenuItem(
              value: isActive ? 'deactivate' : 'activate',
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                    color: isActive ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'manager':
        return Colors.blue;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'manager':
        return 'Manager';
      case 'student':
        return 'Student';
      default:
        return 'Unknown';
    }
  }

  void _handleUserAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'activate':
      case 'deactivate':
        _toggleUserStatus(user);
        break;
      case 'delete':
        _showDeleteUserDialog(user);
        break;
    }
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
                  decoration: const InputDecoration(labelText: 'Họ và tên *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                    final emailRegex = RegExp(r'^\S+@\S+\.\S+$');
                    if (!emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                TextFormField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu *',
                    hintText: 'Để trống sẽ dùng mật khẩu mặc định: 123456',
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return null; // Allow empty for default password
                    if (v.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                  ],
                  onChanged: (v) { role = v ?? 'student'; },
                  decoration: const InputDecoration(labelText: 'Vai trò *'),
                ),
                TextFormField(
                  controller: mssvCtrl,
                  decoration: const InputDecoration(labelText: 'MSSV'),
                ),
                TextFormField(
                  controller: classCtrl,
                  decoration: const InputDecoration(labelText: 'Lớp'),
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'SĐT'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final payload = {
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'password': passCtrl.text.isEmpty ? '123456' : passCtrl.text,
                'role': role,
                if (mssvCtrl.text.trim().isNotEmpty) 'mssv': mssvCtrl.text.trim(),
                if (classCtrl.text.trim().isNotEmpty) 'class': classCtrl.text.trim(),
                if (phoneCtrl.text.trim().isNotEmpty) 'phone': phoneCtrl.text.trim(),
              };
              final res = await ref.read(adminUsersProvider.notifier).createUser(payload);
              if (mounted) {
                if (res != null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tạo người dùng thành công'), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể tạo người dùng'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user['name']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: user['email']?.toString() ?? '');
    final passCtrl = TextEditingController();
    final mssvCtrl = TextEditingController(text: user['mssv']?.toString() ?? '');
    final classCtrl = TextEditingController(text: user['class']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: user['phone']?.toString() ?? '');
    String role = (user['role']?.toString().toLowerCase() ?? 'student');

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
                  decoration: const InputDecoration(labelText: 'Họ và tên *'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
                ),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                    final emailRegex = RegExp(r'^\S+@\S+\.\S+$');
                    if (!emailRegex.hasMatch(v.trim())) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                TextFormField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Mật khẩu mới (để trống nếu không đổi)'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                  ],
                  onChanged: (v) { role = v ?? role; },
                  decoration: const InputDecoration(labelText: 'Vai trò *'),
                ),
                TextFormField(
                  controller: mssvCtrl,
                  decoration: const InputDecoration(labelText: 'MSSV'),
                ),
                TextFormField(
                  controller: classCtrl,
                  decoration: const InputDecoration(labelText: 'Lớp'),
                ),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'SĐT'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final payload = {
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'role': role,
                if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
                'mssv': mssvCtrl.text.trim().isEmpty ? null : mssvCtrl.text.trim(),
                'class': classCtrl.text.trim().isEmpty ? null : classCtrl.text.trim(),
                'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
              }..removeWhere((key, value) => value == null);
              final res = await ref.read(adminUsersProvider.notifier).updateUser(user['id'] as int, payload);
              if (mounted) {
                if (res != null) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cập nhật người dùng thành công'), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Không thể cập nhật người dùng'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(Map<String, dynamic> user) {
    final isActive = user['status'] == 1;
    final action = isActive ? 'vô hiệu hóa' : 'kích hoạt';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isActive ? 'Vô hiệu hóa' : 'Kích hoạt'} người dùng'),
        content: Text('Bạn có chắc chắn muốn $action người dùng "${user['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(adminUsersProvider.notifier).toggleUserStatus(user['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
            ),
            child: Text(isActive ? 'Vô hiệu hóa' : 'Kích hoạt'),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa người dùng'),
        content: Text('Bạn có chắc chắn muốn xóa vĩnh viễn người dùng "${user['name']}"?\n\nHành động này không thể hoàn tác!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(adminUsersProvider.notifier).deleteUser(user['id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa vĩnh viễn'),
          ),
        ],
      ),
    );
  }
}
