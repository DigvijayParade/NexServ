class Validators {
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a valid full name (minimum 3 letters).';
    }
    final trimmedValue = value.trim();
    if (trimmedValue.length < 3) {
      return 'Please enter a valid full name (minimum 3 letters).';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmedValue)) {
      return 'Please enter a valid full name (minimum 3 letters).';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a valid Gmail address (e.g., user@gmail.com).';
    }
    final trimmedValue = value.trim().toLowerCase();
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$').hasMatch(trimmedValue)) {
      return 'Please enter a valid Gmail address (e.g., user@gmail.com).';
    }
    return null;
  }

  static String? validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a valid 10-digit Indian mobile number.';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return 'Please enter a valid 10-digit Indian mobile number.';
    }
    return null;
  }

  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a valid 12-digit Worker Verification / Aadhaar number.';
    }
    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      return 'Please enter a valid 12-digit Worker Verification / Aadhaar number.';
    }
    return null;
  }

  static String? validatePassword(String? value, {bool isRegistration = false}) {
    if (value == null || value.isEmpty) {
      return isRegistration 
          ? 'Password must be 8+ chars with uppercase, lowercase, number & special symbol (@#\$%^&*!_).'
          : 'Please enter your password.';
    }
    if (isRegistration) {
      if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@#\$%^&*!_]).{8,}$').hasMatch(value)) {
        return 'Password must be 8+ chars with uppercase, lowercase, number & special symbol (@#\$%^&*!_).';
      }
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Passwords do not match.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }
}
