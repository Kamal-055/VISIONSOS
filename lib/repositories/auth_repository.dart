import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vision/core/constants/app_constants.dart';
import 'package:vision/core/errors/failures.dart';
import 'package:vision/models/user_model.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentFirebaseUser;
  Future<UserModel> getUserDetails(String uid);
  Future<UserModel> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  });
  Future<UserModel> signIn({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<void> updateProfile({required String name, required String phone});
}

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  @override
  Future<UserModel> getUserDetails(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();
      if (!doc.exists) {
        throw const DatabaseFailure('User profile not found in database.');
      }
      return UserModel.fromMap(doc.data()!);
    } on FirebaseException catch (e) {
      throw DatabaseFailure(e.message ?? 'Failed to load user profile data.');
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthFailure('Registration failed. Please try again.');
      }

      // Create user model
      final now = DateTime.now();
      final userModel = UserModel(
        uid: firebaseUser.uid,
        name: name.trim(),
        phone: phone.trim(),
        email: email.trim(),
        role: 'citizen',
        createdAt: now,
        lastLoginAt: now,
      );

      // Save user record to Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseException(e);
    } on FirebaseException catch (e) {
      throw DatabaseFailure(e.message ?? 'Failed to save user data.');
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Authenticate with Firebase Auth
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw const AuthFailure('Login failed. Please try again.');
      }

      // Update lastLoginAt in Firestore
      final now = DateTime.now();
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(firebaseUser.uid)
          .update({
        'lastLoginAt': Timestamp.fromDate(now),
      });

      // Load user details
      return await getUserDetails(firebaseUser.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseException(e);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw const AuthFailure('Failed to sign out. Please check your connection.');
    }
  }

  @override
  Future<void> updateProfile({required String name, required String phone}) async {
    try {
      final user = currentFirebaseUser;
      if (user == null) {
        throw const AuthFailure('No authenticated user found.');
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
        'name': name.trim(),
        'phone': phone.trim(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseFailure(e.message ?? 'Failed to update profile.');
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
