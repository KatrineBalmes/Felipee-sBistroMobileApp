import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../data/db_helper.dart';

enum Trend { increasing, stable, decreasing }

class ForecastEntry {
  final String itemName;
  final double recentAvg; // last 7 days moving average (qty/day)
  final double previousAvg; // prior 7 days moving average
  final Trend trend;
  final String recommendation;

  ForecastEntry({
    required this.itemName,
    required this.recentAvg,
    required this.previousAvg,
    required this.trend,
    required this.recommendation,
  });
}

/// Implements the rule-based demand engine described in the project
/// proposal: compute 7-day moving averages per menu item, then classify
/// the trend as Increasing / Stable / Decreasing using a threshold rule,
/// and surface a simple procurement recommendation.
class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  bool _loading = true;
  List<ForecastEntry> _entries = [];

  static const double _thresholdPct = 0.10; // 10% swing = trend, per proposal's rule-based approach

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txns = await DBHelper.instance.getTransactions();

    // Build: itemName -> date(yyyy-mm-dd) -> qty sold
    final Map<String, Map<String, int>> perItemPerDay = {};
    for (final t in txns) {
      final date = t.createdAt.substring(0, 10);
      for (final item in t.items) {
        perItemPerDay.putIfAbsent(item.name, () => {});
        perItemPerDay[item.name]![date] = (perItemPerDay[item.name]![date] ?? 0) + item.qty;
      }
    }

    final now = DateTime.now();
    List<String> lastNDays(int n, int offset) => List.generate(n, (i) {
          final d = now.subtract(Duration(days: offset + i));
          return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        });

    final recentWindow = lastNDays(7, 0);
    final previousWindow = lastNDays(7, 7);

    final entries = <ForecastEntry>[];
    perItemPerDay.forEach((name, byDate) {
      final recentTotal = recentWindow.fold<int>(0, (s, d) => s + (byDate[d] ?? 0));
      final previousTotal = previousWindow.fold<int>(0, (s, d) => s + (byDate[d] ?? 0));
      final recentAvg = recentTotal / 7;
      final previousAvg = previousTotal / 7;

      Trend trend;
      String rec;
      if (previousAvg == 0) {
        trend = recentAvg > 0 ? Trend.increasing : Trend.stable;
      } else {
        final change = (recentAvg - previousAvg) / previousAvg;
        if (change > _thresholdPct) {
          trend = Trend.increasing;
        } else if (change < -_thresholdPct) {
          trend = Trend.decreasing;
        } else {
          trend = Trend.stable;
        }
      }

      switch (trend) {
        case Trend.increasing:
          rec = 'Demand is rising — increase prep quantity and check ingredient stock.';
          break;
        case Trend.decreasing:
          rec = 'Demand is slowing — reduce next batch size to avoid spoilage.';
          break;
        case Trend.stable:
          rec = 'Demand is steady — maintain current prep quantity.';
          break;
      }

      entries.add(ForecastEntry(
        itemName: name,
        recentAvg: recentAvg,
        previousAvg: previousAvg,
        trend: trend,
        recommendation: rec,
      ));
    });

    entries.sort((a, b) => b.recentAvg.compareTo(a.recentAvg));

    if (!mounted) return;
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    final anomalies = _entries.where((e) => e.trend == Trend.decreasing && e.recentAvg < 5).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.accent2, size: 20),
            const SizedBox(width: 8),
            Text('AI Forecast', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Rule-based demand engine: 7-day moving average per item, classified as '
          'Increasing / Stable / Decreasing (±10% threshold).',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 18),
        if (anomalies.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.report_problem, color: AppColors.accentRed, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sales anomaly detected: ${anomalies.map((a) => a.itemName).join(', ')} '
                    'showing unusually low demand.',
                    style: const TextStyle(color: AppColors.accentRed, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        if (_entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text('Not enough sales data yet to generate a forecast.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          ..._entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ForecastCard(entry: e),
              )),
      ],
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final ForecastEntry entry;
  const _ForecastCard({required this.entry});

  Color get _color {
    switch (entry.trend) {
      case Trend.increasing:
        return AppColors.accentGreen;
      case Trend.decreasing:
        return AppColors.accentRed;
      case Trend.stable:
        return AppColors.accentBlue;
    }
  }

  IconData get _icon {
    switch (entry.trend) {
      case Trend.increasing:
        return Icons.trending_up;
      case Trend.decreasing:
        return Icons.trending_down;
      case Trend.stable:
        return Icons.trending_flat;
    }
  }

  String get _label {
    switch (entry.trend) {
      case Trend.increasing:
        return 'Increasing';
      case Trend.decreasing:
        return 'Decreasing';
      case Trend.stable:
        return 'Stable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BistroCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
            child: Icon(_icon, color: _color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(entry.itemName,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: _color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                      child: Text(_label,
                          style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '7-day avg: ${entry.recentAvg.toStringAsFixed(1)}/day  '
                  '(prev: ${entry.previousAvg.toStringAsFixed(1)}/day)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                ),
                const SizedBox(height: 6),
                Text(entry.recommendation, style: const TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
