import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/state/app_state.dart';
import 'core/routes/app_routes.dart';
import 'core/widgets/demo_role_switcher.dart';

void main() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.amber, size: 64),
            const SizedBox(height: 16),
            const Text('A minor UI error occurred. Please continue presentation.'),
            if (details.exceptionAsString().isNotEmpty)
              Text(
                details.exceptionAsString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const CoopGigApp(),
    ),
  );
}

class CoopGigApp extends StatelessWidget {
  const CoopGigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexServ',
      navigatorKey: AppRoutes.navigatorKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F5A47), // Deep Emerald Green
          primary: const Color(0xFF0F5A47),
          secondary: const Color(0xFFFFB800), // Warm Gold/Amber
          surface: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F5A47),
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: AppRoutes.auth,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        return DemoRoleSwitcher(child: child!);
      },
    );
  }
}
