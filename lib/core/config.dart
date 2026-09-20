import 'dart:io';
import 'package:flutter/foundation.dart';

class Config {
  static String get apiBaseUrl {
    // Development environment (local emulators)
    const isDev = true; // Hardcoded to true for Hackathon testing, can be swapped later
    if (isDev) {
      if (kIsWeb) return 'http://localhost:5001/nexserv-6d881/us-central1/api/api';
      if (Platform.isAndroid) return 'http://10.0.2.2:5001/nexserv-6d881/us-central1/api/api';
      if (Platform.isIOS) return 'http://localhost:5001/nexserv-6d881/us-central1/api/api';
      return 'http://localhost:5001/nexserv-6d881/us-central1/api/api';
    }
    
    // Production (deployed Cloud Functions)
    return 'https://us-central1-nexserv-6d881.cloudfunctions.net/api/api';
  }
}
