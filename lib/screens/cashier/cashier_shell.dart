import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../shared/pos_page.dart';
import '../shared/inventory_page.dart';

class CashierShell extends StatelessWidget {
  final String fullName;
  final String branchName;
  const CashierShell({super.key, required this.fullName, required this.branchName});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      appTitle: "Filipee's",
      roleLabel: '🧾 CASHIER',
      roleColor: AppColors.accentBlue,
      fullName: fullName,
      branchName: branchName,
      items: const [
        ShellNavItem(icon: Icons.point_of_sale, label: 'Point of Sale', page: PosPage()),
        ShellNavItem(icon: Icons.inventory_2_outlined, label: 'Inventory', page: InventoryPage(canEdit: false)),
      ],
    );
  }
}
