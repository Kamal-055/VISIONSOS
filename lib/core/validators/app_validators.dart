// Utility class containing all form validation methods
class AppValidators {

  // Validates user's full name
  // Checks:
  // 1. Name should not be empty
  // 2. Name should contain at least 3 characters
  static String? validateName(String? value) {
    // Check if name field is empty or null
    if (value == null || value.trim().isEmpty) {
      return 'Full Name is required';
    }

    // Check minimum length requirement
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  // Validates phone number
  // Checks:
  // 1. Phone number should not be empty
  // 2. Phone number must contain exactly 10 digits
  static String? validatePhone(String? value) {

    // Check if phone number field is empty
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    // Remove all non-digit characters from input
    // Example: +91-9876543210 -> 919876543210
    final cleanPhone = value.replaceAll(RegExp(r'\D'), '');

    // Verify phone number length
    if (cleanPhone.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  // Validates email address
  // Checks:
  // 1. Email should not be empty
  // 2. Email must match valid email format
  static String? validateEmail(String? value) {

    // Check if email field is empty
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }

    // Regular Expression (Regex) pattern for email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );

    // Validate email against regex pattern
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Validates password strength
  // Checks:
  // 1. Password should not be empty
  // 2. Minimum length = 8 characters
  // 3. Must contain uppercase letter
  // 4. Must contain lowercase letter
  // 5. Must contain number
  // 6. Must contain special character
  static String? validatePassword(String? value) {

    // Check if password field is empty
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    // Check minimum password length
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Check for at least one uppercase letter (A-Z)
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for at least one lowercase letter (a-z)
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for at least one numeric digit (0-9)
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  // Validates confirm password field
  // Checks:
  // 1. Confirm password should not be empty
  // 2. Confirm password must match original password
  static String? validateConfirmPassword(String? value, String password) {

    // Check if confirm password field is empty
    if (value == null || value.isEmpty) {
      return 'Confirm Password is required';
    }

    // Compare confirm password with original password
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
