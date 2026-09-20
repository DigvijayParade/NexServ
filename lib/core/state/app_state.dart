import 'package:nexserv/core/config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

String get localhost {
  if (!kIsWeb && Platform.isAndroid) return '10.0.2.2';
  return '127.0.0.1';
}

class AppState extends ChangeNotifier {
  String _activeRole = 'Customer';
  String _locale = 'English';
  User? _currentUser;
  
  int _totalActiveJobs = 342;
  double _welfarePool = 3591.0;
  bool _isWorkerOnline = false;
  bool _hasIncomingJob = false;
  
  String get activeRole => _activeRole;
  String get locale => _locale;
  User? get currentUser => _currentUser;
  int get totalActiveJobs => _totalActiveJobs;
  double get welfarePool => _welfarePool;
  bool get isWorkerOnline => _isWorkerOnline;
  bool get hasIncomingJob => _hasIncomingJob;

  AppState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
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
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        String? token = await cred.user?.getIdToken();
        if (token != null) {
          final uri = Uri.parse('${Config.apiBaseUrl}/auth/register');
          await http.post(
            uri,
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({
              'uid': cred.user!.uid,
              'role': role.toLowerCase(),
              'email': email,
              'phone': phone ?? '',
              'name': name ?? 'User',
              'address': address ?? '',
              'service_category': profession
            })
          );
        }
      }
    } catch (e) {
      print('Auth error: $e');
    }
  }

  void setRole(String role) {
    _activeRole = role;
    notifyListeners();
  }

  void toggleLanguage() {
    if (_locale == 'English') _locale = 'Hindi';
    else if (_locale == 'Hindi') _locale = 'Marathi';
    else _locale = 'English';
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
      _userLocation = 'Connaught Place, Delhi (Demo)';
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _userLocation = 'Connaught Place, Delhi (Demo)';
        notifyListeners();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _userLocation = 'Connaught Place, Delhi (Demo)';
      notifyListeners();
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _userLocation = '${place.subLocality ?? place.locality}, ${place.administrativeArea}';
        notifyListeners();
      }
    } catch (e) {
      _userLocation = 'Connaught Place, Delhi (Demo)';
      notifyListeners();
    }
  }

  Future<void> addBooking() async {
    _totalActiveJobs++;
    _welfarePool += 15.0;
    if (_activeRole != 'Worker') _hasIncomingJob = true;
    notifyListeners();

    // Fire HTTP to backend
    if (_currentUser != null) {
      try {
        String? token = await _currentUser!.getIdToken();
        final uri = Uri.parse('http://$localhost:5001/nexserv-6d881/us-central1/api/api/jobs/create');
        await http.post(uri, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}, body: jsonEncode({
          'service_type': 'General Service',
          'service_rate': 250,
          'location': {'latitude': 0, 'longitude': 0, 'address': 'Test'}
        }));
      } catch(e) { print('Job creation error: $e'); }
    }
  }

  void toggleWorkerStatus() { _isWorkerOnline = !_isWorkerOnline; notifyListeners(); }
  void acceptIncomingJob() { _hasIncomingJob = false; notifyListeners(); }
  void clearIncomingJob() { _hasIncomingJob = false; notifyListeners(); }
  void resetData() {
    _activeRole = 'Customer'; _locale = 'English'; _totalActiveJobs = 342; _welfarePool = 3591.0; _isWorkerOnline = false; _hasIncomingJob = false;
    FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
