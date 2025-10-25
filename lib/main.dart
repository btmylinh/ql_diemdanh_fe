import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import 'features/auth/user_provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/manager/presentation/activity_form.dart';
import 'features/manager/presentation/activities_list_screen.dart';
import 'features/manager/presentation/activity_students_screen.dart';
import 'features/manager/presentation/attendance_session_screen.dart';
import 'features/admin/presentation/admin_dashboard.dart';
import 'features/admin/presentation/admin_users_screen.dart';
import 'features/admin/presentation/admin_activities_screen.dart';
import 'features/admin/presentation/admin_backup_restore.dart';
import 'features/student/presentation/student_dashboard.dart' as student_presentation;

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Bootstrap user data khi app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).bootstrapMe();
    });
    
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const _RoleBasedHome()),
      GoRoute(path: '/home', builder: (_, __) => const _RoleBasedHome()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      
      // Manager routes
      GoRoute(path: '/manager/activity/new', builder: (_, __) => const ActivityFormScreen()),
      GoRoute(path: '/manager/activity/:id/edit', builder: (_, __) => const ActivityFormScreen()),
      GoRoute(path: '/manager/activity/:id/students', builder: (_, __) => const ActivityStudentsScreen()),
      GoRoute(path: '/manager/activity/:id/attendance', builder: (_, __) => const AttendanceSessionScreen()),
      GoRoute(path: '/manager/activities', builder: (_, __) => const ActivitiesListScreen()),
      
      // Admin routes
      GoRoute(path: '/admin/dashboard', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: '/admin/activities', builder: (_, __) => const AdminActivitiesScreen()),
      GoRoute(path: '/admin/backup', builder: (_, __) => const AdminBackupRestoreScreen()),
      
      // Student routes
      GoRoute(path: '/student/dashboard', builder: (_, __) => const student_presentation.StudentDashboard()),
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
    
    // Redirect based on role
    if (user.isStudent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/student/dashboard');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (user.isManager) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/manager/activities');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (user.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/admin/dashboard');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      // No user or unknown role, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
  }
}

