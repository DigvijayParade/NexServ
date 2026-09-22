import 'package:nexserv/core/config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  String _activeRole = 'Customer';
  String _locale = 'English';
  User? _currentUser;
  
  int _totalActiveJobs = 342;
  double _welfarePool = 3591.0;
  bool _isWorkerOnline = false;
  bool _hasIncomingJob = false;
  String _userLocation = 'Fetching location...';
  
  String get activeRole => _activeRole;
  String get locale => _locale;
  User? get currentUser => _currentUser;
  int get totalActiveJobs => _totalActiveJobs;
  double get welfarePool => _welfarePool;
  bool get isWorkerOnline => _isWorkerOnline;
  bool get hasIncomingJob => _hasIncomingJob;
  String get userLocation => _userLocation;

  AppState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
    fetchRealLocation(); // Auto-fetch real location on startup
  }

  Future<void> authenticate({
    required bool isLogin,
    required String email,
    required String password,
    required String role,
    String? name,
    String? phone,
    String? profession,
    String? address,
  }) async {
    _activeRole = role;
    notifyListeners();

    try {
      if (isLogin) {
        final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        // Check if user is banned
        final userData = await getUserData(cred.user!.uid);
        if (userData != null && userData['banned'] == true) {
          await FirebaseAuth.instance.signOut();
          throw Exception('Your account has been suspended. Please contact the administrator.');
        }
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        // Save profile directly to Firestore
        final userData = {
          'uid': cred.user!.uid,
          'role': role.toLowerCase(),
          'email': email,
          'phone': phone ?? '',
          'name': name ?? '',
          'address': address ?? '',
          'service_category': profession,
          'created_at': FieldValue.serverTimestamp(),
        };
        
        // Save exclusively to role-specific collections (customers, workers, admins)
        String roleCollection = 'customers';
        if (role.toLowerCase() == 'worker') roleCollection = 'workers';
        if (role.toLowerCase().contains('cooperative') || role.toLowerCase() == 'admin') roleCollection = 'admins';
        
        await FirebaseFirestore.instance.collection(roleCollection).doc(cred.user!.uid).set(userData);
      }
    } catch (e) {
      debugPrint('Auth error: \$e');
      rethrow;
    }
  }

  void setRole(String role) {
    _activeRole = role;
    notifyListeners();
  }

  void toggleLanguage() {
    if (_locale == 'English') {
      _locale = 'Hindi';
    } else if (_locale == 'Hindi') {
      _locale = 'Marathi';
    } else {
      _locale = 'English';
    }
    notifyListeners();
  }

  void setLanguage(String lang) {
    _locale = lang;
    notifyListeners();
  }

  Future<void> fetchRealLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _userLocation = 'Location unavailable';
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _userLocation = 'Location unavailable';
        notifyListeners();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _userLocation = 'Location unavailable';
      notifyListeners();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      final _geocoder = geocoding.Geocoding();
      List<geocoding.Placemark> placemarks = await _geocoder.placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        geocoding.Placemark place = placemarks[0];
        _userLocation = '${place.subLocality ?? place.locality}, ${place.administrativeArea}';
        notifyListeners();
      }
    } catch (e) {
      _userLocation = 'Location unavailable';
      notifyListeners();
    }
  }

  Future<void> addBooking() async {
    _totalActiveJobs++;
    _welfarePool += 15.0;
    if (_activeRole != 'Worker') _hasIncomingJob = true;
    notifyListeners();

    if (_currentUser != null) {
      try {
        String? token = await _currentUser!.getIdToken();
        final String baseHost = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : '127.0.0.1';
        final uri = Uri.parse('http://\$baseHost:5001/nexserv-6d881/us-central1/api/api/jobs/create');
        await http.post(uri,
          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer \$token'},
          body: jsonEncode({
            'service_type': 'General Service',
            'service_rate': 250,
            'location': {'latitude': 0, 'longitude': 0, 'address': 'Test'}
          }));
      } catch (e) {
        debugPrint('Job creation error: \$e');
      }
    }
  }

  void toggleWorkerStatus() {
    _isWorkerOnline = !_isWorkerOnline;
    notifyListeners();
  }

  void acceptIncomingJob() {
    _hasIncomingJob = false;
    notifyListeners();
  }

  void clearIncomingJob() {
    _hasIncomingJob = false;
    notifyListeners();
  }

  void resetData() {
    _activeRole = 'Customer';
    _locale = 'English';
    _totalActiveJobs = 342;
    _welfarePool = 3591.0;
    _isWorkerOnline = false;
    _hasIncomingJob = false;
    FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  // Helper to fetch user data since we no longer have a central 'users' collection
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    for (var collection in ['customers', 'workers', 'admins']) {
      final doc = await FirebaseFirestore.instance.collection(collection).doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    }
    return null;
  }
}