import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../data/db_helper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  double _todaySales = 0;
  int _todayOrders = 0;
  int _menuCount = 0;
  List<String> _lowStock = [];
  List<SaleTransaction> _recent = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  setState(() => _loading = true);

  final results = await Future.wait([
    DBHelper.instance.getTransactions(),
    DBHelper.instance.getMenuItems(),
    DBHelper.instance.getLowStockIngredientNames(),
  ]);

  final txns = results[0] as List<SaleTransaction>;
  final menu = results[1] as List<MenuItem>;
  final low = results[2] as List<String>;

  final now = DateTime.now();

  final todayStr =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final todayTxns =
      txns.where((t) => t.createdAt.startsWith(todayStr)).toList();

  if (!mounted) return;

  setState(() {
    _todaySales = todayTxns.fold(
      0.0,
      (sum, t) => sum + t.total,
    );

    _todayOrders = todayTxns.length;
    _menuCount = menu.length;
    _lowStock = low;
    _recent = txns.take(6).toList();

    _loading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    final wide = isWide(context);
    final statCards = [
      _StatCard(icon: Icons.payments, label: "Today's Sales", value: peso(_todaySales), color: AppColors.accentGreen),
      _StatCard(icon: Icons.receipt_long, label: "Today's Orders", value: '$_todayOrders', color: AppColors.accentBlue),
      _StatCard(icon: Icons.restaurant_menu, label: 'Menu Items', value: '$_menuCount', color: AppColors.accent2),
      _StatCard(icon: Icons.warning_amber, label: 'Low Stock Alerts', value: '${_lowStock.length}', color: AppColors.warning),
    ];

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          const Text('Welcome back! Here\'s how the bistro is doing today.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 18),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: wide ? 4 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: wide ? 1.3 : 1.15,
            children: statCards,
          ),
          const SizedBox(height: 20),
          if (_lowStock.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Low stock: ${_lowStock.join(', ')}',
                        style: const TextStyle(color: AppColors.warning, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (_recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No orders yet.', style: TextStyle(color: AppColors.textSecondary)),
            )
          else
            ..._recent.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BistroCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt, color: AppColors.accent2, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${t.orderType} · ${t.paymentMethod}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(t.createdAt,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(peso(t.total),
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return BistroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
