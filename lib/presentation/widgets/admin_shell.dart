import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../providers/auth_provider.dart';

class AdminNavItem {
  final String label;
  final IconData icon;
  final String route;

  const AdminNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

const List<AdminNavItem> adminNavItems = [
  AdminNavItem(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    route: '/admin/dashboard',
  ),
  AdminNavItem(
    label: 'Motos y Catálogo',
    icon: Icons.two_wheeler_outlined,
    route: '/admin/products',
  ),
  AdminNavItem(
    label: 'Servicios',
    icon: Icons.build_circle_outlined,
    route: '/admin/servicios',
  ),
  AdminNavItem(
    label: 'Proveedores',
    icon: Icons.local_shipping_outlined,
    route: '/admin/proveedores',
  ),
  AdminNavItem(
    label: 'Compras',
    icon: Icons.shopping_cart_checkout_outlined,
    route: '/admin/compras',
  ),
  AdminNavItem(
    label: 'Mantenimientos',
    icon: Icons.miscellaneous_services_outlined,
    route: '/admin/mantenimientos',
  ),
  AdminNavItem(
    label: 'Repuestos usados',
    icon: Icons.settings_outlined,
    route: '/admin/repuestos-mantenimiento',
  ),
  AdminNavItem(
    label: 'Usuarios',
    icon: Icons.people_outline,
    route: '/admin/users',
  ),
  AdminNavItem(
    label: 'Pedidos',
    icon: Icons.receipt_long_outlined,
    route: '/admin/orders',
  ),
  AdminNavItem(
    label: 'Ventas',
    icon: Icons.monetization_on_outlined,
    route: '/admin/ventas',
  ),
  AdminNavItem(
    label: 'Financiamientos',
    icon: Icons.credit_card_outlined,
    route: '/admin/financiamientos',
  ),
  AdminNavItem(
    label: 'Documentos',
    icon: Icons.folder_open_outlined,
    route: '/admin/documentos-venta',
  ),
  AdminNavItem(
    label: 'Historial',
    icon: Icons.history_outlined,
    route: '/admin/historial-venta',
  ),
  AdminNavItem(
    label: 'Devoluciones',
    icon: Icons.undo_outlined,
    route: '/admin/devoluciones',
  ),
  AdminNavItem(
    label: 'Notificaciones',
    icon: Icons.notifications_none_outlined,
    route: '/admin/notificaciones',
  ),
  AdminNavItem(
    label: 'Facturas',
    icon: Icons.receipt_long_outlined,
    route: '/admin/facturas',
  ),
  AdminNavItem(
    label: 'Garantías',
    icon: Icons.shield_outlined,
    route: '/admin/garantias',
  ),
  AdminNavItem(
    label: 'Seguros',
    icon: Icons.policy_outlined,
    route: '/admin/seguros',
  ),
];

int adminSelectedIndex(String currentRoute) {
  final index = adminNavItems.indexWhere(
    (item) =>
        currentRoute == item.route ||
        currentRoute.startsWith('${item.route}/'),
  );

  return index >= 0 ? index : 0;
}

class AdminShell extends ConsumerWidget {
  final Widget child;
  final String title;
  final String currentRoute;

  const AdminShell({
    super.key,
    required this.child,
    required this.title,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text(
              '← Perfil',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: adminSelectedIndex(currentRoute),
        onDestinationSelected: (index) {
          Navigator.pop(context);

          if (index >= 0 && index < adminNavItems.length) {
            context.go(adminNavItems[index].route);
          }
        },
        children: [
          Container(
            color: AppColors.surface2,
            padding: const EdgeInsets.fromLTRB(
              20,
              48,
              20,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/logo_circular.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.username ?? 'Administrador',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                999,
                              ),
                            ),
                            child: const Text(
                              'Administrador',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Panel de administración',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...adminNavItems.map(
            (item) => NavigationDrawerDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(
                item.icon,
                color: AppColors.accent,
              ),
              label: Text(item.label),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.person_outline,
              color: AppColors.textSecondary,
            ),
            title: const Text(
              'Mi perfil',
              style: TextStyle(
                color: AppColors.textPrimary,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.go('/profile');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: AppColors.error,
            ),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              Navigator.pop(context);

              await ref.read(authProvider.notifier).logout();

              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: child,
      ),
    );
  }

  static String _getInitial(String? username) {
    final value = username?.trim() ?? '';

    if (value.isEmpty) {
      return 'A';
    }

    return value[0].toUpperCase();
  }
}