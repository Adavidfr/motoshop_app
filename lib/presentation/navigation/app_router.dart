import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_confirm_screen.dart';
import '../screens/admin/users_admin_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/moto_detail_screen.dart';
import '../screens/catalog/moto_form_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isChecking = authState.isChecking;
      if (isChecking) return null; // Esperar a que verifique la sesión local

      final isAuth = authState.isAuthenticated;
      final goingToLogin = state.uri.path == '/login';
      final goingToRegister = state.uri.path == '/register';
      final goingToForgot = state.uri.path == '/forgot-password';
      final goingToReset = state.uri.path == '/reset-password-confirm';

      final inAuthFlow = goingToLogin || goingToRegister || goingToForgot || goingToReset;

      if (!isAuth && !inAuthFlow) return '/login';
      if (isAuth && inAuthFlow) return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const UsersAdminScreen(),
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
        path: '/reset-password-confirm',
        builder: (context, state) {
          return const ResetPasswordConfirmScreen();
        },
      ),
      GoRoute(
        path: '/moto-detail/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return MotoDetailScreen(motoId: id);
        },
      ),
      GoRoute(
        path: '/moto-form',
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          return MotoFormScreen(motoId: id > 0 ? id : null);
        },
      ),
    ],
  );
});
