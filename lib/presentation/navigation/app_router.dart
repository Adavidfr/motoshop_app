// lib/presentation/navigation/app_router.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/admin/compras_admin_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_confirm_screen.dart';
import '../screens/admin/proveedores_admin_screen.dart';
import '../widgets/admin_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',

    redirect: (context, state) {
      if (authState.isChecking) {
        return null;
      }

      final isAuthenticated = authState.isAuthenticated;
      final isStaff = authState.isStaff;
      final location = state.matchedLocation;

      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/reset-password-confirm';

      final isAdminRoute = location.startsWith('/admin');

      // Usuario sin sesión
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Usuario autenticado intentando regresar al login
      if (isAuthenticated && isAuthRoute) {
        return isStaff ? '/admin' : '/';
      }

      // Cliente intentando ingresar al panel administrativo
      if (isAuthenticated && !isStaff && isAdminRoute) {
        return '/';
      }

      return null;
    },

    routes: [
      // ── Perfil principal ────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const ProfileScreen(),
      ),

      // ── Autenticación ───────────────────────────────────
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
        builder: (context, state) =>
            const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password-confirm',
        builder: (context, state) =>
            const ResetPasswordConfirmScreen(),
      ),

      // ── Administración ──────────────────────────────────
      GoRoute(
        path: '/admin',
        redirect: (context, state) =>
            '/admin/proveedores',
      ),

      GoRoute(
        path: '/admin/proveedores',
        builder: (context, state) => AdminShell(
          title: 'Proveedores',
          currentRoute: state.matchedLocation,
          child: const ProveedoresAdminScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/compras',
        builder: (context, state) => AdminShell(
          title: 'Compras',
          currentRoute: state.matchedLocation,
          child: const ComprasAdminScreen(),
        ),
      ),
    ],
  );
});