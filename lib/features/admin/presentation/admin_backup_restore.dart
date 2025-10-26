import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';
import '../data/backup_provider.dart';
import '../data/backup_history_service.dart';

class AdminBackupRestoreScreen extends ConsumerWidget {
  const AdminBackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupStateProvider);
    
    // Listen to backup state changes and show results
    ref.listen<BackupState>(backupStateProvider, (previous, next) {
      if (previous?.isLoading == true && !next.isLoading) {
        // Show result message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? ''),
            backgroundColor: next.isSuccess ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
            action: next.isSuccess && next.filePath != null
                ? SnackBarAction(
                    label: 'Mở thư mục',
                    textColor: Colors.white,
                    onPressed: () {
                      // TODO: Open file location
                    },
                  )
                : null,
          ),
        );
        
        // Show warnings if any
        if (next.warnings != null && next.warnings!.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cảnh báo'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: next.warnings!.map((warning) => 
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('• $warning'),
                    ),
                  ).toList(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            );
          });
        }
        
        // Show metadata if available
        if (next.metadata != null && next.isSuccess) {
          Future.delayed(const Duration(milliseconds: 1000), () {
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
          });
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
      body: Stack(
        children: [
          Padding(
        padding: const EdgeInsets.all(16.0),
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
              child: GridView.count(
                crossAxisCount: 2,
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
                        onTap: () => _showRestoreDialog(context, ref),
                        isLoading: backupState.isLoading,
                  ),
                  _buildBackupCard(
                    context,
                    title: 'Xuất báo cáo',
                    subtitle: 'Xuất báo cáo thống kê',
                    icon: Icons.analytics,
                    color: Colors.orange,
                        onTap: () => _showExportDialog(context, ref),
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
                ],
              ),
            ),
          ],
        ),
          ),
          // Progress overlay
          if (backupState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
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
            ),
        ],
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
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                    : Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLoading ? Colors.grey : null,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isLoading ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
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
        content: const Text('Bạn có muốn tạo bản sao lưu toàn bộ dữ liệu hệ thống?\n\nBao gồm:\n• Dữ liệu hoạt động\n• Dữ liệu người dùng\n• Dữ liệu đăng ký\n• Dữ liệu điểm danh'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Khôi phục dữ liệu'),
        content: const Text('Chọn file sao lưu để khôi phục dữ liệu.\n\n⚠️ CẢNH BÁO: Hành động này sẽ ghi đè toàn bộ dữ liệu hiện tại!\n\nHãy đảm bảo bạn đã tạo sao lưu trước khi khôi phục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(backupStateProvider.notifier).restoreFromFile();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Chọn file'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xuất báo cáo'),
        content: const Text('Chọn loại báo cáo cần xuất:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(backupStateProvider.notifier).exportReport('activities');
            },
            child: const Text('Báo cáo hoạt động'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(backupStateProvider.notifier).exportReport('users');
            },
            child: const Text('Báo cáo người dùng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(backupStateProvider.notifier).exportReport('attendances');
            },
            child: const Text('Báo cáo điểm danh'),
          ),
        ],
      ),
    );
  }

  void _showBackupHistory(BuildContext context) async {
    final history = await BackupHistoryService.getBackupHistory();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lịch sử sao lưu'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: history.isEmpty
              ? const Center(
                  child: Text('Chưa có bản sao lưu nào'),
                )
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final backup = history[index];
                    final createdAt = DateTime.tryParse(backup['createdAt'] ?? '') ?? DateTime.now();
                    final metadata = backup['metadata'] as Map<String, dynamic>? ?? {};
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.backup, color: Colors.blue),
                        title: Text(backup['fileName'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tạo lúc: ${_formatDateTime(createdAt)}'),
                            Text('Hoạt động: ${metadata['totalActivities'] ?? 0}'),
                            Text('Người dùng: ${metadata['totalUsers'] ?? 0}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              final success = await BackupHistoryService.deleteBackupFromHistory(
                                backup['id'] ?? '',
                              );
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã xóa bản sao lưu'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                                _showBackupHistory(context); // Refresh
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Xóa'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          if (history.isNotEmpty)
            TextButton(
              onPressed: () async {
                await BackupHistoryService.clearBackupHistory();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa tất cả lịch sử'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Xóa tất cả'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}