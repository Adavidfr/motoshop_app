// lib/presentation/navigation/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/model/auth_state.dart';
import '../../domain/model/product.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_confirm_screen.dart';
import '../screens/auth/profile_screen.dart';
import '../screens/catalog/home_screen.dart';
import '../screens/catalog/catalog_screen.dart';
import '../screens/catalog/product_detail_screen.dart';
import '../screens/cart/cart_screen.dart';
import 'public_shell.dart';

// ── Placeholder para pantallas aún no implementadas ──────────────
class _PlaceholderScreen extends ConsumerWidget {
  final String title;
  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip:  'Cerrar sesión',
            icon:     const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(color: Color(0xFF8888AA), fontSize: 16),
        ),
      ),
    );
  }
}

// ── Provider del router ───────────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthStateListenable(ref),
    redirect: (context, state) {
      final auth     = ref.read(authProvider);
      final location = state.matchedLocation;

      if (auth.isChecking) return null;

      final isAuthRoute = location == '/login'   ||
                          location == '/register' ||
                          location == '/forgot-password' ||
                          location == '/reset-password-confirm';

      if (!auth.isAuthenticated && !isAuthRoute) { return '/login'; }
      if ( auth.isAuthenticated &&  isAuthRoute) {
        return auth.isStaff ? '/admin' : '/';
      }
      if ( auth.isAuthenticated && !auth.isStaff &&
           location.startsWith('/admin')) { return '/'; }

      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────────
      GoRoute(
        path:    '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path:    '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path:    '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password-confirm',
        builder: (_, __) => const ResetPasswordConfirmScreen(),
      ),

      // ── Zona pública con BottomNavBar ────────────────────────
      ShellRoute(
        builder: (_, __, child) => PublicShell(child: child),
        routes: [
          GoRoute(
            path:    '/',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path:    '/catalog',
            builder: (_, __) => const CatalogScreen(),
            routes: [
              GoRoute(
                path: ':tipo/:id',
                builder: (_, state) {
                  final id   = int.parse(state.pathParameters['id']!);
                  final tipo = state.pathParameters['tipo'] == 'moto'
                      ? ProductType.moto
                      : ProductType.repuesto;
                  return ProductDetailScreen(productId: id, tipo: tipo);
                },
              ),
            ],
          ),
          GoRoute(
            path:    '/cart',
            builder: (_, __) => const CartScreen(),
          ),
          GoRoute(
            path:    '/orders',
            builder: (_, __) => const _PlaceholderScreen('Mis pedidos — M6'),
          ),
          GoRoute(
            path:    '/orders/:id',
            builder: (_, state) =>
                _PlaceholderScreen('Pedido #${state.pathParameters['id']} — M6'),
          ),
          GoRoute(
            path:    '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Admin ────────────────────────────────────────────────
      GoRoute(
        path:    '/admin',
        builder: (_, __) => const _PlaceholderScreen('Dashboard — M8'),
      ),
      GoRoute(
        path:    '/admin/categories',
        builder: (_, __) => const _PlaceholderScreen('Categorías — M9'),
      ),
      GoRoute(
        path:    '/admin/products',
        builder: (_, __) => const _PlaceholderScreen('Productos — M10'),
      ),
      GoRoute(
        path:    '/admin/orders',
        builder: (_, __) => const _PlaceholderScreen('Pedidos admin — M11'),
      ),
      GoRoute(
        path:    '/admin/orders/:id',
        builder: (_, state) =>
            _PlaceholderScreen('Pedido admin #${state.pathParameters['id']}'),
      ),
      GoRoute(
        path:    '/admin/users',
        builder: (_, __) => const _PlaceholderScreen('Usuarios — M12'),
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
