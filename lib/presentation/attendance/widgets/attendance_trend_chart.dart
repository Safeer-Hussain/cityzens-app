import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AttendanceTrendChart extends StatelessWidget {
  final double currentPercentage;

  const AttendanceTrendChart({super.key, required this.currentPercentage});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 6-week trendline data points leading to current percentage
    final spots = [
      const FlSpot(1, 86.0),
      const FlSpot(2, 88.5),
      const FlSpot(3, 85.0),
      const FlSpot(4, 89.2),
      const FlSpot(5, 90.0),
      FlSpot(6, currentPercentage),
    ];

    return SizedBox(
      width: double.infinity,
      height: 140,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: 6,
          minY: 70,
          maxY: 100,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => colors.surfaceContainerHighest,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    'W${spot.x.toInt()}: ${spot.y.toStringAsFixed(1)}%',
                    TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: colors.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
                dashArray: [4, 4],
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 10,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'W${value.toInt()}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Crucial rule: reservedSize: 0 on hidden axes so charts span edge-to-edge
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false, reservedSize: 0),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false, reservedSize: 0),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: colors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 3.5,
                    color: colors.primary,
                    strokeWidth: 2,
                    strokeColor: colors.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.primary.withValues(alpha: 0.28),
                    colors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
