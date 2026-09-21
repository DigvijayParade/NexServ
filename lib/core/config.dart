import 'dart:io';
import 'package:flutter/foundation.dart';

class Config {
  static String get apiBaseUrl {
    // Development environment (local emulators)
    const isDev = false; // Set to false to use Production Render backend!
    if (isDev) {
      if (kIsWeb) return 'http://localhost:5001/nexserv-6d881/us-central1/api/api';
      if (Platform.isAndroid) return 'http://10.0.2.2:5001/nexserv-6d881/us-central1/api/api';
      if (Platform.isIOS) return 'http://localhost:5001/nexserv-6d881/us-central1/api/api';
      return 'http://localhost:5001/nexserv-6d881/us-central1/api/api';
    }
    
    // Production (deployed Render backend)
    return 'https://nexserv-gilc.onrender.com/api';
  }
}
