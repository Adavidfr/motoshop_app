// lib/presentation/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Modelos y providers comunes
import '../../domain/model/auth_state.dart';
import '../../domain/model/product.dart';
import '../providers/auth_provider.dart';

// Pantallas públicas y del cliente (Tarea 6)
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_confirm_screen.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/catalog/home_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/orders/client_orders_screen.dart';
import '../screens/orders/client_order_detail_screen.dart';
import 'public_shell.dart';

// Pantallas administrativas y de inventario (Tarea 5)
import '../screens/admin/compras_admin_screen.dart';
import '../screens/admin/proveedores_admin_screen.dart';
import '../screens/admin/servicios_admin_screen.dart';
import '../screens/admin/users_admin_screen.dart';
import '../screens/admin/mantenimientos_admin_screen.dart';
import '../screens/admin/repuestos_mantenimiento_admin_screen.dart';
import '../screens/admin/catalog_admin_screen.dart';
import '../screens/admin/orders_admin_screen.dart';
import '../screens/admin/order_admin_detail_screen.dart';
import '../screens/admin/ventas_admin_screen.dart';
import '../widgets/admin_shell.dart';
import '../screens/catalog/moto_detail_screen.dart';
import '../screens/catalog/moto_form_screen.dart';
import '../screens/inventory/inventory_dashboard_screen.dart';
import '../screens/inventory/movimiento_form_screen.dart';
import '../screens/inventory/repuesto_detail_screen.dart';
import '../screens/inventory/repuesto_form_screen.dart';


// ── Provider del router ───────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      if (authState.isChecking) {
        return null; // Esperar a que verifique la sesión local
      }

      final isAuthenticated = authState.isAuthenticated;
      final isStaff = authState.isStaff;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/reset-password-confirm';

      final isAdminRoute = location.startsWith('/admin') ||
          location == '/inventory' ||
          location.startsWith('/repuesto-detail') ||
          location == '/moto-form' ||
          location == '/repuesto-form' ||
          location == '/movimiento-form';

      // Si no está autenticado, forzar /login excepto para las pantallas de auth
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Si está autenticado e intenta ir a auth, redirigir según rol
      if (isAuthenticated && isAuthRoute) {
        return isStaff ? '/admin/servicios' : '/';
      }

      // Si es cliente común e intenta ir a rutas admin, redirigir a /
      if (isAuthenticated && !isStaff && isAdminRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────
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
        builder: (context, state) => const ResetPasswordConfirmScreen(),
      ),

      // ── Zona pública con BottomNavBar ────────────────────────
      ShellRoute(
        builder: (context, state, child) => PublicShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/catalog',
            builder: (context, state) => const CatalogScreen(),
            routes: [
              GoRoute(
                path: ':tipo/:id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  final tipo = state.pathParameters['tipo'] == 'moto'
                      ? ProductType.moto
                      : ProductType.repuesto;
                  return ProductDetailScreen(productId: id, tipo: tipo);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/orders',
            builder: (context, state) => const ClientOrdersScreen(),
          ),
          GoRoute(
            path: '/orders/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ClientOrderDetailScreen(orderId: id);
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Formularios privados y administración de Tarea 5 ──────────────────
      GoRoute(
        path: '/moto-detail/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return MotoDetailScreen(motoId: id);
        },
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const InventoryDashboardScreen(),
      ),
      GoRoute(
        path: '/repuesto-detail/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return RepuestoDetailScreen(repuestoId: id);
        },
      ),
      GoRoute(
        path: '/moto-form',
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          return MotoFormScreen(motoId: id > 0 ? id : null);
        },
      ),
      GoRoute(
        path: '/repuesto-form',
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '') ?? 0;
          return RepuestoFormScreen(repuestoId: id > 0 ? id : null);
        },
      ),
      GoRoute(
        path: '/movimiento-form',
        builder: (context, state) => const MovimientoFormScreen(),
      ),

      // ── Admin Shell (Panel de administración) ─────────────────
      GoRoute(
        path: '/admin',
        redirect: (context, state) => '/admin/servicios',
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => AdminShell(
          title: 'Motos y Catálogo',
          currentRoute: state.matchedLocation,
          child: const CatalogAdminScreen(),
        ),
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
        path: '/admin/orders',
        builder: (context, state) => AdminShell(
          title: 'Pedidos',
          currentRoute: state.matchedLocation,
          child: const OrdersAdminScreen(),
        ),
      ),
      GoRoute(
        path: '/admin/orders/:id',
        builder: (context, state) => AdminShell(
          title: 'Detalle pedido #${state.pathParameters['id']}',
          currentRoute: '/admin/orders',
          child: OrderAdminDetailScreen(
            orderId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/admin/ventas',
        builder: (context, state) => AdminShell(
          title: 'Ventas',
          currentRoute: state.matchedLocation,
          child: const VentasAdminScreen(),
        ),
      ),
    ],
  );
});

// ── Listenable de cambios en AuthState ───────────────────────────
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}