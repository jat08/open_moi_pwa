import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../data/models.dart';
import '../providers/moi_provider.dart';
import 'components.dart';

class MeasurementDetailScreen extends ConsumerWidget {
  final Measurement measurement;

  const MeasurementDetailScreen({
    super.key,
    required this.measurement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(moiProvider);
    final notifier = ref.read(moiProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cycles = measurement.cyclePeriods
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s) ?? 0.0)
        .toList();

    final trimLast = uiState.trimLastCycle;
    final avgMeasured = cycles.isNotEmpty
        ? ((trimLast && cycles.length > 1) ? cycles.sublist(0, cycles.length - 1) : cycles).reduce((a, b) => a + b) /
            ((trimLast && cycles.length > 1) ? cycles.length - 1 : cycles.length)
        : measurement.period;

    String displayType = 'Paddle/Racquet';
    if (measurement.type == 'OBJECT_A' || measurement.type == 'OBJECT_B') {
      displayType = 'Calibration Object';
    } else if (measurement.type == 'TARE_PB' || measurement.type == 'TARE_TW') {
      displayType = 'Tare Adapter';
    }

    final swTwLabel = measurement.type == 'PADDLE'
        ? (measurement.moi >= 40 ? ' (SW)' : ' (TW)')
        : '';

    final finalMoiValue = measurement.type == 'OBJECT_A'
        ? uiState.knownObjectAInertia
        : measurement.type == 'OBJECT_B'
            ? uiState.knownObjectBInertia
            : measurement.moi;

    final finalMoiText = measurement.type == 'OBJECT_A'
        ? uiState.knownObjectAInertia.toStringAsFixed(2)
        : measurement.type == 'OBJECT_B'
            ? uiState.knownObjectBInertia.toStringAsFixed(2)
            : measurement.moi.toStringAsFixed(uiState.moiUnitsResolution);

    final periodText = '${avgMeasured.toStringAsFixed(uiState.periodUnitsResolution)}s';

    final timeStr = DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(measurement.timestamp));
    final dateStr = DateFormat('M/d/yy').format(DateTime.fromMillisecondsSinceEpoch(measurement.timestamp));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        notifier.selectMeasurement(null);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface, size: 28),
                      onPressed: () => notifier.selectMeasurement(null),
                    ),
                    Text(
                      'Measurement Data',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          color: theme.colorScheme.surfaceVariant,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: InfoBit(label: 'Type', value: '$displayType$swTwLabel'),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: InfoBit(label: 'Tare', value: measurement.tareMode),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: InfoBit(
                                        label: 'MOI',
                                        value: finalMoiText,
                                        onLongClick: () {
                                          Clipboard.setData(ClipboardData(text: finalMoiValue.toStringAsFixed(uiState.moiUnitsResolution)));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Copied MOI: ${finalMoiValue.toStringAsFixed(uiState.moiUnitsResolution)}')),
                                          );
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: InfoBit(
                                        label: 'Period',
                                        value: periodText,
                                        onLongClick: () {
                                          Clipboard.setData(ClipboardData(text: avgMeasured.toStringAsFixed(uiState.periodUnitsResolution)));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Copied Period: ${avgMeasured.toStringAsFixed(uiState.periodUnitsResolution)}')),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: InfoBit(label: 'Time', value: timeStr),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: InfoBit(label: 'Date', value: dateStr),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Text(
                          'Oscillation Graph',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),

                        const SizedBox(height: 8),

                        OscillationGraph(measurement: measurement),

                        const SizedBox(height: 24),

                        Text(
                          'Cycle Analysis',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),

                        const SizedBox(height: 8),

                        if (cycles.isNotEmpty) ...[
                          Builder(builder: (context) {
                            final refIndex = uiState.cycleReference;
                            final refValue = (refIndex > 0 && refIndex <= cycles.length)
                                ? cycles[refIndex - 1]
                                : ((trimLast && cycles.length > 1) ? cycles.sublist(0, cycles.length - 1) : cycles).reduce((a, b) => a + b) /
                                    ((trimLast && cycles.length > 1) ? cycles.length - 1 : cycles.length);

                            final isTW = measurement.type == 'TARE_PB' ||
                                measurement.type == 'TARE_TW' ||
                                (measurement.type == 'PADDLE' && measurement.moi < 40);

                            final margin = isTW ? uiState.twMargin : uiState.swMargin;

                            return Column(
                              children: cycles.asMap().entries.map((entry) {
                                final index = entry.key;
                                final period = entry.value;
                                final isRef = refIndex == (index + 1);
                                final isTrimmed = trimLast && index == (cycles.length - 1);
                                final diff = (period - refValue).abs() / refValue;
                                final isExcluded = !isTrimmed && (diff > margin);

                                Color periodColor = theme.colorScheme.onSurface;
                                if (isTrimmed) periodColor = isDark ? AppColors.errorTextDark : AppColors.errorTextLight;
                                else if (isExcluded) periodColor = theme.colorScheme.outline;

                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Cycle #${index + 1}',
                                                style: TextStyle(color: periodColor, fontWeight: isRef ? FontWeight.bold : FontWeight.normal),
                                              ),
                                              if (isRef) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: theme.colorScheme.primary.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'REFERENCE',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                                  ),
                                                ),
                                              ],
                                              if (isTrimmed) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'TRIMMED',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.errorTextDark : AppColors.errorTextLight),
                                                  ),
                                                ),
                                              ] else if (isExcluded) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withOpacity(0.25),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'DEVIATION',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? AppColors.warningTextDark : AppColors.warningTextLight),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          GestureDetector(
                                            onLongPress: () {
                                              Clipboard.setData(ClipboardData(text: period.toStringAsFixed(uiState.periodUnitsResolution)));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Copied: ${period.toStringAsFixed(uiState.periodUnitsResolution)}s')),
                                              );
                                            },
                                            child: Text(
                                              '${period.toStringAsFixed(uiState.periodUnitsResolution)}s',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: periodColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                                  ],
                                );
                              }).toList(),
                            );
                          }),
                        ],

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoBit extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onLongClick;

  const InfoBit({
    super.key,
    required this.label,
    required this.value,
    this.onLongClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: onLongClick,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.outline)),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}

class OscillationGraph extends StatelessWidget {
  final Measurement measurement;

  const OscillationGraph({
    super.key,
    required this.measurement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawData = measurement.rawData
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s) ?? 0.0)
        .toList();

    if (rawData.isEmpty || measurement.totalDuration <= 0) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('No graph data available', style: TextStyle(color: theme.colorScheme.outline)),
      );
    }

    final maxAmp = rawData.map((d) => d.abs()).reduce(max);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, left: 8, right: 8, bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CustomPaint(
              painter: WaveformPainter(
                rawData: rawData,
                maxAmp: maxAmp,
                totalDuration: measurement.totalDuration,
                period: measurement.period,
                primaryColor: theme.colorScheme.primary,
                secondaryColor: theme.colorScheme.secondary,
                axisColor: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(label: 'Physical Measurement', color: theme.colorScheme.primary, isDashed: false),
              const SizedBox(width: 24),
              _LegendItem(label: 'Theoretical Fit', color: theme.colorScheme.secondary, isDashed: true),
            ],
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> rawData;
  final double maxAmp;
  final double totalDuration;
  final double period;
  final Color primaryColor;
  final Color secondaryColor;
  final Color axisColor;

  WaveformPainter({
    required this.rawData,
    required this.maxAmp,
    required this.totalDuration,
    required this.period,
    required this.primaryColor,
    required this.secondaryColor,
    required this.axisColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    final pixelsPerSecond = width / totalDuration;

    // Grid lines
    double t = 0.0;
    while (t <= totalDuration + 0.001) {
      final xMark = t * pixelsPerSecond;
      final isFullSecond = (t % 1.0).abs() < 0.01;

      if (isFullSecond) {
        final linePaint = Paint()
          ..color = axisColor.withOpacity(0.4)
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(xMark, 0), Offset(xMark, height), linePaint);

        // Time label
        final tp = TextPainter(
          text: TextSpan(
            text: '${t.toInt()}s',
            style: TextStyle(fontSize: 11, color: axisColor, fontWeight: FontWeight.bold),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(xMark - tp.width / 2, height + 4));
      }
      t += 0.25;
    }

    // Center axis
    final centerPaint = Paint()
      ..color = axisColor.withOpacity(0.5)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(0, centerY), Offset(width, centerY), centerPaint);

    final step = width / max(1, rawData.length - 1);

    // Theoretical Sine Wave (Dashed)
    if (period > 0) {
      final theoreticalPaint = Paint()
        ..color = secondaryColor.withOpacity(0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final initialPhase = (rawData.length > 1 && rawData[1] < rawData[0]) ? pi : 0.0;
      final path = Path();
      for (var i = 0; i < rawData.length; i++) {
        final time = (i / max(1, rawData.length - 1)) * totalDuration;
        final amp = maxAmp * sin(2.0 * pi * time / period + initialPhase);
        final x = i * step;
        final y = centerY - (amp / (maxAmp == 0 ? 1 : maxAmp)) * (height / 2.2);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Draw dashed path
      final dashWidth = 8;
      final dashSpace = 8;
      double distance = 0.0;
      for (var pathMetric in path.computeMetrics()) {
        while (distance < pathMetric.length) {
          canvas.drawPath(
            pathMetric.extractPath(distance, distance + dashWidth),
            theoreticalPaint,
          );
          distance += dashWidth + dashSpace;
        }
      }
    }

    // Actual Measurement Waveform
    final actualPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final actualPath = Path();
    for (var i = 0; i < rawData.length; i++) {
      final x = i * step;
      final y = centerY - (rawData[i] / (maxAmp == 0 ? 1 : maxAmp)) * (height / 2.2);
      if (i == 0) {
        actualPath.moveTo(x, y);
      } else {
        actualPath.lineTo(x, y);
      }
    }
    canvas.drawPath(actualPath, actualPaint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDashed;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.isDashed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CustomPaint(
          size: const Size(20, 2),
          painter: _LineLegendPainter(color: color, isDashed: isDashed),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
        ),
      ],
    );
  }
}

class _LineLegendPainter extends CustomPainter {
  final Color color;
  final bool isDashed;

  _LineLegendPainter({required this.color, required this.isDashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    if (!isDashed) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    } else {
      canvas.drawLine(Offset(0, size.height / 2), Offset(6, size.height / 2), paint);
      canvas.drawLine(Offset(10, size.height / 2), Offset(16, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
