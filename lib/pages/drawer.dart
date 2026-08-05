import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Wajahat POS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Offline POS Mode',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.dashboard,
            title: 'Home',
            route: '/home',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.inventory,
            title: 'Inventory',
            route: '/inventory',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.history,
            title: 'Inventory History',
            route: '/inventory/history',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.point_of_sale,
            title: 'Sales',
            route: '/',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.receipt_long,
            title: 'Bills',
            route: '/bills',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.print_disabled,
            title: 'Pending Receipts',
            route: '/pending-receipts',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.attach_money,
            title: 'Profit',
            route: '/profit',
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings,
            title: 'Settings',
            route: '/store',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.health_and_safety,
            title: 'Database Health',
            route: '/database-health',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.history_edu,
            title: 'Audit Logs',
            route: '/audit',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
  }) {
    // Check if the current route matches to highlight it
    final String currentRoute = GoRouterState.of(context).uri.toString();
    final bool isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        size: 28,
        color: isSelected ? Colors.blue[700] : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue[700] : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue[50],
      onTap: () {
        context.go(route);
      },
    );
  }
}
