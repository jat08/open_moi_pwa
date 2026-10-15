import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../data/models.dart';
import '../logic/oscillation_detector.dart';
import '../providers/moi_provider.dart';

class DynamicTitleText extends StatelessWidget {
  final String text;
  final double maxFontSize;
  final FontWeight fontWeight;
  final Color color;

  const DynamicTitleText({
    super.key,
    required this.text,
    this.maxFontSize = 20,
    this.fontWeight = FontWeight.bold,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = maxFontSize;
        final style = TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );

        TextPainter textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: Directionality.maybeOf(context) ?? ui.TextDirection.ltr,
        )..layout();

        while ((textPainter.didExceedMaxLines || textPainter.width > constraints.maxWidth) && fontSize > 11) {
          fontSize -= 0.5;
          textPainter = TextPainter(
            text: TextSpan(
              text: text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: color,
              ),
            ),
            maxLines: 1,
            textDirection: Directionality.maybeOf(context) ?? ui.TextDirection.ltr,
          )..layout();
        }

        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
          ),
        );
      },
    );
  }
}

class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String text;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.text,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
      content: Text(text, style: TextStyle(color: theme.colorScheme.onSurface)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class RenameDialog extends StatefulWidget {
  final String currentName;
  final ValueChanged<String> onConfirm;

  const RenameDialog({
    super.key,
    required this.currentName,
    required this.onConfirm,
  });

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Rename'),
      content: TextField(
        controller: _controller,
        maxLength: 40,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Name'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              widget.onConfirm(text);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class SelectionTopBar extends StatelessWidget {
  final int count;
  final bool isAllSelected;
  final VoidCallback onToggleAll;
  final VoidCallback onClear;
  final VoidCallback onDelete;

  const SelectionTopBar({
    super.key,
    required this.count,
    required this.isAllSelected,
    required this.onToggleAll,
    required this.onClear,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClear,
          ),
          Text(
            '$count Selected',
            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
          ),
          const Spacer(),
          TextButton(
            onPressed: onToggleAll,
            child: Text(isAllSelected ? 'Deselect All' : 'Select All'),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class MeasurementItem extends StatelessWidget {
  final Measurement measurement;
  final VoidCallback onDelete;
  final VoidCallback onClick;
  final VoidCallback onLongClick;
  final bool selected;
  final int resolution;
  final int periodResolution;
  final double averageVal;
  final int index;
  final bool showType;
  final bool isPeriod;
  final double fitThreshold;
  final double margin;
  final bool trimLast;

  const MeasurementItem({
    super.key,
    required this.measurement,
    required this.onDelete,
    required this.onClick,
    required this.onLongClick,
    this.selected = false,
    this.resolution = 1,
    this.periodResolution = 4,
    this.averageVal = 0.0,
    this.index = 0,
    this.showType = true,
    this.isPeriod = false,
    this.fitThreshold = 1.0,
    this.margin = 0.07,
    this.trimLast = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cycles = measurement.cyclePeriods
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s) ?? 0.0)
        .toList();

    double avgMeasured = measurement.period;
    if (cycles.isNotEmpty) {
      if (trimLast && cycles.length > 1) {
        avgMeasured = cycles.sublist(0, cycles.length - 1).reduce((a, b) => a + b) / (cycles.length - 1);
      } else {
        avgMeasured = cycles.reduce((a, b) => a + b) / cycles.length;
      }
    }

    final value = isPeriod ? avgMeasured : measurement.moi;
    final diff = averageVal > 0 ? (value - averageVal).abs() / averageVal : 0.0;
    final isOutlier = averageVal > 0 && diff > margin;

    final containerColor = selected
        ? theme.colorScheme.primaryContainer
        : AppColors.getCardBackgroundColor(
            context: context,
            isSelected: selected,
            isError: measurement.fitResidual >= fitThreshold,
            isOutlier: isOutlier,
          );

    final valueText = isPeriod
        ? '${avgMeasured.toStringAsFixed(periodResolution)}s'
        : '${value.toStringAsFixed(resolution)} kg·cm²';

    final typeMarking = measurement.moi >= 40 ? 'SW' : 'TW';

    final timeStr = DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(measurement.timestamp));
    final dateStr = DateFormat('M/d/yy').format(DateTime.fromMillisecondsSinceEpoch(measurement.timestamp));

    final valueColor = measurement.fitResidual >= fitThreshold
        ? (isDark ? AppColors.errorTextDark : AppColors.errorTextLight)
        : theme.colorScheme.onSurface;

    return Card(
      elevation: 0,
      color: containerColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      child: InkWell(
        onTap: onClick,
        onLongPress: onLongClick,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '#$index',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                ),
              ),
              if (showType && !isPeriod) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: measurement.moi >= 40 ? theme.colorScheme.primary : theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    typeMarking,
                    style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      valueText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: valueColor,
                        height: 1.1,
                      ),
                    ),
                    if (!isPeriod) ...[
                      Text(
                        'Period: ${avgMeasured.toStringAsFixed(periodResolution)}s',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.outline, height: 1.1),
                      ),
                      Text(
                        'Tare: ${measurement.tareMode}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.outline, height: 1.1),
                      ),
                    ],
                    Text(
                      'Fit Residual: ${measurement.fitResidual.toStringAsFixed(3)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: measurement.fitResidual >= fitThreshold
                            ? (isDark ? AppColors.errorTextDark : AppColors.errorTextLight)
                            : theme.colorScheme.outline,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeStr, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline, height: 1.1)),
                  Text(dateStr, style: TextStyle(fontSize: 11, color: theme.colorScheme.outline, height: 1.1)),
                ],
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => DeleteConfirmationDialog(
                      title: 'Delete Measurement?',
                      text: 'Are you sure you want to delete measurement #$index?',
                      onConfirm: onDelete,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(Icons.delete, size: 24, color: theme.colorScheme.outline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MeasurementControlButton extends StatelessWidget {
  final OscillationState state;
  final double progress;
  final bool isCalibrated;
  final double cooldownRemaining;
  final int preparationRemaining;
  final VoidCallback onStart;

  const MeasurementControlButton({
    super.key,
    required this.state,
    required this.progress,
    this.isCalibrated = true,
    this.cooldownRemaining = 0.0,
    this.preparationRemaining = 0,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content;

    if (!isCalibrated) {
      content = Consumer(
        builder: (context, ref, child) => InkWell(
          onTap: () {
            ref.read(moiProvider.notifier).navigateToCalibrate();
          },
          child: Container(
            color: theme.colorScheme.errorContainer,
            alignment: Alignment.center,
            child: Text(
              'Calibrate Device First',
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      );
    } else if (state == OscillationState.WRONG_ORIENTATION) {
      content = Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.center,
        child: Text(
          'Hold Phone at 45°',
          style: TextStyle(
            color: theme.colorScheme.onErrorContainer,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );
    } else if (preparationRemaining > 0) {
      content = Container(
        color: Colors.grey,
        alignment: Alignment.center,
        child: Text(
          'Waiting $preparationRemaining Seconds to be Ready',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    } else if (cooldownRemaining > 0) {
      content = Container(
        color: Colors.grey,
        alignment: Alignment.center,
        child: Text(
          'Waiting ${cooldownRemaining.toInt()} seconds',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      );
    } else {
      switch (state) {
        case OscillationState.READY:
          content = ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Start Measurement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          );
          break;
        case OscillationState.ARMED:
          content = Container(
            color: theme.colorScheme.primary.withOpacity(0.2),
            alignment: Alignment.center,
            child: Text(
              'Ready - Waiting for Oscillations',
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          );
          break;
        case OscillationState.SETTLING:
        case OscillationState.ACTIVE_COUNTING:
          final label = state == OscillationState.SETTLING ? 'Settling...' : 'Measuring...';
          final pct = (progress * 100).toInt().clamp(0, 100);
          content = Stack(
            children: [
              Container(color: theme.colorScheme.primary.withOpacity(0.15)),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(color: theme.colorScheme.primary.withOpacity(0.35)),
              ),
              Center(
                child: Text(
                  '$label $pct%',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ),
            ],
          );
          break;
        default:
          content = const SizedBox.shrink();
      }
    }

    return Container(
      height: 48,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: content,
    );
  }
}

class SummaryHeaderLarge extends StatelessWidget {
  final double avgSW;
  final double stdDevSW;
  final double avgTW;
  final double stdDevTW;
  final double avgPeriodSW;
  final double stdDevPeriodSW;
  final double avgPeriodTW;
  final double stdDevPeriodTW;
  final int moiResolution;
  final int periodResolution;
  final double? calculatedBP;
  final double? stdDevBP;

  const SummaryHeaderLarge({
    super.key,
    required this.avgSW,
    required this.stdDevSW,
    required this.avgTW,
    required this.stdDevTW,
    required this.avgPeriodSW,
    required this.stdDevPeriodSW,
    required this.avgPeriodTW,
    required this.stdDevPeriodTW,
    required this.moiResolution,
    this.periodResolution = 4,
    this.calculatedBP,
    this.stdDevBP,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSW = avgSW > 0;
    final swVal = hasSW ? avgSW.toStringAsFixed(moiResolution) : 'No Data';
    final swTol = hasSW ? '± ${stdDevSW.toStringAsFixed(moiResolution)} kg·cm²' : '';

    final hasTW = avgTW > 0;
    final twVal = hasTW ? avgTW.toStringAsFixed(moiResolution) : 'No Data';
    final twTol = hasTW ? '± ${stdDevTW.toStringAsFixed(moiResolution)} kg·cm²' : '';

    final periodSWText = avgPeriodSW > 0 ? 'Period: ${avgPeriodSW.toStringAsFixed(periodResolution)}s' : 'Period: No Data';
    final periodTWText = avgPeriodTW > 0 ? 'Period: ${avgPeriodTW.toStringAsFixed(periodResolution)}s' : 'Period: No Data';

    String? bpVal;
    String? bpTol;
    if (calculatedBP != null && calculatedBP! > 0) {
      bpVal = calculatedBP!.toStringAsFixed(moiResolution);
      bpTol = (stdDevBP != null && stdDevBP! > 0) ? '± ${stdDevBP!.toStringAsFixed(moiResolution)} cm' : 'cm';
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Swing Weight', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: avgSW.toStringAsFixed(moiResolution)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied SW: ${avgSW.toStringAsFixed(moiResolution)}')),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(swVal, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, height: 1.1)),
                            if (hasSW) ...[
                              const SizedBox(height: 4),
                              Text(swTol, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.colorScheme.primary.withOpacity(0.85), height: 1.1)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onLongPress: () {
                          if (hasSW) {
                            Clipboard.setData(ClipboardData(text: avgPeriodSW.toStringAsFixed(periodResolution)));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied Period SW: ${avgPeriodSW.toStringAsFixed(periodResolution)}')),
                            );
                          }
                        },
                        child: Text(
                          periodSWText,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.outline, height: 1.1),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 110,
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Twist Weight', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: avgTW.toStringAsFixed(moiResolution)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied TW: ${avgTW.toStringAsFixed(moiResolution)}')),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(twVal, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, height: 1.1)),
                            if (hasTW) ...[
                              const SizedBox(height: 4),
                              Text(twTol, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary.withOpacity(0.85), height: 1.1)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onLongPress: () {
                          if (hasTW) {
                            Clipboard.setData(ClipboardData(text: avgPeriodTW.toStringAsFixed(periodResolution)));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied Period TW: ${avgPeriodTW.toStringAsFixed(periodResolution)}')),
                            );
                          }
                        },
                        child: Text(
                          periodTWText,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.outline, height: 1.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (bpVal != null) ...[
              Divider(height: 20, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: calculatedBP!.toStringAsFixed(moiResolution)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied BP: ${calculatedBP!.toStringAsFixed(moiResolution)}')),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Balance Point: ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.outline)),
                    Text(bpVal, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    if (bpTol != null) ...[
                      const SizedBox(width: 4),
                      Text(bpTol, style: TextStyle(fontSize: 15, color: theme.colorScheme.outline)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SingleSummaryHeader extends StatelessWidget {
  final String label;
  final double avg;
  final double stdDev;
  final int moiResolution;
  final int periodResolution;
  final bool isPeriod;
  final String? label2;
  final double avg2;
  final double stdDev2;
  final bool showTolerance;
  final bool inlineToleranceWithUnits;
  final String? expectedNote;

  const SingleSummaryHeader({
    super.key,
    required this.label,
    required this.avg,
    required this.stdDev,
    required this.moiResolution,
    this.periodResolution = 4,
    this.isPeriod = false,
    this.label2,
    this.avg2 = 0.0,
    this.stdDev2 = 0.0,
    this.showTolerance = true,
    this.inlineToleranceWithUnits = false,
    this.expectedNote,
    this.onInfoClick,
  });

  final VoidCallback? onInfoClick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = isPeriod ? periodResolution : moiResolution;
    final unit1 = isPeriod ? 's' : 'kg·cm²';

    final fullLabel1 = label == 'SW' ? 'Swing Weight' : (label == 'TW' ? 'Twist Weight' : label);
    final fullLabel2 = label2 == 'SW' ? 'Swing Weight' : (label2 == 'TW' ? 'Twist Weight' : label2);

    final hasVal1 = avg > 0;
    final val1 = hasVal1 ? avg.toStringAsFixed(res) : 'No Data';
    final tol1 = hasVal1 && showTolerance ? '± ${stdDev.toStringAsFixed(res)} $unit1' : (hasVal1 ? unit1 : '');

    final hasVal2 = avg2 > 0;
    final val2 = hasVal2 ? avg2.toStringAsFixed(moiResolution) : 'No Data';
    final tol2 = hasVal2 && showTolerance ? '± ${stdDev2.toStringAsFixed(moiResolution)} kg·cm²' : (hasVal2 ? 'kg·cm²' : '');

    final inlineVal1 = hasVal1
        ? (showTolerance
            ? '$val1 ± ${stdDev.toStringAsFixed(res)} $unit1'
            : '$val1 $unit1')
        : 'No Data';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullLabel1, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text: val1));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied $fullLabel1: $val1')),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inlineToleranceWithUnits ? inlineVal1 : val1,
                              style: TextStyle(
                                fontSize: inlineToleranceWithUnits ? 24 : 36,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                height: 1.1,
                              ),
                            ),
                            if (!inlineToleranceWithUnits && hasVal1) ...[
                              const SizedBox(height: 4),
                              Text(tol1, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.colorScheme.primary.withOpacity(0.85), height: 1.1)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (fullLabel2 != null) ...[
                  Container(
                    width: 1,
                    height: 80,
                    color: theme.colorScheme.outline.withOpacity(0.3),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullLabel2!, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onLongPress: () {
                            Clipboard.setData(ClipboardData(text: val2));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Copied $fullLabel2: $val2')),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(val2, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, height: 1.1)),
                              if (hasVal2) ...[
                                const SizedBox(height: 4),
                                Text(tol2, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary.withOpacity(0.85), height: 1.1)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (expectedNote != null && expectedNote!.isNotEmpty) ...[
              Divider(height: 20, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      expectedNote!,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
                    ),
                  ),
                  if (onInfoClick != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onInfoClick,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'i',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EstimationInputField extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final List<String> units;
  final ValueChanged<String> onValueChange;
  final ValueChanged<String> onUnitChange;
  final bool locked;
  final double inputWidth;
  final double unitWidth;

  const EstimationInputField({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.units,
    required this.onValueChange,
    required this.onUnitChange,
    this.locked = false,
    this.inputWidth = 100,
    this.unitWidth = 70,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              SizedBox(
                width: inputWidth,
                height: 38,
                child: TextField(
                  controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
                  enabled: !locked,
                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.end,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    prefixIcon: locked ? Icon(Icons.lock, size: 18, color: theme.colorScheme.outline) : null,
                    prefixIconConstraints: locked ? const BoxConstraints(minWidth: 32, minHeight: 0) : null,
                  ),
                  onChanged: onValueChange,
                ),
              ),
              const SizedBox(width: 8),
              UnitPicklist(
                current: unit,
                units: units,
                onSelect: onUnitChange,
                enabled: !locked,
                width: unitWidth,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UnitPicklist extends StatelessWidget {
  final String current;
  final List<String> units;
  final ValueChanged<String> onSelect;
  final bool enabled;
  final double width;

  const UnitPicklist({
    super.key,
    required this.current,
    required this.units,
    required this.onSelect,
    this.enabled = true,
    this.width = 70,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      enabled: enabled,
      initialValue: current,
      onSelected: onSelect,
      child: Container(
        width: width,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              current,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 16, color: theme.colorScheme.primary),
          ],
        ),
      ),
      itemBuilder: (context) {
        final isDark = theme.brightness == Brightness.dark;
        final selectedBg = isDark ? const Color(0xFF1E3A52) : const Color(0xFFE2F0FE);
        return units.map((u) {
          final isSelected = u == current;
          return PopupMenuItem<String>(
            value: u,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                u,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
          );
        }).toList();
      },
    );
  }
}

class TypeSelector extends StatelessWidget {
  final String label;
  final String current;
  final List<String> options;
  final ValueChanged<String> onSelect;
  final double width;

  const TypeSelector({
    super.key,
    required this.label,
    required this.current,
    required this.options,
    required this.onSelect,
    this.width = 178,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            initialValue: current,
            onSelected: onSelect,
            child: Container(
              width: width,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      current,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: theme.colorScheme.primary),
                ],
              ),
            ),
            itemBuilder: (context) {
              final isDark = theme.brightness == Brightness.dark;
              final selectedBg = isDark ? const Color(0xFF1E3A52) : const Color(0xFFE2F0FE);
              return options.map((o) {
                final isSelected = o == current;
                return PopupMenuItem<String>(
                  value: o,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedBg : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      o,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}

class ReadOnlySettingField extends StatelessWidget {
  final String label;
  final String value;
  final double width;
  final VoidCallback? onLongClick;

  const ReadOnlySettingField({
    super.key,
    required this.label,
    required this.value,
    this.width = 160,
    this.onLongClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
          ),
          GestureDetector(
            onLongPress: onLongClick,
            child: Container(
              width: width,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.lock, size: 18, color: theme.colorScheme.outline),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NumberWheelPicker extends StatelessWidget {
  final double value;
  final List<double> range;
  final String format;
  final double multiplyBy;
  final ValueChanged<double> onValueChange;

  const NumberWheelPicker({
    super.key,
    required this.value,
    required this.range,
    this.format = '%.1f',
    this.multiplyBy = 1.0,
    required this.onValueChange,
  });

  String _formatVal(double v) {
    final adj = v * multiplyBy;
    if (format.contains('%%')) {
      return '${adj.toStringAsFixed(1)}%';
    } else if (format == '%.0f') {
      return adj.toInt().toString();
    } else {
      return adj.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => _NumberWheelDialog(
            initialValue: value,
            range: range,
            formatVal: _formatVal,
            onConfirm: onValueChange,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatVal(value),
              style: TextStyle(fontSize: 15, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 18, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class ItemWheelPicker<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final String Function(T) displayLabel;
  final ValueChanged<T> onValueChange;

  const ItemWheelPicker({
    super.key,
    required this.value,
    required this.options,
    required this.displayLabel,
    required this.onValueChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => _ItemWheelDialog<T>(
            initialValue: value,
            options: options,
            displayLabel: displayLabel,
            onConfirm: onValueChange,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel(value),
              style: TextStyle(fontSize: 15, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 18, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _ItemWheelDialog<T> extends StatefulWidget {
  final T initialValue;
  final List<T> options;
  final String Function(T) displayLabel;
  final ValueChanged<T> onConfirm;

  const _ItemWheelDialog({
    required this.initialValue,
    required this.options,
    required this.displayLabel,
    required this.onConfirm,
  });

  @override
  State<_ItemWheelDialog<T>> createState() => _ItemWheelDialogState<T>();
}

class _ItemWheelDialogState<T> extends State<_ItemWheelDialog<T>> {
  late int _selectedIndex;
  late FixedExtentScrollController _controller;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    final idx = widget.options.indexOf(widget.initialValue);
    _selectedIndex = idx >= 0 ? idx : 0;
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);
    final wheelBg = isDark ? const Color(0xFF1E242C) : const Color(0xFFF4F9FF);
    final highlightBg = isDark ? theme.colorScheme.primary.withOpacity(0.25) : const Color(0xFFE2F0FE);
    final primaryBlue = isDark ? theme.colorScheme.primary : const Color(0xFF2B9DF0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: dialogBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: wheelBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 44,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: highlightBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _controller,
                    itemExtent: 44,
                    perspective: 0.003,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.options.length,
                      builder: (context, index) {
                        final isSelected = index == _selectedIndex;
                        final item = widget.options[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            if (_isSelecting) return;
                            _isSelecting = true;
                            if (index == _selectedIndex) {
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                widget.onConfirm(item);
                              }
                            } else {
                              await _controller.animateToItem(
                                index,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                widget.onConfirm(item);
                              }
                            }
                          },
                          child: Center(
                            child: Text(
                              widget.displayLabel(item),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? primaryBlue : (isDark ? Colors.grey : const Color(0xFF889098)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onConfirm(widget.options[_selectedIndex]);
                },
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberWheelDialog extends StatefulWidget {
  final double initialValue;
  final List<double> range;
  final String Function(double) formatVal;
  final ValueChanged<double> onConfirm;

  const _NumberWheelDialog({
    required this.initialValue,
    required this.range,
    required this.formatVal,
    required this.onConfirm,
  });

  @override
  State<_NumberWheelDialog> createState() => _NumberWheelDialogState();
}

class _NumberWheelDialogState extends State<_NumberWheelDialog> {
  late int _selectedIndex;
  late FixedExtentScrollController _controller;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    final idx = widget.range.indexOf(widget.initialValue);
    _selectedIndex = idx >= 0 ? idx : 0;
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);
    final wheelBg = isDark ? const Color(0xFF1E242C) : const Color(0xFFF4F9FF);
    final highlightBg = isDark ? theme.colorScheme.primary.withOpacity(0.25) : const Color(0xFFE2F0FE);
    final primaryBlue = isDark ? theme.colorScheme.primary : const Color(0xFF2B9DF0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: dialogBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: wheelBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 44,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: highlightBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  ListWheelScrollView.useDelegate(
                    controller: _controller,
                    itemExtent: 44,
                    perspective: 0.003,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: widget.range.length,
                      builder: (context, index) {
                        final isSelected = index == _selectedIndex;
                        final item = widget.range[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            if (_isSelecting) return;
                            _isSelecting = true;
                            if (index == _selectedIndex) {
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                widget.onConfirm(item);
                              }
                            } else {
                              await _controller.animateToItem(
                                index,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                widget.onConfirm(item);
                              }
                            }
                          },
                          child: Center(
                            child: Text(
                              widget.formatVal(item),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? primaryBlue : (isDark ? Colors.grey : const Color(0xFF889098)),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onConfirm(widget.range[_selectedIndex]);
                },
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SortDialog extends StatelessWidget {
  final SortType currentType;
  final SortDirection currentDirection;
  final void Function(SortType type, SortDirection direction) onApply;

  const SortDialog({
    super.key,
    required this.currentType,
    required this.currentDirection,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    SortType selectedType = currentType;
    SortDirection selectedDir = currentDirection;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Sort By'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<SortType>(
                title: const Text('Name'),
                value: SortType.NAME,
                groupValue: selectedType,
                onChanged: (v) => setState(() => selectedType = v!),
              ),
              RadioListTile<SortType>(
                title: const Text('Date'),
                value: SortType.DATE,
                groupValue: selectedType,
                onChanged: (v) => setState(() => selectedType = v!),
              ),
              const Divider(),
              RadioListTile<SortDirection>(
                title: const Text('Ascending'),
                value: SortDirection.ASCENDING,
                groupValue: selectedDir,
                onChanged: (v) => setState(() => selectedDir = v!),
              ),
              RadioListTile<SortDirection>(
                title: const Text('Descending'),
                value: SortDirection.DESCENDING,
                groupValue: selectedDir,
                onChanged: (v) => setState(() => selectedDir = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                onApply(selectedType, selectedDir);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }
}
