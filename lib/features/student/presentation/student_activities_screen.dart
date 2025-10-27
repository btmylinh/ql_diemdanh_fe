import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/activities_providers.dart';
import '../../../theme.dart';

class StudentActivitiesScreen extends ConsumerStatefulWidget {
  const StudentActivitiesScreen({super.key});

  @override
  ConsumerState<StudentActivitiesScreen> createState() => _StudentActivitiesScreenState();
}

class _StudentActivitiesScreenState extends ConsumerState<StudentActivitiesScreen> {
  String _selectedFilter = 'Tất cả';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(activitiesListProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hoạt động CNTT',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Ongoing Activity Banner
          listAsync.when(
            data: (data) => _buildOngoingBanner(List<Map<String, dynamic>>.from(data['activities'] ?? [])),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
                child: TextField(
              controller: _searchController,
                  decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoạt động...',
                    prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: kGreen),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          
          // Filter bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Tất cả',
                    isSelected: _selectedFilter == 'Tất cả',
                    onSelected: () => setState(() => _selectedFilter = 'Tất cả'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Đang diễn ra',
                    isSelected: _selectedFilter == 'Đang diễn ra',
                    onSelected: () => setState(() => _selectedFilter = 'Đang diễn ra'),
              ),
              const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Chưa đăng ký',
                    isSelected: _selectedFilter == 'Chưa đăng ký',
                    onSelected: () => setState(() => _selectedFilter = 'Chưa đăng ký'),
              ),
              const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Đã đăng ký',
                    isSelected: _selectedFilter == 'Đã đăng ký',
                    onSelected: () => setState(() => _selectedFilter = 'Đã đăng ký'),
                  ),
                ],
              ),
            ),
          ),
          // Activities list
          Expanded(
            child: listAsync.when(
              data: (data) {
                final raw = List<Map<String, dynamic>>.from(data['activities'] ?? []);
                
                // Lọc theo search query
                List<Map<String, dynamic>> filtered = raw;
                if (_searchQuery.isNotEmpty) {
                  filtered = raw.where((activity) {
                    final name = activity['name']?.toString().toLowerCase() ?? '';
                    return name.contains(_searchQuery.toLowerCase());
                }).toList();
                }
                
                // Lọc theo filter
                List<Map<String, dynamic>> result = [];
                final now = DateTime.now();
                
                for (final activity in filtered) {
                  final status = activity['status'] as int?;
                  final registered = activity['registered_by_me'] == true;
                  final startTime = DateTime.tryParse(activity['start_time']?.toString() ?? '');
                  final endTime = DateTime.tryParse(activity['end_time']?.toString() ?? '');
                  final registrationDeadline = DateTime.tryParse(activity['registration_deadline']?.toString() ?? '');
                  
                  // Loại bỏ hoạt động đã hủy (status = 4) hoặc đã hoàn thành (status = 3)
                  if (status == 3 || status == 4) {
                    continue;
                  }
                  
                  // Loại bỏ hoạt động đã kết thúc (endTime đã qua)
                  if (endTime != null && now.isAfter(endTime)) {
                    continue;
                  }
                  
                  bool isOngoing = false;
                  bool isExpired = false;
                  
                  if (startTime != null && endTime != null) {
                    isOngoing = now.isAfter(startTime) && now.isBefore(endTime);
                  }
                  
                  if (registrationDeadline != null) {
                    isExpired = now.isAfter(registrationDeadline);
                  }
                  
                  bool shouldInclude = false;
                  
                  switch (_selectedFilter) {
                    case 'Tất cả':
                      shouldInclude = true;
                      break;
                    case 'Đang diễn ra':
                      shouldInclude = isOngoing;
                      break;
                    case 'Chưa đăng ký':
                      shouldInclude = !registered && !isExpired;
                      break;
                    case 'Đã đăng ký':
                      shouldInclude = registered;
                      break;
                  }
                  
                  if (shouldInclude) {
                    result.add(activity);
                  }
                }
                
                if (result.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? 'Không tìm thấy hoạt động nào'
                              : 'Không có hoạt động',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Thử tìm kiếm với từ khóa khác',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ...result.map((activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ActivityCard(activity: activity),
                    )),
                  ],
                );
              },
              error: (e, st) => Center(
                child: Text(
                  'Lỗi: $e',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }

  Widget _buildOngoingBanner(List<Map<String, dynamic>> activities) {
    final now = DateTime.now();
    
    // Tìm hoạt động đang diễn ra mà sinh viên đã đăng ký
    final ongoingActivity = activities.firstWhere(
      (activity) {
        final registered = activity['registered_by_me'] == true;
        final status = activity['status'] ?? 0;
        final start = DateTime.tryParse(activity['start_time']?.toString() ?? '');
        final end = DateTime.tryParse(activity['end_time']?.toString() ?? '');
        
        return registered && 
               status == 2 && // Đang diễn ra
               start != null && 
               now.isAfter(start) && 
               (end == null || now.isBefore(end));
      },
      orElse: () => <String, dynamic>{},
    );
    
    if (ongoingActivity.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kGreen, kGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: kGreen.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_circle_fill,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hoạt động đang diễn ra',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ongoingActivity['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Điểm danh ngay',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              context.push('/student/activity/${ongoingActivity['id']}');
            },
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kBlue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
  });

  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final name = activity['name'] ?? 'Hoạt động';
    final startTime = DateTime.tryParse(activity['start_time']?.toString() ?? '');
    final registrationDeadline = DateTime.tryParse(activity['registration_deadline']?.toString() ?? '');
    final registered = activity['registered_by_me'] == true;
    final now = DateTime.now();
    
    // Xác định tags
    List<_Tag> tags = [];
    
    // Tag đang diễn ra
    if (startTime != null) {
      final endTime = DateTime.tryParse(activity['end_time']?.toString() ?? '');
      if (endTime != null && now.isAfter(startTime) && now.isBefore(endTime)) {
        tags.add(_Tag(
          label: 'Đang diễn ra',
          color: Colors.green,
          textColor: Colors.white,
        ));
      }
    }
    
    // Tag đã đăng ký
    if (registered) {
      tags.add(_Tag(
        label: 'Đã đăng ký',
        color: Colors.blue,
        textColor: Colors.white,
      ));
    }
    
    // Tag hết hạn đăng ký
    if (registrationDeadline != null && now.isAfter(registrationDeadline)) {
      tags.add(_Tag(
        label: 'Hết hạn đăng ký',
        color: Colors.red,
        textColor: Colors.white,
      ));
    }

    return GestureDetector(
      onTap: () => context.push('/student/activity/${activity['id']}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
        borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Title
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            
            // Thông tin chi tiết
            _InfoRow(
              icon: Icons.access_time,
              label: 'Hạn đăng ký',
              value: registrationDeadline != null 
                  ? _formatDateTime(registrationDeadline)
                  : 'Không có',
              iconColor: Colors.red,
            ),
            const SizedBox(height: 8),
            
            _InfoRow(
              icon: Icons.schedule,
              label: 'Thời gian bắt đầu',
              value: startTime != null 
                  ? _formatDateTime(startTime)
                  : 'Không có',
              iconColor: Colors.blue,
            ),
            
            // Tags
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: tag.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag.label,
                    style: TextStyle(
                      color: tag.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _Tag {
  const _Tag({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;
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
                  children: [
        Icon(icon, size: 16, color: iconColor),
                        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
                        child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
                          ),
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
                isActive: true,
                onTap: () {},
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