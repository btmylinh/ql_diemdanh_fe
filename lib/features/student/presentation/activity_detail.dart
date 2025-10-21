import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme.dart';
import '../data/activities_repository.dart';
import '../data/registrations_repository.dart';

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
      appBar: AppBar(title: const Text('Chi tiết hoạt động')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : activity == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(activity['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (activity['location'] != null)
                          Row(children: [
                            const Icon(Icons.place, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(activity['location'] ?? ''),
                          ]),
                        const SizedBox(height: 8),
                        _timeRow(activity),
                        const SizedBox(height: 8),
                        // Training Points
                        if (activity['training_points'] != null && activity['training_points'] > 0)
                          Row(children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 6),
                            Text('${activity['training_points']} điểm rèn luyện'),
                          ]),
                        const SizedBox(height: 8),
                        // Registration Deadline
                        if (activity['registration_deadline'] != null)
                          Row(children: [
                            const Icon(Icons.access_time, size: 16, color: Colors.red),
                            const SizedBox(width: 6),
                            Text('Hạn đăng ký: ${_fmt(DateTime.parse(activity['registration_deadline']))}'),
                          ]),
                        const SizedBox(height: 16),
                        if (activity['description'] != null) Text(activity['description'] ?? ''),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(child: _RegisterButton(activity: activity, onChanged: _fetch)),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _addToCalendar(activity),
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Thêm lịch'),
                          )
                        ]),
                      ],
                    ),
    );
  }

  Widget _timeRow(Map<String, dynamic> activity) {
    final start = DateTime.tryParse(activity['start_time']?.toString() ?? '');
    final end = DateTime.tryParse(activity['end_time']?.toString() ?? '');
    if (start == null) return const SizedBox.shrink();
    return Row(children: [
      const Icon(Icons.schedule, size: 16, color: Colors.grey),
      const SizedBox(width: 6),
      Text('${_fmt(start)}${end != null ? ' - ${_fmt(end)}' : ''}'),
    ]);
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmt(DateTime d) {
    final t = d.toLocal();
    return '${_two(t.hour)}:${_two(t.minute)} ${_two(t.day)}/${_two(t.month)}/${t.year}';
  }

  Future<void> _addToCalendar(Map<String, dynamic> activity) async {
    final start = DateTime.tryParse(activity['start_time']?.toString() ?? '');
    final end = DateTime.tryParse(activity['end_time']?.toString() ?? '');
    if (start == null) return;
    final event = cal.Event(
      title: activity['name'] ?? 'Hoạt động',
      description: activity['description'],
      location: activity['location'],
      startDate: start.toLocal(),
      endDate: (end ?? start.add(const Duration(hours: 2))).toLocal(),
    );
    await cal.Add2Calendar.addEvent2Cal(event);
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
            widget.onChanged();
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



