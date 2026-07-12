import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:motoshop_app/presentation/screens/admin/repuestos_mantenimiento_admin_screen.dart';
import 'package:motoshop_app/presentation/screens/admin/pagos_admin_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_confirm_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/moto_detail_screen.dart';
import '../screens/catalog/moto_form_screen.dart';
import '../screens/inventory/inventory_dashboard_screen.dart';
import '../screens/inventory/movimiento_form_screen.dart';
import '../screens/inventory/repuesto_detail_screen.dart';
import '../screens/inventory/repuesto_form_screen.dart';
import '../screens/admin/compras_admin_screen.dart';
import '../screens/admin/proveedores_admin_screen.dart';
import '../screens/admin/servicios_admin_screen.dart';
import '../screens/admin/users_admin_screen.dart';
import '../widgets/admin_shell.dart';
import '../screens/admin/mantenimientos_admin_screen.dart';
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

      final isPrivateRoute =
          location == '/profile' ||
          location == '/moto-form' ||
          location == '/repuesto-form' ||
          location == '/movimiento-form' ||
          isAdminRoute;

      if (!isAuthenticated && isPrivateRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return isStaff ? '/admin' : '/';
      }


      if (isAuthenticated && !isStaff && isAdminRoute) {
        return '/';
      }

      return null;
    },

    routes: [
      // ── Sección pública ─────────────────────────────────

      GoRoute(
        path: '/',
        builder: (context, state) => const CatalogScreen(),
      ),

      GoRoute(
        path: '/moto-detail/:id',
        builder: (context, state) {
          final id = int.tryParse(
                state.pathParameters['id'] ?? '',
              ) ??
              0;

          return MotoDetailScreen(motoId: id);
        },
      ),

      GoRoute(
        path: '/inventory',
        builder: (context, state) =>
            const InventoryDashboardScreen(),
      ),

      GoRoute(
        path: '/repuesto-detail/:id',
        builder: (context, state) {
          final id = int.tryParse(
                state.pathParameters['id'] ?? '',
              ) ??
              0;

          return RepuestoDetailScreen(repuestoId: id);
        },
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

      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // ── Formularios privados ────────────────────────────

      GoRoute(
        path: '/moto-form',
        builder: (context, state) {
          final id = int.tryParse(
                state.uri.queryParameters['id'] ?? '',
              ) ??
              0;

          return MotoFormScreen(
            motoId: id > 0 ? id : null,
          );
        },
      ),

      GoRoute(
        path: '/repuesto-form',
        builder: (context, state) {
          final id = int.tryParse(
                state.uri.queryParameters['id'] ?? '',
              ) ??
              0;

          return RepuestoFormScreen(
            repuestoId: id > 0 ? id : null,
          );
        },
      ),

      GoRoute(
        path: '/movimiento-form',
        builder: (context, state) =>
            const MovimientoFormScreen(),
      ),

      // ── Administración ──────────────────────────────────

      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/servicios',
      ),

      GoRoute(
        path: '/admin/servicios',
        builder: (context, state) => AdminShell(
          title: 'Servicios',
          currentRoute: state.matchedLocation,
          child: const ServiciosAdminScreen(),
        ),
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
      GoRoute(
        path: '/admin/mantenimientos',
        builder: (context, state) => AdminShell(
          title: 'Mantenimientos',
          currentRoute: state.matchedLocation,
          child: const MantenimientosAdminScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/repuestos-mantenimiento',
        builder: (context, state) => AdminShell(
          title: 'Repuestos de mantenimiento',
          currentRoute: state.matchedLocation,
          child: const RepuestosMantenimientoAdminScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => AdminShell(
          title: 'Usuarios',
          currentRoute: state.matchedLocation,
          child: const UsersAdminScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/pagos',
        builder: (context, state) => AdminShell(
          title: 'Pagos',
          currentRoute: state.matchedLocation,
          child: const PagosAdminScreen(),
        ),
      ),
    ],
  );
});