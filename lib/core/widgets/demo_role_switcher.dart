import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../routes/app_routes.dart';

class DemoRoleSwitcher extends StatelessWidget {
  final Widget child;

  const DemoRoleSwitcher({super.key, required this.child});

  void _showRoleSwitcher(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final appState = Provider.of<AppState>(ctx, listen: false);
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Demo Presentation Controls',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('Switch to Customer Screen'),
                onPressed: () {
                  appState.setRole('Customer');
                  Navigator.pop(ctx);
                  AppRoutes.navigatorKey.currentState?.pushReplacementNamed(AppRoutes.customerHome);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.handyman),
                label: const Text('Switch to Worker Screen'),
                onPressed: () {
                  appState.setRole('Worker');
                  Navigator.pop(ctx);
                  AppRoutes.navigatorKey.currentState?.pushReplacementNamed(AppRoutes.workerHome);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Switch to Admin Screen'),
                onPressed: () {
                  appState.setRole('Admin');
                  Navigator.pop(ctx);
                  AppRoutes.navigatorKey.currentState?.pushReplacementNamed(AppRoutes.adminDashboard);
                },
              ),
              const Divider(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reset All App Data'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () {
                  appState.resetData();
                  Navigator.pop(ctx);
                  AppRoutes.navigatorKey.currentState?.pushReplacementNamed(AppRoutes.auth);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: Colors.amber,
            onPressed: () => _showRoleSwitcher(context),
            child: const Icon(Icons.developer_mode, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
