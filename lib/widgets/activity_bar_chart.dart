// lib/widgets/activity_bar_chart.dart
// A simple bar chart for displaying activity history

import 'package:flutter/material.dart';

class ActivityBarChart extends StatelessWidget {
  final List<double> data;
  final double height;
  final List<Color> gradientColors;
  final bool showLabels;
  final List<String>? labels;

  const ActivityBarChart({
    super.key,
    required this.data,
    this.height = 100,
    this.gradientColors = const [Color(0xFFF79D00), Color(0xFFFFD93D)],
    this.showLabels = false,
    this.labels,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minBarHeight = 4.0;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(data.length, (index) {
              final barHeight = maxValue > 0
                  ? (data[index] / maxValue * height)
                      .clamp(minBarHeight, height)
                  : minBarHeight;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: gradientColors,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        if (showLabels && labels != null && labels!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labels!.first,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                labels!.last,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A more detailed bar chart with tooltips and axis labels
class DetailedBarChart extends StatefulWidget {
  final List<BarChartData> data;
  final double height;
  final List<Color> gradientColors;
  final String? title;
  final String? unit;

  const DetailedBarChart({
    super.key,
    required this.data,
    this.height = 150,
    this.gradientColors = const [Color(0xFFF79D00), Color(0xFFFFD93D)],
    this.title,
    this.unit,
  });

  @override
  State<DetailedBarChart> createState() => _DetailedBarChartState();
}

class _DetailedBarChartState extends State<DetailedBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    final maxValue =
        widget.data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final minBarHeight = 4.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null)
            Text(
              widget.title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (_selectedIndex != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  widget.data[_selectedIndex!].label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '',
                  style: TextStyle(
                    color: widget.gradientColors.first,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: widget.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.data.length, (index) {
                final item = widget.data[index];
                final barHeight = maxValue > 0
                    ? (item.value / maxValue * widget.height)
                        .clamp(minBarHeight, widget.height)
                    : minBarHeight;

                final isSelected = _selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = _selectedIndex == index ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: isSelected
                                    ? widget.gradientColors
                                    : widget.gradientColors
                                        .map((c) => c.withValues(alpha: 0.6))
                                        .toList(),
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: widget.gradientColors.first
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.data.first.label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                widget.data.last.label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BarChartData {
  final String label;
  final double value;
  final DateTime? date;

  const BarChartData({
    required this.label,
    required this.value,
    this.date,
  });

  factory BarChartData.fromDate(DateTime date, double value) {
    return BarChartData(
      label: '/',
      value: value,
      date: date,
    );
  }
}

/// Weekly activity chart with day labels
class WeeklyActivityChart extends StatelessWidget {
  final List<double> data; // 7 values for each day
  final List<Color> gradientColors;
  final double height;

  const WeeklyActivityChart({
    super.key,
    required this.data,
    this.gradientColors = const [Color(0xFFF79D00), Color(0xFFFFD93D)],
    this.height = 100,
  });

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final paddedData = List.generate(7, (i) => i < data.length ? data[i] : 0.0);
    final maxValue = paddedData.reduce((a, b) => a > b ? a : b);
    final minBarHeight = 4.0;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (index) {
              final barHeight = maxValue > 0
                  ? (paddedData[index] / maxValue * height)
                      .clamp(minBarHeight, height)
                  : minBarHeight;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: gradientColors,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (index) {
            return Expanded(
              child: Text(
                _days[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
