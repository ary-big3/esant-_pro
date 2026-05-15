import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';

/// Widget pour afficher un graphique linéaire de santé
class HealthLineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color lineColor;
  final String? titre;
  final double? minY;
  final double? maxY;

  const HealthLineChart({
    super.key,
    required this.data,
    this.labels = const [],
    this.lineColor = AppColors.primary,
    this.titre,
    this.minY,
    this.maxY,
  });

  List<FlSpot> get spots {
    return data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titre != null) ...[
          Text(titre!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 20,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.surfaceVariant,
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: labels.isNotEmpty,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < labels.length && labels[index].isNotEmpty) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            labels[index],
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: minY ?? 0,
              maxY: maxY ?? (data.reduce((a, b) => a > b ? a : b) * 1.2),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: lineColor,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: lineColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Modèle de données pour le graphique en camembert
class PieChartDataModel {
  final double value;
  final String label;
  final Color color;

  const PieChartDataModel({
    required this.value,
    required this.label,
    required this.color,
  });
}

/// Widget pour afficher un graphique en camembert
class StatsPieChart extends StatelessWidget {
  final List<PieChartDataModel> data;
  final String? titre;
  final double centerRadius;

  const StatsPieChart({
    super.key,
    required this.data,
    this.titre,
    this.centerRadius = 40,
  });

  List<PieChartSectionData> get sections {
    final total = data.fold<double>(0, (sum, item) => sum + item.value);
    return data.map((item) {
      final percentage = (item.value / total * 100).round();
      return PieChartSectionData(
        color: item.color,
        value: item.value,
        title: '$percentage%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    return Column(
      children: [
        if (titre != null) ...[
          Text(titre!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: centerRadius,
                    sections: sections,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: item.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher un graphique en barres
class StatsBarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color barColor;
  final String? titre;

  const StatsBarChart({
    super.key,
    required this.data,
    required this.labels,
    this.barColor = AppColors.primary,
    this.titre,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Aucune donnée'));
    }

    final maxY = data.reduce((a, b) => a > b ? a : b) * 1.2;

    final barGroups = data.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: barColor,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (titre != null) ...[
          Text(titre!, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
        ],
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppColors.textPrimary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.round()}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < labels.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            labels[index],
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }
}
