import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'core/state/app_state.dart';
import 'core/routes/app_routes.dart';

String get localhost {
  if (!kIsWeb && Platform.isAndroid) return '10.0.2.2';
  return '127.0.0.1';
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Connect to local emulators
    // FirebaseFirestore.instance.useFirestoreEmulator(localhost, 8080);
    // await FirebaseAuth.instance.useAuthEmulator(localhost, 9099);
  } catch (e) {
    print('Firebase initialization error: $e');
  }

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
          seedColor: const Color(0xFF0F5A47),
          primary: const Color(0xFF0F5A47),
          secondary: const Color(0xFFFFB800),
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
        return child!;
      },
    );
  }
}
