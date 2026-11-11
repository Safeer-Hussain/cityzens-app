import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RetentionAnalyticsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const RetentionAnalyticsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final totalCards = (stats['totalCards'] as num?)?.toInt() ?? 0;
    final masteredCards = (stats['masteredCards'] as num?)?.toInt() ?? 0;
    final reviewingCards = (stats['reviewingCards'] as num?)?.toInt() ?? 0;
    final learningCards = (stats['learningCards'] as num?)?.toInt() ?? 0;
    final retentionRate = (stats['retentionRate'] as num?)?.toDouble() ?? 100.0;
    final avgEaseFactor = (stats['avgEaseFactor'] as num?)?.toDouble() ?? 2.5;
    final weeklyReviews =
        (stats['weeklyReviews'] as List<dynamic>?) ?? <dynamic>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.insights_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'SM-2 Retention Telemetry',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'EF Floor: 1.30',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Grid Metric Tiles
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Retention Rate',
                  value: '$retentionRate%',
                  subtext: 'q >= 3 Recall',
                  icon: Icons.check_circle_outline_rounded,
                  color: colors.secondary,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Average EF',
                  value: avgEaseFactor.toStringAsFixed(2),
                  subtext: 'Spaced Multiplier',
                  icon: Icons.trending_up_rounded,
                  color: colors.primary,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Mastered Cards',
                  value: '$masteredCards / $totalCards',
                  subtext: totalCards > 0
                      ? '${((masteredCards / totalCards) * 100).toStringAsFixed(1)}% Completed'
                      : '0%',
                  icon: Icons.stars_rounded,
                  color: colors.tertiary,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  label: 'Review Queue',
                  value: '${(stats['dueCards'] as num?)?.toInt() ?? 0}',
                  subtext: 'Due Today',
                  icon: Icons.access_time_rounded,
                  color: colors.error,
                  colors: colors,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mastery Distribution Progress Bar
          Text(
            'MASTERY LEVEL DISTRIBUTION',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              width: double.infinity,
              child: totalCards == 0
                  ? Container(color: colors.outlineVariant)
                  : Row(
                      children: [
                        if (masteredCards > 0)
                          Expanded(
                            flex: masteredCards,
                            child: Container(color: colors.secondary),
                          ),
                        if (reviewingCards > 0)
                          Expanded(
                            flex: reviewingCards,
                            child: Container(color: colors.tertiary),
                          ),
                        if (learningCards > 0)
                          Expanded(
                            flex: learningCards,
                            child: Container(color: colors.primary),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildLegendItem(
                label: 'Mastered: $masteredCards',
                color: colors.secondary,
                colors: colors,
              ),
              _buildLegendItem(
                label: 'Reviewing: $reviewingCards',
                color: colors.tertiary,
                colors: colors,
              ),
              _buildLegendItem(
                label: 'Learning: $learningCards',
                color: colors.primary,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 7-Day Review Activity Bar Chart
          Text(
            'WEEKLY RETENTION REVIEW ACTIVITY',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 8,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dayData = groupIndex < weeklyReviews.length
                          ? weeklyReviews[groupIndex] as Map<String, dynamic>
                          : null;
                      final day = dayData?['day'] ?? '';
                      return BarTooltipItem(
                        '$day: ${rod.toY.toInt()} reviews',
                        TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 0),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false, reservedSize: 0),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 9,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < weeklyReviews.length) {
                          final item =
                              weeklyReviews[index] as Map<String, dynamic>;
                          return Text(
                            item['day'] as String? ?? '',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: colors.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(weeklyReviews.length, (index) {
                  final item = weeklyReviews[index] as Map<String, dynamic>;
                  final count = (item['count'] as num?)?.toDouble() ?? 0.0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: count,
                        color: colors.primary,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 8,
                          color: colors.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required ColorScheme colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            subtext,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required String label,
    required Color color,
    required ColorScheme colors,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
