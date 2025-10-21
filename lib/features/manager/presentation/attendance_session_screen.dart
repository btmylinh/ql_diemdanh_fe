import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';

class AttendanceSessionScreen extends StatelessWidget {
  const AttendanceSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activityId = GoRouterState.of(context).pathParameters['id'] ?? '0';
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: kBlue,
        foregroundColor: Colors.white,
        title: const Text('Phiên điểm danh'),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Quản lý phiên điểm danh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activity ID: $activityId',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}