import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/vedic_models.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<SessionRecord> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final list = await DatabaseHelper.instance.getSessionHistory();
    if (!mounted) return;
    setState(() {
      _sessions = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Complete your first 25-question drill to see your progress graph!',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final totalPts = _sessions.fold<int>(0, (sum, s) => sum + s.score);
    final avgScore = (totalPts / _sessions.length).round();
    final spots = List.generate(
      _sessions.length,
      (i) => FlSpot(i.toDouble(), _sessions[i].score.toDouble()),
    );
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _StatCard(label: 'Sessions', value: '${_sessions.length}'),
            const SizedBox(width: 12),
            _StatCard(label: 'Total Points', value: '$totalPts'),
            const SizedBox(width: 12),
            _StatCard(label: 'Avg Score', value: '$avgScore / 250'),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score History (Points per Session)',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 240,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 260,
                      gridData: const FlGridData(
                        show: true,
                        horizontalInterval: 50,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 50,
                            getTitlesWidget: (value, meta) {
                              if (value > 250) return const SizedBox.shrink();
                              return SideTitleWidget(
                                meta: meta,
                                child: Text('${value.toInt()}'),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (value != idx ||
                                  idx < 0 ||
                                  idx >= _sessions.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text('#${idx + 1}'),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final s = _sessions[spot.x.toInt()];
                              return LineTooltipItem(
                                '${s.itemTitle}\n${s.score} pts (${s.durationSeconds}s)',
                                TextStyle(
                                  color: colors.onInverseSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          barWidth: 4,
                          color: colors.primary,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: colors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Recent Sessions',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._sessions.reversed.map((s) {
          final dateStr = DateFormat('MMM d, h:mm a').format(s.completedAt);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(s.itemTitle),
              subtitle: Text(
                '$dateStr  •  ${s.correctCount}/25 correct  •  ${s.durationSeconds}s',
              ),
              trailing: Text(
                '${s.score} pts',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
