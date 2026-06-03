import 'package:firebase_auth/firebase_auth.dart';

abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection. Please verify your network.']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message);

  factory AuthFailure.fromFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AuthFailure('The email address is badly formatted.');
      case 'user-disabled':
        return const AuthFailure('This user account has been disabled.');
      case 'user-not-found':
        return const AuthFailure('No user found with this email.');
      case 'wrong-password':
        return const AuthFailure('Incorrect password. Please try again.');
      case 'email-already-in-use':
        return const AuthFailure('The email account is already registered.');
      case 'weak-password':
        return const AuthFailure('The password provided is too weak.');
      case 'network-request-failed':
        return const AuthFailure('Network error. Check your internet connection.');
      case 'too-many-requests':
        return const AuthFailure('Too many attempts. Please try again later.');
      default:
        return AuthFailure(e.message ?? 'An unknown authentication error occurred.');
    }
  }
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred. Please try again.']);
}
