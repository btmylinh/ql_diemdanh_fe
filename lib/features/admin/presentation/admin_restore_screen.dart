import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme.dart';
import '../data/backup_provider.dart';
import '../data/backup_service.dart';

class AdminRestoreScreen extends ConsumerStatefulWidget {
  const AdminRestoreScreen({super.key});

  @override
  ConsumerState<AdminRestoreScreen> createState() => _AdminRestoreScreenState();
}

class _AdminRestoreScreenState extends ConsumerState<AdminRestoreScreen> {
  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khôi phục dữ liệu'),
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'CẢNH BÁO: Hành động này sẽ ghi đè toàn bộ dữ liệu hiện tại!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Chọn file từ thiết bị
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(backupStateProvider.notifier).restoreFromFile();
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Chọn file từ thiết bị'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 32),
              
              // Danh sách backup từ server
              const Text(
                'Hoặc chọn từ lịch sử sao lưu trên server:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: BackupService().listServerBackups(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, 
                              size: 48, 
                              color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Lỗi: ${snapshot.error}',
                              style: TextStyle(color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    
                    final serverBackups = snapshot.data ?? [];
                    
                    if (serverBackups.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, 
                              size: 48, 
                              color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có bản sao lưu nào trên server',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      itemCount: serverBackups.length,
                      itemBuilder: (context, index) {
                        final backup = serverBackups[index];
                        final createdAt = DateTime.tryParse(backup['createdAt'] ?? '') ?? DateTime.now();
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.green.shade100,
                                      child: Icon(Icons.backup, color: Colors.green.shade700),
                                    ),
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
                                Text('Thời gian: ${_formatDateTime(createdAt)}'),
                                Text('Kích thước: ${backup['fileSize'] ?? 'N/A'}'),
                                Text('Người tạo: ${backup['createdBy'] ?? 'N/A'}'),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _confirmRestore(context, backup['id']),
                                    icon: const Icon(Icons.restore, size: 18),
                                    label: const Text('Khôi phục'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRestore(BuildContext context, dynamic backupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận khôi phục'),
        content: const Text(
          'Bạn có chắc chắn muốn khôi phục dữ liệu từ bản sao lưu này?\n\n'
          '⚠️ Dữ liệu hiện tại sẽ bị ghi đè hoàn toàn!'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final backupService = BackupService();
                final result = await backupService.restoreFromServerBackupId(backupId.toString());
                
                Navigator.pop(context); // Close loading
                
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: result.success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 4),
                  ),
                );
              } catch (e) {
                Navigator.pop(context); // Close loading if error
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

  String _formatDateTime(DateTime dt) {
    // Backend trả về UTC, cần chuyển sang giờ địa phương
    final local = dt.toLocal();
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}

