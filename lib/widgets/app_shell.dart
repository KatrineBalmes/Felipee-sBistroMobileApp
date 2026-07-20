import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/auth/login_screen.dart';

class ShellNavItem {
  final IconData icon;
  final String label;
  final Widget page;
  const ShellNavItem({required this.icon, required this.label, required this.page});
}

/// A responsive app shell shared by the Cashier and Owner apps:
/// a side NavigationRail on wide/tablet screens, a bottom
/// NavigationBar on phones — same pages, adaptive chrome.
class AppShell extends StatefulWidget {
  final String appTitle;
  final String roleLabel;
  final String fullName;
  final String branchName;
  final List<ShellNavItem> items;
  final Color roleColor;
  const AppShell({
    super.key,
    required this.appTitle,
    required this.roleLabel,
    required this.fullName,
    required this.branchName,
    required this.items,
    this.roleColor = AppColors.accentBlue,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  bool _wide(BuildContext context) => MediaQuery.of(context).size.width >= 900;

  @override
  Widget build(BuildContext context) {
    final wide = _wide(context);

    if (wide) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Row(
          children: [
            _SideRail(
              appTitle: widget.appTitle,
              roleLabel: widget.roleLabel,
              roleColor: widget.roleColor,
              fullName: widget.fullName,
              branchName: widget.branchName,
              items: widget.items,
              index: _index,
              onSelect: (i) => setState(() => _index = i),
              onLogout: _logout,
            ),
            Expanded(
              child: SafeArea(child: widget.items[_index].page),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        // The page body already shows its own big title (e.g. "Dashboard",
        // "Inventory"), so the app bar only carries the brand + role badge
        // here instead of repeating that same title a second time.
        titleSpacing: 20,
        title: Row(
          children: [
            Text(widget.appTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.roleColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(widget.roleLabel,
                  style: TextStyle(color: widget.roleColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout, size: 20)),
        ],
      ),
      body: SafeArea(child: widget.items[_index].page),
      bottomNavigationBar: _BottomBar(
        items: widget.items,
        index: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// A horizontally-scrollable bottom bar with fixed-width, evenly padded
/// tabs — this keeps labels readable and never overflows, no matter how
/// many sections the app has or how long their names are.
class _BottomBar extends StatelessWidget {
  final List<ShellNavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  const _BottomBar({required this.items, required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 74,
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final selected = i == index;
            final item = items[i];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(i),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 96,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent.withValues(alpha: 0.14) : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.icon,
                          size: 21, color: selected ? AppColors.accent : AppColors.textSecondary),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.accent : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  final String appTitle, roleLabel, fullName, branchName;
  final Color roleColor;
  final List<ShellNavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _SideRail({
    required this.appTitle,
    required this.roleLabel,
    required this.roleColor,
    required this.fullName,
    required this.branchName,
    required this.items,
    required this.index,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      color: AppColors.bgSidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset('assets/images/logo.jpg', width: 34, height: 34),
                  ),
                  const SizedBox(height: 8),
                  Text(appTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                  const Text('BISTRO SYSTEM',
                      style: TextStyle(color: AppColors.accent2, fontSize: 10, letterSpacing: 1.2)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(roleLabel,
                    style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(indent: 16, endIndent: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final selected = i == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: selected ? AppColors.hover : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                          child: Row(
                            children: [
                              Icon(items[i].icon,
                                  size: 18, color: selected ? AppColors.accent : AppColors.textSecondary),
                              const SizedBox(width: 12),
                              Text(items[i].label,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: selected ? AppColors.accent : AppColors.textSecondary,
                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(branchName,
                      style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700)),
                  Text(fullName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout, size: 14),
                      label: const Text('Logout', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
