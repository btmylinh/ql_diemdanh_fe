import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';
import '../data/activities_repository.dart';
import '../data/registrations_repository.dart';
import '../data/activities_providers.dart';
import '../data/registrations_providers.dart';

class ActivityDetailScreen extends ConsumerStatefulWidget {
  const ActivityDetailScreen({super.key, required this.activityId});
  final int activityId;

  @override
  ConsumerState<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends ConsumerState<ActivityDetailScreen> {
  bool _loading = false;
  Map<String, dynamic>? _activity;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ref.read(activitiesRepositoryProvider).getById(widget.activityId);
      setState(() { _activity = data; });
    } catch (e) {
      setState(() { _error = 'Không tải được dữ liệu'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activity = _activity;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chi tiết hoạt động',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : activity == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            activity['name'] ?? '', 
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                           // Description
                          if (activity['description'] != null) ...[
                            const Text(
                              'Mô tả',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Text(
                                activity['description'] ?? '',
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          // Info Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                // Location
                                if (activity['location'] != null) ...[
                                  _InfoRow(
                                    icon: Icons.place,
                                    label: 'Địa điểm',
                                    value: activity['location'] ?? '',
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                
                                // Time
                        _timeRow(activity),
                                const SizedBox(height: 12),
                                
                        // Training Points
                                if (activity['training_points'] != null && activity['training_points'] > 0) ...[
                                  _InfoRow(
                                    icon: Icons.star,
                                    label: 'Điểm rèn luyện',
                                    value: '${activity['training_points']} điểm',
                                    iconColor: Colors.amber,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                
                        // Registration Deadline
                                if (activity['registration_deadline'] != null) ...[
                                  _InfoRow(
                                    icon: Icons.access_time,
                                    label: 'Hạn đăng ký',
                                    value: _fmt(DateTime.parse(activity['registration_deadline'])),
                                    iconColor: Colors.red,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                        const SizedBox(height: 16),
                          // Register Button
                          _RegisterButton(activity: activity, onChanged: _fetch),
                        ],
                      ),
                    ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }

  Widget _timeRow(Map<String, dynamic> activity) {
    final start = DateTime.tryParse(activity['start_time']?.toString() ?? '');
    final end = DateTime.tryParse(activity['end_time']?.toString() ?? '');
    if (start == null) return const SizedBox.shrink();
    return _InfoRow(
      icon: Icons.schedule,
      label: 'Thời gian',
      value: '${_fmt(start)}${end != null ? ' - ${_fmt(end)}' : ''}',
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmt(DateTime d) {
    final t = d.toLocal();
    return '${_two(t.hour)}:${_two(t.minute)} ${_two(t.day)}/${_two(t.month)}/${t.year}';
  }

}

class _RegisterButton extends ConsumerStatefulWidget {
  const _RegisterButton({required this.activity, required this.onChanged});
  final Map<String, dynamic> activity;
  final VoidCallback onChanged;

  @override
  ConsumerState<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends ConsumerState<_RegisterButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final registered = widget.activity['registered_by_me'] == true;
    final start = DateTime.tryParse(widget.activity['start_time']?.toString() ?? '');
    final registrationDeadline = widget.activity['registration_deadline'] != null 
        ? DateTime.tryParse(widget.activity['registration_deadline']?.toString() ?? '') 
        : null;
    final now = DateTime.now();
    final isEnded = start != null && now.isAfter(start);
    final isRegistrationClosed = registrationDeadline != null && now.isAfter(registrationDeadline);
    final canRegister = !isEnded && !isRegistrationClosed;
    
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(
          !canRegister ? Colors.grey : (registered ? Colors.red : kGreen),
        )),
        onPressed: (_busy || !canRegister) ? null : () async {
          setState(() { _busy = true; });
          try {
            if (registered) {
              await ref.read(registrationsRepositoryProvider).cancel(widget.activity['id'] as int);
            } else {
              await ref.read(registrationsRepositoryProvider).register(widget.activity['id'] as int);
            }
            // Refresh chi tiết hoạt động
            widget.onChanged();
            // Refresh danh sách hoạt động để cập nhật trạng thái đăng ký
            ref.invalidate(activitiesListProvider);
            // Refresh danh sách đăng ký của tôi
            ref.invalidate(myRegistrationsProvider);
            // Hiển thị thông báo thành công
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(registered ? 'Hủy đăng ký thành công' : 'Đăng ký thành công'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(registered ? 'Hủy thất bại' : 'Đăng ký thất bại')),
              );
            }
          } finally {
            setState(() { _busy = false; });
          }
        },
        icon: _busy
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(!canRegister ? Icons.lock_clock : (registered ? Icons.cancel : Icons.check_circle)),
        label: Text(
          !canRegister 
            ? (isRegistrationClosed ? 'Hết hạn đăng ký' : 'Đã kết thúc')
            : (registered ? 'Hủy đăng ký' : 'Đăng ký ngay')
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = Colors.grey,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kGreen,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.play_circle_fill,
                label: 'Hoạt động',
                isActive: false,
                onTap: () => context.go('/student/activities'),
              ),
              _NavItem(
                icon: Icons.qr_code_scanner,
                label: 'QR danh',
                isActive: false,
                onTap: () => context.push('/student/qr-scan'),
              ),
              _NavItem(
                icon: Icons.assessment_outlined,
                label: 'Báo cáo',
                isActive: false,
                onTap: () => context.push('/student/reports'),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Hồ sơ',
                isActive: false,
                onTap: () => context.push('/student/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: isActive ? 28 : 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
