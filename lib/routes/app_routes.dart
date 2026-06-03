import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vision/providers/auth_provider.dart';

// Screens
import 'package:vision/features/splash/splash_screen.dart';
import 'package:vision/features/auth/login/login_screen.dart';
import 'package:vision/features/auth/register/register_screen.dart';
import 'package:vision/features/auth/forgot_password/forgot_password_screen.dart';
import 'package:vision/features/home/home_screen.dart';
import 'package:vision/features/profile/profile_screen.dart';

// Helper class to adapt a Stream to a Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// Track whether splash animation is completed to avoid redirect glitch
final splashFinishedProvider = StateProvider<bool>((ref) => false);

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final splashFinished = ref.watch(splashFinishedProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepo.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authRepo.currentFirebaseUser != null;
      
      // Determine what state we are visiting
      final isSplash = state.matchedLocation == '/';
      final isLogin = state.matchedLocation == '/login';
      final isRegister = state.matchedLocation == '/register';
      final isForgotPassword = state.matchedLocation == '/forgot-password';
      
      final isAuthRoute = isLogin || isRegister || isForgotPassword;

      // If splash screen hasn't finished animating, stay on splash
      if (!splashFinished) {
        return isSplash ? null : '/';
      }

      if (!isLoggedIn) {
        // Force unauthenticated user to login screen
        if (!isAuthRoute) {
          return '/login';
        }
      } else {
        // Force authenticated user away from auth pages to home screen
        if (isAuthRoute || isSplash) {
          return '/home';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
