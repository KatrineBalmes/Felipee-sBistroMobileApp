import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../shared/pos_page.dart';
import '../shared/inventory_page.dart';
import 'dashboard_page.dart';
import 'sales_page.dart';
import 'forecast_page.dart';
import 'users_page.dart';

class OwnerShell extends StatelessWidget {
  final String fullName;
  final String branchName;

  const OwnerShell({
    super.key,
    required this.fullName,
    required this.branchName,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appTitle: "Filipee's",
      roleLabel: '👑 OWNER',
      roleColor: AppColors.accent2,
      fullName: fullName,
      branchName: branchName,
      items: const [
        ShellNavItem(
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
          page: DashboardPage(),
        ),
        ShellNavItem(
          icon: Icons.point_of_sale,
          label: 'Point of Sale',
          page: PosPage(),
        ),
        ShellNavItem(
          icon: Icons.inventory_2_outlined,
          label: 'Inventory',
          page: InventoryPage(canEdit: true),
        ),
        ShellNavItem(
          icon: Icons.show_chart,
          label: 'Sales Monitor',
          page: SalesPage(),
        ),
        ShellNavItem(
          icon: Icons.auto_awesome,
          label: 'AI Forecast',
          page: ForecastPage(),
        ),
        ShellNavItem(
          icon: Icons.people_outline,
          label: 'Users',
          page: UsersPage(),
        ),
      ],
    );
  }
}