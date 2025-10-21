import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';

// removed for Session 3.2 scope: activity form (manager/admin)
import 'features/student/presentation/student_activities_screen.dart';
import 'features/student/presentation/activity_detail.dart';
import 'features/student/presentation/my_activities.dart';
import 'features/student/presentation/qr_scan.dart';
import 'features/student/presentation/student_dashboard.dart' as student_presentation;
import 'features/student/presentation/student_profile.dart' as student_presentation;
// removed for Session 3.1 scope: admin/manager dashboards
import 'features/auth/user_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
// Manager screens (Session 3.3)
import 'features/manager/presentation/manager_dashboard.dart';
import 'features/manager/presentation/activity_form.dart';
import 'features/manager/presentation/registrations_screen.dart';
import 'features/manager/presentation/batch_registrations_screen.dart';
import 'features/manager/presentation/activities_list_screen.dart';
import 'features/manager/presentation/attendance_session_screen.dart';
// Admin screens (Session 3.4) - TODO: Implement in future session
// import 'features/admin/presentation/admin_users.dart';
// import 'features/admin/presentation/admin_activities.dart';
// import 'features/admin/presentation/admin_backup_restore.dart';
// import 'features/admin/presentation/admin_reports.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bootstrap current user from token on app start
    ref.read(authControllerProvider.notifier).bootstrapMe();
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      
      // Role-based routing (Session 3.2: student only)
      GoRoute(path: '/home', builder: (_, __) => const _RoleBasedHome()),
      
     
      // Manager routes
      GoRoute(path: '/manager/dashboard', builder: (_, __) => const ManagerDashboardScreen()),
      GoRoute(path: '/manager/activity/new', builder: (_, __) => const ActivityFormScreen()),
      GoRoute(path: '/manager/activity/:id/edit', builder: (_, __) => const ActivityFormScreen()),
      GoRoute(path: '/manager/activity/:id/registrations', builder: (_, __) => const RegistrationsScreen()),
      GoRoute(path: '/manager/batch-registrations', builder: (_, __) => const BatchRegistrationsScreen()),
      GoRoute(path: '/manager/activities', builder: (_, __) => const ActivitiesListScreen()),
      GoRoute(path: '/manager/activity/:id/attendance', builder: (_, __) => const AttendanceSessionScreen()),

      // Student routes
      GoRoute(path: '/student/dashboard', builder: (_, __) => const student_presentation.StudentDashboard()),
      GoRoute(path: '/student/profile', builder: (_, __) => const student_presentation.StudentProfileScreen()),
      GoRoute(path: '/student/activities', builder: (_, __) => const StudentActivitiesScreen()),
      GoRoute(path: '/student/activities/:id', builder: (ctx, st) {
        final idStr = st.pathParameters['id']!;
        final id = int.tryParse(idStr) ?? 0;
        return ActivityDetailScreen(activityId: id);
      }),
      GoRoute(path: '/student/my', builder: (_, __) => const MyActivitiesScreen()),
      GoRoute(path: '/student/qr-scan', builder: (_, __) => const QrScanScreen()),

      // creation/edit screens are out of scope for Session 3.2
    ]);
    return MaterialApp.router(
      title: 'CNTT Activities',
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _RoleBasedHome extends ConsumerWidget {
  const _RoleBasedHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    
    // Debug log
    debugPrint('[ROLE_BASED_HOME] Entered with user: ${user.user} / role: ${user.role}');
    
    // Redirect based on role
    if (user.isStudent) {
      debugPrint('[ROLE_BASED_HOME] Student detected -> redirecting to /student/dashboard');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/student/dashboard');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (user.isManager) {
      debugPrint('[ROLE_BASED_HOME] Manager detected -> redirecting to /manager/dashboard');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/manager/dashboard');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (user.isAdmin) {
      debugPrint('[ROLE_BASED_HOME] Admin detected -> redirecting to /manager/dashboard (admin features not implemented yet)');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/manager/dashboard');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      // No user or unknown role, redirect to login
      debugPrint('[ROLE_BASED_HOME] No user or unknown role -> redirecting to /login');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
  }
}
