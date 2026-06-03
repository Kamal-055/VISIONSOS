import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vision/models/user_model.dart';
import 'package:vision/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Listen to Firebase Auth changes to sync profile
    _ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) async {
      next.when(
        data: (firebaseUser) async {
          if (firebaseUser == null) {
            state = const AsyncValue.data(null);
          } else {
            await loadUserDetails(firebaseUser.uid);
          }
        },
        error: (err, stack) {
          state = AsyncValue.error(err, stack);
        },
        loading: () {
          // Do not overwrite existing profile state with loading
          // if we are already logged in to prevent visual flashes
          if (state.value == null) {
            state = const AsyncValue.loading();
          }
        },
      );
    });

    // Check initial session
    final initialUser = _authRepository.currentFirebaseUser;
    if (initialUser != null) {
      loadUserDetails(initialUser.uid);
    } else {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> loadUserDetails(String uid) async {
    try {
      final userModel = await _authRepository.getUserDetails(uid);
      state = AsyncValue.data(userModel);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final userModel = await _authRepository.signIn(
        email: email,
        password: password,
      );
      state = AsyncValue.data(userModel);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userModel = await _authRepository.signUp(
        name: name,
        phone: phone,
        email: email,
        password: password,
      );
      state = AsyncValue.data(userModel);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({required String name, required String phone}) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    state = const AsyncValue.loading();
    try {
      await _authRepository.updateProfile(name: name, phone: phone);
      final updatedUser = currentUser.copyWith(name: name, phone: phone);
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
