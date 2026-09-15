import 'package:flutter/material.dart';

class AppState extends ChangeNotifier {
  String _activeRole = 'Customer';
  String _locale = 'English';
  
  int _totalActiveJobs = 342;
  double _welfarePool = 3591.0;
  
  bool _isWorkerOnline = false;
  bool _hasIncomingJob = false;
  
  String get activeRole => _activeRole;
  String get locale => _locale;
  int get totalActiveJobs => _totalActiveJobs;
  double get welfarePool => _welfarePool;
  bool get isWorkerOnline => _isWorkerOnline;
  bool get hasIncomingJob => _hasIncomingJob;

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

  void addBooking() {
    _totalActiveJobs++;
    _welfarePool += 15.0; // Simulated welfare pool increment
    if (_activeRole != 'Worker') {
       _hasIncomingJob = true; // Trigger for demo purpose when booked from customer
    }
    notifyListeners();
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
    notifyListeners();
  }
}
