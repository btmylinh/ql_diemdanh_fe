import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../theme.dart';
import '../data/activities_providers.dart';

class StudentActivitiesScreen extends ConsumerStatefulWidget {
  const StudentActivitiesScreen({super.key});

  @override
  ConsumerState<StudentActivitiesScreen> createState() => _StudentActivitiesScreenState();
}

class _StudentActivitiesScreenState extends ConsumerState<StudentActivitiesScreen> {
  final _search = TextEditingController();
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(activitiesListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoạt động'),
        actions: [
          IconButton(
            tooltip: 'Quét QR',
            onPressed: () => context.push('/student/qr-scan'),
            icon: const Icon(Icons.qr_code_scanner),
          ),
          IconButton(
            tooltip: 'Của tôi',
            onPressed: () => context.push('/student/my'),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên/mô tả...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _applyFilters(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event),
                label: Text(_selectedDate == null
                    ? 'Ngày'
                    : _selectedDate!.toLocal().toString().split(' ').first),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _applyFilters,
                child: const Text('Lọc'),
              ),
            ]),
          ),
          Expanded(
            child: listAsync.when(
              data: (data) {
                final now = DateTime.now();
                final raw = List<Map<String, dynamic>>.from(data['activities'] ?? []);
                // Ẩn sự kiện đã qua (dựa trên end_time; nếu không có thì dùng start_time)
                final items = raw.where((a) {
                  final start = DateTime.tryParse(a['start_time']?.toString() ?? '');
                  final end = DateTime.tryParse(a['end_time']?.toString() ?? '');
                  final effectiveEnd = end ?? start;
                  if (effectiveEnd == null) return true; // nếu thiếu hết thời gian, không lọc
                  return !now.isAfter(effectiveEnd);
                }).toList();
                if (items.isEmpty) {
                  return const Center(child: Text('Không có hoạt động'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (_, i) => _ActivityItem(activity: items[i]),
                );
              },
              error: (e, st) => Center(child: Text('Lỗi: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    final dateIso = _selectedDate?.toIso8601String();
    ref.read(activitiesQueryProvider.notifier)
        .state = ActivitiesQuery(q: _search.text.trim(), dateIso: dateIso);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDate: _selectedDate ?? now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity});
  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.tryParse(activity['start_time']?.toString() ?? '');
    final end = DateTime.tryParse(activity['end_time']?.toString() ?? '');
    final registeredByMe = activity['registered_by_me'] == true;
    final now = DateTime.now();
    final isOngoing = (start != null && end != null) && now.isAfter(start) && now.isBefore(end);
    final isUpcomingSoon = start != null && now.isBefore(start) && start.difference(now) <= const Duration(minutes: 30);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/student/activities/${activity['id']}', extra: activity['id']),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event, color: kGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity['name'] ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (activity['location'] != null)
                      Row(children: [
                        const Icon(Icons.place, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(child: Text(activity['location'], overflow: TextOverflow.ellipsis)),
                      ]),
                    const SizedBox(height: 4),
                    if (start != null)
                      Row(children: [
                        const Icon(Icons.schedule, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(_formatStart(start)),
                        const SizedBox(width: 8),
                        if (isOngoing) _StatusChip(text: 'Đang diễn ra', color: Colors.green),
                        if (!isOngoing && isUpcomingSoon) _StatusChip(text: 'Sắp diễn ra', color: Colors.blue),
                      ]),
                    const SizedBox(height: 4),
                    // Training Points
                    if (activity['training_points'] != null && activity['training_points'] > 0)
                      Row(children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${activity['training_points']} điểm rèn luyện'),
                      ]),
                    const SizedBox(height: 4),
                    // Registration Deadline
                    if (activity['registration_deadline'] != null)
                      Row(children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text('Hạn đăng ký: ${_formatStart(DateTime.parse(activity['registration_deadline']))}'),
                      ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: registeredByMe ? Colors.amber.withOpacity(0.18) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: registeredByMe ? Colors.amber.shade600 : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          registeredByMe ? 'Đã đăng ký' : 'Chưa đăng ký',
                          style: TextStyle(
                            color: registeredByMe ? Colors.amber.shade800 : Colors.grey[700],
                            fontWeight: registeredByMe ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right),
                    ])
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _formatStart(DateTime dt) {
    final d = dt.toLocal();
    return '${_two(d.hour)}:${_two(d.minute)} ${_two(d.day)}/${_two(d.month)}/${d.year}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}


