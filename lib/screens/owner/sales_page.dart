import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../data/db_helper.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  bool _loading = true;
  List<SaleTransaction> _txns = [];
  List<MapEntry<String, double>> _daily = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txns = await DBHelper.instance.getTransactions();
    final Map<String, double> byDay = {};
    for (final t in txns) {
      final day = t.createdAt.substring(5, 10); // MM-DD
      byDay[day] = (byDay[day] ?? 0) + t.total;
    }
    final sortedDays = byDay.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final last14 = sortedDays.length > 14 ? sortedDays.sublist(sortedDays.length - 14) : sortedDays;

    if (!mounted) return;
    setState(() {
      _txns = txns;
      _daily = last14;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    final totalSales = _txns.fold<double>(0, (s, t) => s + t.total);
    final avgOrder = _txns.isEmpty ? 0 : totalSales / _txns.length;
    final maxY = _daily.isEmpty ? 100.0 : (_daily.map((e) => e.value).reduce((a, b) => a > b ? a : b)) * 1.25;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Sales Monitor', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
        const SizedBox(height: 4),
        const Text('Track daily performance across all recorded transactions.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _MiniStat(label: 'Total Sales', value: peso(totalSales))),
            const SizedBox(width: 12),
            Expanded(child: _MiniStat(label: 'Total Orders', value: '${_txns.length}')),
            const SizedBox(width: 12),
            Expanded(child: _MiniStat(label: 'Avg. Order', value: peso(avgOrder))),
          ],
        ),
        const SizedBox(height: 20),
        BistroCard(
          padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 12),
                child: Text('Daily Sales Trend', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              SizedBox(
                height: 220,
                child: _daily.isEmpty
                    ? const Center(
                        child: Text('No sales data yet.', style: TextStyle(color: AppColors.textSecondary)))
                    : BarChart(
                        BarChartData(
                          maxY: maxY,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 26,
                                getTitlesWidget: (v, meta) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= _daily.length) return const SizedBox();
                                  // Only show every Nth label so dates never
                                  // crowd into each other, however many bars
                                  // there are — and shorten "07-19" to "7/19"
                                  // so each label takes less horizontal room.
                                  const maxLabels = 6;
                                  final step = (_daily.length / maxLabels).ceil().clamp(1, 999);
                                  final isFirst = i == 0;
                                  final isLast = i == _daily.length - 1;
                                  if (!isFirst && !isLast && i % step != 0) return const SizedBox();
                                  final bits = _daily[i].key.split('-');
                                  final short = '${int.parse(bits[0])}/${int.parse(bits[1])}';
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(short,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5)),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups: [
                            for (int i = 0; i < _daily.length; i++)
                              BarChartGroupData(x: i, barRods: [
                                BarChartRodData(
                                  toY: _daily[i].value,
                                  width: 14,
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: AppColors.gradient,
                                ),
                              ]),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Transaction History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ..._txns.take(30).map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BistroCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${t.orderType} · ${t.paymentMethod}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          Text(formatOrderTimestamp(t.createdAt),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        t.items.map((i) => '${i.name} x${i.qty}').join(', '),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(peso(t.total), style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return BistroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(color: AppColors.accent, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
