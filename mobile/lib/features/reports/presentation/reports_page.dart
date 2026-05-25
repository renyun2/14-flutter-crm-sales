import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../../shared/presentation/widgets.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  var _period = 'month';

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(reportProvider(_period));

    return Scaffold(
      appBar: AppBar(
        title: const Text('业绩报表'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _period,
            onSelected: (v) => setState(() => _period = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'month', child: Text('本月')),
              PopupMenuItem(value: 'quarter', child: Text('本季')),
            ],
          ),
        ],
      ),
      body: report.when(
        data: (data) {
          final funnel = data.funnel;
          final trend = data.trend;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('赢单金额：${formatMoney((data.kpis['wonAmount'] as num?) ?? 0)}'),
              Text('Pipeline：${formatMoney((data.kpis['pipeline'] as num?) ?? 0)}'),
              const SizedBox(height: 16),
              const Text('销售漏斗', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    barGroups: [
                      for (var i = 0; i < funnel.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: (funnel[i]['count'] as num?)?.toDouble() ?? 0,
                              color: Colors.blue,
                              width: 16,
                            ),
                          ],
                        ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= funnel.length) return const SizedBox.shrink();
                            return Text(
                              funnel[idx]['label']?.toString().substring(0, 2) ?? '',
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('业绩趋势', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < trend.length; i++)
                            FlSpot(i.toDouble(), (trend[i]['amount'] as num?)?.toDouble() ?? 0),
                        ],
                        isCurved: true,
                        color: Colors.green,
                      ),
                    ],
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= trend.length) return const SizedBox.shrink();
                            return Text(trend[idx]['label']?.toString() ?? '');
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('业绩排行', style: TextStyle(fontWeight: FontWeight.bold)),
              ...data.ranking.map(
                (r) => ListTile(
                  title: Text(r['name']?.toString() ?? ''),
                  subtitle: Text('商机 ${r['opp_count']}'),
                  trailing: Text(formatMoney((r['won_amount'] as num?) ?? 0)),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.invalidate(reportProvider(_period))),
      ),
    );
  }
}
