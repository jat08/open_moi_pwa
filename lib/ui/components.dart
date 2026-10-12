import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../data/models.dart';
import '../logic/oscillation_detector.dart';
import '../providers/moi_provider.dart';

class DynamicTitleText extends StatelessWidget {
  final String text;
  final double maxFontSize;
  final FontWeight? fontWeight;
  final FontStyle? fontStyle;
  final Color? color;
  final TextAlign? textAlign;

  const DynamicTitleText({
    super.key,
    required this.text,
    this.maxFontSize = 20,
    this.fontWeight,
    this.fontStyle,
    this.color,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontSize: maxFontSize,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              color: color,
            ),
            textAlign: textAlign,
          ),
        );
      },
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
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
              IconButton(
                icon: Icon(
                  isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  color: theme.colorScheme.primary,
                ),
                onPressed: onToggleAll,
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onToggleAll,
                child: Text(
                  '$count selected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              color: count > 0 ? Colors.red : Colors.grey,
            ),
            onPressed: count > 0
                ? () {
                    showDialog(
                      context: context,
                      builder: (ctx) => DeleteConfirmationDialog(
                        title: 'Delete Items?',
                        text: 'Are you sure you want to delete $count selected items? This action cannot be undone.',
                        onConfirm: onDelete,
                      ),
                    );
                  }
                : null,
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

  static const Color primaryBlue = Color(0xFF38A5F2);
  static const Color secondaryTeal = Color(0xFF0D7A70);
  static const Color cardBg = Color(0xFFEFF4F9);

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
      final candidates = (trimLast && cycles.length > 1) ? cycles.sublist(0, cycles.length - 1) : cycles;
      avgMeasured = candidates.reduce((a, b) => a + b) / candidates.length;
    }

    final value = isPeriod ? avgMeasured : measurement.moi;

    final isOutlier = averageVal > 0
        ? ((value - averageVal).abs() / averageVal) > margin
        : false;

    final containerColor = AppColors.getCardBackgroundColor(
      context: context,
      isSelected: selected,
      isError: measurement.fitResidual >= fitThreshold,
      isOutlier: isOutlier,
    );

    final String valueText = isPeriod
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
        borderRadius: BorderRadius.circular(10),
        side: selected ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      child: InkWell(
        onTap: onClick,
        onLongPress: onLongClick,
        borderRadius: BorderRadius.circular(10),
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
                    if (measurement.fitResidual >= fitThreshold)
                      Text(
                        'Poor Fit Quality',
                        style: TextStyle(
                          color: isDark ? AppColors.errorTextDark : AppColors.errorTextLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      )
                    else if (isOutlier)
                      Text(
                        'High Deviation',
                        style: TextStyle(
                          color: isDark ? AppColors.warningTextDark : AppColors.warningTextLight,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
                  child: Icon(Icons.delete, size: 26, color: theme.colorScheme.outline),
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
      content = Container(
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

  static const Color primaryBlue = Color(0xFF38A5F2);
  static const Color secondaryTeal = Color(0xFF0D7A70);
  static const Color greyLabel = Color(0xFF8E8E93);

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
    final swStr = '${avgSW.toStringAsFixed(moiResolution)} ± ${stdDevSW.toStringAsFixed(moiResolution)} kg·cm²';
    final twStr = '${avgTW.toStringAsFixed(moiResolution)} ± ${stdDevTW.toStringAsFixed(moiResolution)} kg·cm²';
    final pSWVal = '${avgPeriodSW.toStringAsFixed(periodResolution)} ± ${stdDevPeriodSW.toStringAsFixed(periodResolution)}s';
    final pTWVal = '${avgPeriodTW.toStringAsFixed(periodResolution)} ± ${stdDevPeriodTW.toStringAsFixed(periodResolution)}s';

    String? bpStr;
    if (calculatedBP != null && calculatedBP! > 0) {
      final bpVal = calculatedBP!.toStringAsFixed(moiResolution);
      final bpTol = (stdDevBP != null && stdDevBP! > 0) ? ' ± ${stdDevBP!.toStringAsFixed(moiResolution)}' : '';
      bpStr = '$bpVal$bpTol cm';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: avgSW.toStringAsFixed(moiResolution)));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied SW: ${avgSW.toStringAsFixed(moiResolution)}')),
            );
          },
          child: DynamicTitleText(
            text: 'SW: $swStr',
            maxFontSize: 32,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: avgPeriodSW.toStringAsFixed(periodResolution)));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied Period: ${avgPeriodSW.toStringAsFixed(periodResolution)}')),
            );
          },
          child: Row(
            children: [
              const Text('Period SW: ', style: TextStyle(fontSize: 18, color: greyLabel, fontWeight: FontWeight.bold)),
              Text(pSWVal, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
            ],
          ),
        ),
        if (bpStr != null) ...[
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: calculatedBP!.toStringAsFixed(moiResolution)));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied BP: ${calculatedBP!.toStringAsFixed(moiResolution)}')),
              );
            },
            child: Row(
              children: [
                const Text('BP: ', style: TextStyle(fontSize: 18, color: greyLabel, fontWeight: FontWeight.bold)),
                Text(bpStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
              ],
            ),
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Divider(height: 1, thickness: 1.0, color: Color(0xFFC7C7CC)),
        ),
        GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: avgTW.toStringAsFixed(moiResolution)));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied TW: ${avgTW.toStringAsFixed(moiResolution)}')),
            );
          },
          child: DynamicTitleText(
            text: 'TW: $twStr',
            maxFontSize: 32,
            fontWeight: FontWeight.bold,
            color: secondaryTeal,
          ),
        ),
        GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: avgPeriodTW.toStringAsFixed(periodResolution)));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Copied Period: ${avgPeriodTW.toStringAsFixed(periodResolution)}')),
            );
          },
          child: Row(
            children: [
              const Text('Period TW: ', style: TextStyle(fontSize: 18, color: greyLabel, fontWeight: FontWeight.bold)),
              Text(pTWVal, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: secondaryTeal)),
            ],
          ),
        ),
      ],
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
    this.expectedNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = isPeriod ? periodResolution : moiResolution;
    final unit = isPeriod ? 's' : 'kg·cm²';

    final val1 = showTolerance
        ? '${avg.toStringAsFixed(res)} ± ${stdDev.toStringAsFixed(res)} $unit'
        : '${avg.toStringAsFixed(res)} $unit';

    final line1 = '$label: $val1';

    String? line2;
    if (label2 != null) {
      line2 = showTolerance
          ? '$label2: ${avg2.toStringAsFixed(moiResolution)} ± ${stdDev2.toStringAsFixed(moiResolution)} kg·cm²'
          : '$label2: ${avg2.toStringAsFixed(moiResolution)} kg·cm²';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DynamicTitleText(
          text: line1,
          maxFontSize: 32,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
        if (line2 != null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, thickness: 1.0, color: Color(0xFFC7C7CC)),
          ),
          DynamicTitleText(
            text: line2,
            maxFontSize: 32,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.secondary,
          ),
        ],
        if (expectedNote != null) ...[
          const SizedBox(height: 4),
          Text(
            expectedNote!,
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: theme.colorScheme.outline),
          ),
        ],
      ],
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
    return AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('No'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text('Yes'),
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
      title: const Text('Rename Group'),
      content: TextField(
        controller: _controller,
        maxLength: 40,
        decoration: const InputDecoration(
          labelText: 'New Name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onConfirm(_controller.text);
          },
          child: const Text('Rename'),
        ),
      ],
    );
  }
}

class SortDialog extends StatefulWidget {
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
  State<SortDialog> createState() => _SortDialogState();
}

class _SortDialogState extends State<SortDialog> {
  late SortType _type;
  late SortDirection _direction;

  @override
  void initState() {
    super.initState();
    _type = widget.currentType;
    _direction = widget.currentDirection;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Sort', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          RadioListTile<SortType>(
            title: const Text('Name'),
            value: SortType.NAME,
            groupValue: _type,
            onChanged: (val) => setState(() => _type = val!),
          ),
          RadioListTile<SortType>(
            title: const Text('Date'),
            value: SortType.DATE,
            groupValue: _type,
            onChanged: (val) => setState(() => _type = val!),
          ),
          const Divider(),
          Text('Direction', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
          RadioListTile<SortDirection>(
            title: const Text('Ascending'),
            value: SortDirection.ASCENDING,
            groupValue: _direction,
            onChanged: (val) => setState(() => _direction = val!),
          ),
          RadioListTile<SortDirection>(
            title: const Text('Descending'),
            value: SortDirection.DESCENDING,
            groupValue: _direction,
            onChanged: (val) => setState(() => _direction = val!),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onApply(_type, _direction);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class ReadOnlySettingField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onLongClick;
  final double width;

  const ReadOnlySettingField({
    super.key,
    required this.label,
    required this.value,
    this.onLongClick,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onLongPress: onLongClick,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
              ),
            ),
            SizedBox(
              width: width,
              height: 40,
              child: TextField(
                controller: TextEditingController(text: value),
                readOnly: true,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.normal,
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, size: 18, color: theme.colorScheme.outline),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NumberWheelPicker extends StatelessWidget {
  final double value;
  final List<double> range;
  final ValueChanged<double> onValueChange;
  final String format;
  final double multiplyBy;

  const NumberWheelPicker({
    super.key,
    required this.value,
    required this.range,
    required this.onValueChange,
    this.format = '%.1f',
    this.multiplyBy = 1.0,
  });

  String _formatVal(double val) {
    final v = val * multiplyBy;
    if (format.contains('%%')) {
      return '${v.toStringAsFixed(1)}%';
    } else if (format.contains('%.0f')) {
      return v.toInt().toString();
    } else if (format.contains('%.2f')) {
      return v.toStringAsFixed(2);
    } else {
      return v.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
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
      child: Text(
        _formatVal(value),
        style: const TextStyle(fontSize: 16, color: Color(0xFF38A5F2), fontWeight: FontWeight.bold),
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
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
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
      child: Text(
        displayLabel(value),
        style: const TextStyle(fontSize: 16, color: Color(0xFF38A5F2), fontWeight: FontWeight.bold),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                borderRadius: BorderRadius.circular(16),
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
                          onTap: () {
                            _controller.animateToItem(
                              index,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            );
                            setState(() {
                              _selectedIndex = index;
                            });
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
                    borderRadius: BorderRadius.circular(24),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                borderRadius: BorderRadius.circular(16),
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
                          onTap: () {
                            _controller.animateToItem(
                              index,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            );
                            setState(() {
                              _selectedIndex = index;
                            });
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
                    borderRadius: BorderRadius.circular(24),
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

class EstimationInputField extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final List<String> units;
  final ValueChanged<String> onValueChange;
  final ValueChanged<String> onUnitChange;
  final bool locked;

  const EstimationInputField({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.units,
    required this.onValueChange,
    required this.onUnitChange,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = locked && value.isEmpty ? 'N/A' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
            ),
          ),
          SizedBox(
            width: 120,
            height: 40,
            child: TextField(
              controller: TextEditingController(text: displayValue)
                ..selection = TextSelection.collapsed(offset: displayValue.length),
              onChanged: locked ? null : onValueChange,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              readOnly: locked,
              textAlign: locked ? TextAlign.end : TextAlign.start,
              style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                prefixIcon: locked ? Icon(Icons.lock, size: 18, color: theme.colorScheme.outline) : null,
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          UnitPicklist(current: unit, options: units, onSelect: onUnitChange),
        ],
      ),
    );
  }
}

class UnitPicklist extends StatelessWidget {
  final String current;
  final List<String> options;
  final ValueChanged<String> onSelect;

  const UnitPicklist({
    super.key,
    required this.current,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      initialValue: current,
      onSelected: onSelect,
      child: Container(
        width: 80,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(current, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
      ),
      itemBuilder: (context) {
        return options.map((opt) {
          return PopupMenuItem<String>(
            value: opt,
            child: Text(opt),
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

  const TypeSelector({
    super.key,
    required this.label,
    required this.current,
    required this.options,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
            ),
          ),
          PopupMenuButton<String>(
            initialValue: current,
            onSelected: onSelect,
            child: Container(
              width: 208,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(current, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            ),
            itemBuilder: (context) {
              return options.map((opt) {
                return PopupMenuItem<String>(
                  value: opt,
                  child: Text(opt),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}
