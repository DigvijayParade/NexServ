import 'package:flutter/material.dart';

import '../../features/auth/screens/auth_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/customer/screens/live_tracking_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/history/screens/job_history_screen.dart';
import '../../features/worker/screens/worker_home_screen.dart';
import '../../features/worker/screens/active_job_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String auth = '/';
  static const String customerHome = '/customerHome';
  static const String workerHome = '/workerHome';
  static const String adminDashboard = '/adminDashboard';
  static const String liveTracking = '/liveTracking';
  static const String activeJob = '/activeJob';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case auth:
        page = const AuthScreen();
        break;
      case customerHome:
        page = const CustomerHomeScreen();
        break;
      case adminDashboard:
        page = const AdminDashboardScreen();
        break;
      case liveTracking:
        final jobId = settings.arguments as String? ?? 'dummy_job_id';
        page = LiveTrackingScreen(jobId: jobId);
        break;
      case workerHome:
        page = const WorkerHomeScreen();
        break;
      case activeJob:
        final jobId = settings.arguments as String?;
        page = ActiveJobScreen(jobId: jobId);
        break;
      case '/history':
        page = const JobHistoryScreen();
        break;
      case '/profile':
        page = const EditProfileScreen();
        break;
      default:
        page = const AuthScreen();
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
