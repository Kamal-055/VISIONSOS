import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vision/models/user_model.dart';
import 'package:vision/services/auth_service.dart';
import 'package:vision/services/firebase_service.dart';

// Providers for the services
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firebaseServiceProvider = Provider<FirebaseService>((ref) => FirebaseService());

// State class for Auth State
class AuthState {
  final UserModel? user;
  final Map<String, String>? contacts;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.contacts,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    UserModel? user,
    Map<String, String>? contacts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // can be cleared
    );
  }

  bool get isAuthenticated => user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FirebaseService _firebaseService;

  AuthNotifier(this._authService, this._firebaseService) : super(const AuthState()) {
    // Automatically load current user on provider creation
    _initUser();
  }

  Future<void> _initUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      state = state.copyWith(isLoading: true);
      try {
        var profile = await _firebaseService.getUserProfile(user.uid);
        profile ??= UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Citizen',
          phone: user.phoneNumber ?? '',
          email: user.email ?? '',
          registeredAt: DateTime.now().toUtc().toIso8601String(),
        );
        final contacts = await _firebaseService.getEmergencyContacts(user.uid);
        state = state.copyWith(user: profile, contacts: contacts, isLoading: false);
      } catch (e) {
        final fallbackProfile = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Citizen',
          phone: user.phoneNumber ?? '',
          email: user.email ?? '',
          registeredAt: DateTime.now().toUtc().toIso8601String(),
        );
        state = state.copyWith(
          user: fallbackProfile,
          isLoading: false,
          errorMessage: 'Database profile not found or permission denied. Using session fallback.',
        );
      }
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = await _authService.signIn(email, password);
      final firebaseUser = credential.user!;
      
      UserModel? profile;
      try {
        profile = await _firebaseService.getUserProfile(firebaseUser.uid);
      } catch (e) {
        // Fallback on error
      }

      profile ??= UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Citizen',
        phone: firebaseUser.phoneNumber ?? '',
        email: firebaseUser.email ?? '',
        registeredAt: DateTime.now().toUtc().toIso8601String(),
      );

      Map<String, String>? contacts;
      try {
        contacts = await _firebaseService.getEmergencyContacts(firebaseUser.uid);
      } catch (e) {
        // Fallback
      }

      state = state.copyWith(user: profile, contacts: contacts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = await _authService.signUp(email, password);
      final uid = credential.user!.uid;
      
      // Write metadata to Realtime Database
      try {
        await _firebaseService.createUserProfile(uid, name, phone, email);
      } catch (e) {
        // Suppress write errors so auth is not broken by database rules
      }
      
      UserModel? profile;
      try {
        profile = await _firebaseService.getUserProfile(uid);
      } catch (e) {
        // Suppress
      }

      profile ??= UserModel(
        uid: uid,
        name: name,
        phone: phone,
        email: email,
        registeredAt: DateTime.now().toUtc().toIso8601String(),
      );

      Map<String, String>? contacts;
      try {
        contacts = await _firebaseService.getEmergencyContacts(uid);
      } catch (e) {
        // Suppress
      }
      
      state = state.copyWith(user: profile, contacts: contacts, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> updateProfile({required String name, required String phone}) async {
    final currentUser = state.user;
    if (currentUser == null) return;
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _firebaseService.updateUserProfile(currentUser.uid, name, phone);
      final updatedUser = currentUser.copyWith(name: name, phone: phone);
      state = state.copyWith(user: updatedUser, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> updateContacts({
    required String mother,
    required String father,
    required String friend,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _firebaseService.updateEmergencyContacts(
        currentUser.uid,
        mother: mother,
        father: father,
        friend: friend,
      );
      state = state.copyWith(
        contacts: {'mother': mother, 'father': father, 'friend': friend},
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _authService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final firebaseService = ref.watch(firebaseServiceProvider);
  return AuthNotifier(authService, firebaseService);
});
