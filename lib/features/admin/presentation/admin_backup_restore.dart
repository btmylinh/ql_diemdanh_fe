import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme.dart';
import '../data/backup_provider.dart';
import '../data/backup_service.dart';

class AdminBackupRestoreScreen extends ConsumerWidget {
  const AdminBackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupStateProvider);
    
    // Lắng nghe thay đổi state để hiển thị SnackBar/Dialog
    ref.listen<BackupState>(backupStateProvider, (previous, next) async {
      // Khi vừa xong 1 tác vụ (loading -> not loading)
      if (previous?.isLoading == true && !next.isLoading) {
        // Thông báo kết quả
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? ''),
            backgroundColor: next.isSuccess ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
            action: (next.isSuccess && next.filePath != null)
                ? SnackBarAction(
                    label: 'Mở thư mục',
                    textColor: Colors.white,
                    onPressed: () {
                      // TODO: Mở thư mục lưu file backup (tuỳ nền tảng)
                      // Ví dụ desktop: dùng url_launcher với file://
                    },
                  )
                : null,
          ),
        );
        
        // Cảnh báo (nếu có)
        if (next.warnings != null && next.warnings!.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cảnh báo'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                    children: next.warnings!
                        .map(
                          (w) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('• $w'),
                          ),
                        )
                        .toList(),
                    ),
                ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
        }
        
        // Metadata (nếu có)
        if (next.metadata != null && next.isSuccess) {
          await Future.delayed(const Duration(milliseconds: 1000));
          if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Thông tin sao lưu'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng hoạt động: ${next.metadata!['totalActivities'] ?? 0}'),
                    Text('Tổng người dùng: ${next.metadata!['totalUsers'] ?? 0}'),
                    Text('Tổng đăng ký: ${next.metadata!['totalRegistrations'] ?? 0}'),
                    Text('Tổng điểm danh: ${next.metadata!['totalAttendances'] ?? 0}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
        }
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sao lưu & Khôi phục'),
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
      body: SafeArea(
        child: Stack(
        children: [
          Padding(
              padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý sao lưu dữ liệu',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive cột theo chiều rộng
                        final width = constraints.maxWidth;
                        final crossAxisCount = width >= 1000
                            ? 4
                            : width >= 700
                                ? 3
                                : 2;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: [
                  _buildBackupCard(
                    context,
                    title: 'Tạo sao lưu',
                    subtitle: 'Xuất toàn bộ dữ liệu hệ thống',
                    icon: Icons.backup,
                    color: Colors.blue,
                        onTap: () => _showBackupDialog(context, ref),
                        isLoading: backupState.isLoading,
                  ),
                  _buildBackupCard(
                    context,
                    title: 'Khôi phục dữ liệu',
                    subtitle: 'Import dữ liệu từ file sao lưu',
                    icon: Icons.restore,
                    color: Colors.green,
                              onTap: () => context.push('/admin/backup/restore'),
                        isLoading: backupState.isLoading,
                  ),
                  _buildBackupCard(
                    context,
                    title: 'Lịch sử sao lưu',
                    subtitle: 'Xem các bản sao lưu trước đó',
                    icon: Icons.history,
                    color: Colors.purple,
                    onTap: () => _showBackupHistory(context),
                        isLoading: false,
                  ),
                            _buildBackupCard(
                              context,
                              title: 'Sao lưu tự động',
                              subtitle: 'Cài đặt sao lưu định kỳ',
                              icon: Icons.schedule,
                              color: Colors.orange,
                              onTap: () => _showAutoBackupSettings(context),
                        isLoading: false,
                  ),
                ],
                        );
                      },
              ),
            ),
          ],
        ),
          ),

            // Overlay tiến trình
          if (backupState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
                alignment: Alignment.center,
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Đang xử lý...',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (backupState.progress != null) ...[
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: backupState.progress,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(backupState.progress! * 100).toInt()}%',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
            ),
      ),
    );
  }

  Widget _buildBackupCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      )
                    : Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLoading ? Colors.grey : null,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isLoading ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo sao lưu'),
        content: const Text(
          'Bạn có muốn tạo bản sao lưu toàn bộ dữ liệu hệ thống?\n\nBao gồm:\n'
          '• Dữ liệu hoạt động\n• Dữ liệu người dùng\n• Dữ liệu đăng ký\n• Dữ liệu điểm danh',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(backupStateProvider.notifier).createBackup();
            },
            child: const Text('Tạo sao lưu'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    final backupService = BackupService();
    
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục dữ liệu'),
        content: FutureBuilder<List<dynamic>>(
          future: backupService.listServerBackups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text('Lỗi: ${snapshot.error}'),
                ),
              );
            }
            
            final serverBackups = snapshot.data ?? [];
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Chọn nguồn sao lưu để khôi phục:\n\n'
                  'CẢNH BÁO: Hành động này sẽ ghi đè toàn bộ dữ liệu hiện tại!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    ref.read(backupStateProvider.notifier).restoreFromFile();
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Chọn file từ thiết bị'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    textStyle: const TextStyle(color: Colors.white),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                if (serverBackups.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Hoặc chọn từ lịch sử sao lưu:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: serverBackups.length,
                    itemBuilder: (context, index) {
                      final backup = serverBackups[index];
                      final createdAt = DateTime.tryParse(backup['createdAt'] ?? '') ??
                          DateTime.now();

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.backup, color: Colors.green),
                          title: Text(
                            backup['name'] ?? 'Unknown',
                            style: const TextStyle(fontSize: 14),
                          ),
                          subtitle: Text(
                            '${_formatDateTime(createdAt)} - ${backup['fileSize'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                            trailing: IconButton(
                              icon: const Icon(Icons.restore, color: Colors.orange),
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true).pop();
                                _confirmRestore(context, ref, backup['id']);
                              },
                            ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                const SizedBox(height: 8),
                const Text(
                  'Chưa có bản sao lưu nào trên server',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context, WidgetRef ref, dynamic backupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận khôi phục'),
        content: const Text(
          'Bạn có chắc chắn muốn khôi phục dữ liệu từ bản sao lưu này?\n\n'
          '⚠️ Dữ liệu hiện tại sẽ bị ghi đè hoàn toàn!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Loading nhỏ trong lúc gọi API
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              try {
                final backupService = BackupService();
                final result =
                    await backupService.restoreFromServerBackupId(backupId.toString());

                if (Navigator.canPop(context)) Navigator.pop(context); // đóng loading
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.success ? result.message : result.message),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              } catch (e) {
                if (Navigator.canPop(context)) Navigator.pop(context); // đóng loading
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackupHistory(BuildContext context) async {
    try {
      // Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Lấy danh sách backup từ server
      final backupService = BackupService();
      final serverBackups = await backupService.listServerBackups();

      if (Navigator.canPop(context)) Navigator.pop(context); // đóng loading
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lịch sử sao lưu'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
            child: serverBackups.isEmpty
                ? const Center(child: Text('Chưa có bản sao lưu nào'))
              : ListView.builder(
                    itemCount: serverBackups.length,
                  itemBuilder: (context, index) {
                      final backup = serverBackups[index];
                      final createdAt = DateTime.tryParse(backup['createdAt'] ?? '') ??
                          DateTime.now();
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.backup, color: Colors.blue, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    backup['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Tạo lúc: ${_formatDateTime(createdAt)}'),
                            Text('Kích thước: ${backup['fileSize'] ?? 'N/A'}'),
                            Text('Người tạo: ${backup['createdBy'] ?? 'N/A'}'),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final success = await backupService
                                        .deleteBackup(backup['id'].toString());
                                    if (!context.mounted) return;

                                    if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã xóa bản sao lưu'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                                      await _showBackupHistory(context);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Xóa thất bại'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Xóa'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context); // đóng loading nếu lỗi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    // Backend trả về UTC, cần chuyển sang giờ địa phương
    final local = dt.toLocal();
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }

  void _showAutoBackupSettings(BuildContext context) {
    String selectedSchedule = 'None'; // None, Daily, Weekly, Monthly
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sao lưu tự động'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn tần suất sao lưu tự động:',
                style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              RadioListTile(
                title: const Text('Tắt'),
                value: 'None',
                groupValue: selectedSchedule,
                onChanged: (value) => setState(() => selectedSchedule = value!),
              ),
              RadioListTile(
                title: const Text('Hàng ngày (00:00)'),
                value: 'Daily',
                groupValue: selectedSchedule,
                onChanged: (value) => setState(() => selectedSchedule = value!),
              ),
              RadioListTile(
                title: const Text('Hàng tuần (Chủ nhật 00:00)'),
                value: 'Weekly',
                groupValue: selectedSchedule,
                onChanged: (value) => setState(() => selectedSchedule = value!),
              ),
              RadioListTile(
                title: const Text('Hàng tháng (Ngày 1, 00:00)'),
                value: 'Monthly',
                groupValue: selectedSchedule,
                onChanged: (value) => setState(() => selectedSchedule = value!),
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
                // TODO: Implement auto backup schedule
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã cài đặt: $selectedSchedule')),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
