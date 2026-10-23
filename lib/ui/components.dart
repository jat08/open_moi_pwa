import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/page_typography.dart';
import '../data/models.dart';
import '../logic/oscillation_detector.dart';
import '../providers/moi_provider.dart';

/// Constants for multipurpose bars (Top Search Bar, Sort Button, Selection Top Bar, Measurement Control Button)
const double kMultipurposeBarHeight = 52.0;
const double kMultipurposeBarRadius = 26.0;

/// One UI Drag Handle Bar Component for Bottom Sheets
class OneUiDragHandle extends StatelessWidget {
  const OneUiDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 38,
      height: 4.5,
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withOpacity(0.35),
        borderRadius: BorderRadius.circular(2.25),
      ),
    );
  }
}

class DynamicTitleText extends StatelessWidget {
  final String text;
  final double maxFontSize;
  final FontWeight fontWeight;
  final Color color;
  final int maxLines;

  const DynamicTitleText({
    super.key,
    required this.text,
    this.maxFontSize = 20,
    this.fontWeight = FontWeight.bold,
    this.color = Colors.black,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final typo = PageTypography.of(context);
    final targetSize = typo.cardTitleSize(maxFontSize);

    return LayoutBuilder(
      builder: (context, constraints) {
        double fontSize = targetSize;
        final style = TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );

        TextPainter textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: maxLines,
          textDirection: Directionality.maybeOf(context) ?? ui.TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);

        while ((textPainter.didExceedMaxLines || textPainter.height > (fontSize * 1.35 * maxLines)) && fontSize > 11) {
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
            maxLines: maxLines,
            textDirection: Directionality.maybeOf(context) ?? ui.TextDirection.ltr,
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
        }

        return Text(
          text,
          maxLines: maxLines,
          softWrap: true,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: color,
            height: 1.15,
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
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);

    return Container(
      decoration: BoxDecoration(
        color: dialogBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OneUiDragHandle(),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OneUiDragHandle(),
              const SizedBox(height: 4),
              const Text('Rename Group', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLength: 40,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        ),
                        onPressed: () {
                          final text = _controller.text.trim();
                          if (text.isNotEmpty) {
                            HapticFeedback.lightImpact();
                            widget.onConfirm(text);
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectionTopBar extends StatelessWidget {
  final int count;
  final bool isAllSelected;
  final bool isPartialSelected;
  final VoidCallback onToggleAll;
  final VoidCallback onClear;
  final VoidCallback onDelete;
  final VoidCallback? onCompare;

  const SelectionTopBar({
    super.key,
    required this.count,
    required this.isAllSelected,
    this.isPartialSelected = false,
    required this.onToggleAll,
    required this.onClear,
    required this.onDelete,
    this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool? checkboxValue = isAllSelected ? true : (isPartialSelected ? null : false);

    return Container(
      height: kMultipurposeBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(kMultipurposeBarRadius),
      ),
      child: Row(
        children: [
          Checkbox(
            tristate: true,
            value: checkboxValue,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onToggleAll();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: theme.colorScheme.onPrimaryContainer,
            onPressed: () {
              HapticFeedback.lightImpact();
              onClear();
            },
          ),
          const SizedBox(width: 4),
          Text(
            '$count Selected',
            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer, fontSize: 15),
          ),
          const Spacer(),
          if (onCompare != null) ...[
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.compare_arrows, size: 18),
              label: const Text(
                'Compare',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                onCompare!();
              },
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            icon: const Icon(Icons.delete, size: 22, color: Colors.red),
            onPressed: () {
              HapticFeedback.mediumImpact();
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}

class TopSearchBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onChanged;

  const TopSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF2B333E) : const Color(0xFFE9F1F8);

    return Container(
      height: kMultipurposeBarHeight,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(kMultipurposeBarRadius),
      ),
      child: TextField(
        controller: TextEditingController(text: query)..selection = TextSelection.collapsed(offset: query.length),
        onChanged: onChanged,
        style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(fontSize: 15, color: theme.colorScheme.outline),
          prefixIcon: Icon(Icons.search, size: 20, color: theme.colorScheme.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(''),
                )
              : null,
        ),
      ),
    );
  }
}

class SortIconButton extends StatelessWidget {
  final VoidCallback onTap;

  const SortIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF2B333E) : const Color(0xFFE9F1F8);

    return Container(
      width: kMultipurposeBarHeight,
      height: kMultipurposeBarHeight,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.sort, color: theme.colorScheme.primary, size: 22),
        onPressed: () {
          HapticFeedback.lightImpact();
          onTap();
        },
      ),
    );
  }
}

class MeasurementItem extends StatelessWidget {
  final Measurement measurement;
  final VoidCallback? onDelete;
  final VoidCallback onClick;
  final VoidCallback onLongClick;
  final bool selected;
  final int resolution;
  final int periodResolution;
  final double averageVal;
  final int index;
  final bool showType;
  final bool isPeriod;
  final bool hideUnits;
  final double fitThreshold;
  final double margin;
  final bool trimLast;

  const MeasurementItem({
    super.key,
    required this.measurement,
    this.onDelete,
    required this.onClick,
    required this.onLongClick,
    this.selected = false,
    this.resolution = 1,
    this.periodResolution = 4,
    this.averageVal = 0.0,
    required this.index,
    this.showType = true,
    this.isPeriod = false,
    this.hideUnits = false,
    this.fitThreshold = 1.5,
    this.margin = 0.003,
    this.trimLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isFitOutlier = measurement.fitResidual >= fitThreshold;
    final isStatisticalOutlier = averageVal > 0 &&
        (measurement.moi - averageVal).abs() / averageVal > margin;

    final displayVal = isPeriod ? measurement.period : measurement.moi;
    final displayRes = isPeriod ? periodResolution : resolution;
    final unitStr = isPeriod ? 's' : 'kg·cm²';

    final valueText = '${displayVal.toStringAsFixed(displayRes)}${hideUnits ? '' : ' $unitStr'}';

    final cardBg = selected
        ? theme.colorScheme.primaryContainer
        : (isFitOutlier || isStatisticalOutlier
            ? (isDark ? const Color(0xFF3E2424) : const Color(0xFFFFF0F0))
            : theme.colorScheme.surfaceContainerHighest);

    final borderColor = selected
        ? theme.colorScheme.primary
        : (isFitOutlier || isStatisticalOutlier
            ? Colors.red.withOpacity(0.5)
            : BorderSide.none.color);

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: selected || isFitOutlier || isStatisticalOutlier
            ? BorderSide(color: borderColor, width: selected ? 2 : 1)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 3.5),
      child: InkWell(
        onTap: onClick,
        onLongPress: onLongClick,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(
                '#$index',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          valueText,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isFitOutlier || isStatisticalOutlier
                                ? Colors.red
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        if (isFitOutlier || isStatisticalOutlier) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Period: ${measurement.period.toStringAsFixed(periodResolution)} s  •  Residual: ${measurement.fitResidual.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              if (measurement.rawData.isNotEmpty) ...[
                const SizedBox(width: 8),
                MiniSparklineWidget(
                  rawData: measurement.rawData,
                  color: measurement.moi >= 40 ? theme.colorScheme.primary : theme.colorScheme.secondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.outline,
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    actionLabel!,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onAction!();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MiniSparklineWidget extends StatelessWidget {
  final String rawData;
  final Color color;
  final double height;

  const MiniSparklineWidget({
    super.key,
    required this.rawData,
    required this.color,
    this.height = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final points = rawData
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s) ?? 0.0)
        .toList();

    if (points.isEmpty) return const SizedBox.shrink();

    List<double> sampled = points;
    if (points.length > 60) {
      final step = points.length / 60;
      sampled = List.generate(60, (i) => points[(i * step).floor()]);
    }

    final maxVal = sampled.map((d) => d.abs()).fold(0.01, max);

    return SizedBox(
      height: height,
      width: 50,
      child: CustomPaint(
        painter: _MiniSparklinePainter(
          points: sampled,
          maxVal: maxVal,
          color: color,
        ),
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final List<double> points;
  final double maxVal;
  final Color color;

  _MiniSparklinePainter({
    required this.points,
    required this.maxVal,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (points.length - 1);
    final midY = size.height / 2.0;

    fillPath.moveTo(0, midY);

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normY = (points[i] / maxVal).clamp(-1.0, 1.0);
      final y = midY - (normY * (size.height / 2.0 - 2.0));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, midY);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class MeasurementControlButton extends StatelessWidget {
  final OscillationState state;
  final double progress;
  final bool isCalibrated;
  final double cooldownRemaining;
  final int preparationRemaining;
  final VoidCallback onStart;
  final VoidCallback? onCancel;

  const MeasurementControlButton({
    super.key,
    required this.state,
    required this.progress,
    required this.isCalibrated,
    this.cooldownRemaining = 0.0,
    this.preparationRemaining = 0,
    required this.onStart,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget content;

    if (!isCalibrated) {
      content = Consumer(
        builder: (context, ref, child) => InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
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
                fontSize: 16,
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
            fontSize: 16,
          ),
        ),
      );
    } else if (preparationRemaining > 0) {
      content = InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onCancel?.call();
        },
        child: Container(
          color: Colors.grey.shade700,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Waiting $preparationRemaining Seconds to be Ready',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Text(
                  'Tap to Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    } else if (cooldownRemaining > 0) {
      content = InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onCancel?.call();
        },
        child: Container(
          color: Colors.grey.shade700,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Waiting ${cooldownRemaining.toInt()} seconds',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Text(
                  'Tap to Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      switch (state) {
        case OscillationState.READY:
          content = ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              onStart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
            child: const Text('Start Measurement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          );
          break;
        case OscillationState.ARMED:
          content = InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onCancel?.call();
            },
            child: Container(
              color: theme.colorScheme.primary.withOpacity(0.2),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ready - Waiting for Oscillations',
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Tap to Cancel',
                      style: TextStyle(color: theme.colorScheme.primary.withOpacity(0.7), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          );
          break;
        case OscillationState.SETTLING:
        case OscillationState.ACTIVE_COUNTING:
          final label = state == OscillationState.SETTLING ? 'Settling...' : 'Measuring...';
          final pct = (progress * 100).toInt().clamp(0, 100);
          content = InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onCancel?.call();
            },
            child: Stack(
              children: [
                Container(color: theme.colorScheme.primary.withOpacity(0.15)),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(color: theme.colorScheme.primary.withOpacity(0.35)),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$label $pct%',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                          ),
                          Text(
                            'Tap to Cancel',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.primary.withOpacity(0.8), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
          break;
        default:
          content = const SizedBox.shrink();
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(kMultipurposeBarRadius),
      child: SizedBox(
        height: kMultipurposeBarHeight,
        width: double.infinity,
        child: content,
      ),
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
    final typo = PageTypography.of(context);

    final hasSW = avgSW > 0;
    final hasTW = avgTW > 0;

    final swVal = hasSW ? '${avgSW.toStringAsFixed(moiResolution)} kg·cm²' : 'No Data';
    final swTol = hasSW ? '± ${stdDevSW.toStringAsFixed(moiResolution)} kg·cm²' : '';
    final twVal = hasTW ? '${avgTW.toStringAsFixed(moiResolution)} kg·cm²' : 'No Data';
    final twTol = hasTW ? '± ${stdDevTW.toStringAsFixed(moiResolution)} kg·cm²' : '';

    final periodSWText = hasSW ? 'Period: ${avgPeriodSW.toStringAsFixed(periodResolution)} ± ${stdDevPeriodSW.toStringAsFixed(periodResolution)} s' : 'Period: No Data';
    final periodTWText = hasTW ? 'Period: ${avgPeriodTW.toStringAsFixed(periodResolution)} ± ${stdDevPeriodTW.toStringAsFixed(periodResolution)} s' : 'Period: No Data';

    final bpVal = calculatedBP != null && calculatedBP! > 0 ? '${calculatedBP!.toStringAsFixed(moiResolution)} cm' : null;
    final bpTol = calculatedBP != null && calculatedBP! > 0 && stdDevBP != null ? '± ${stdDevBP!.toStringAsFixed(moiResolution)} cm' : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - 48) / 2.0;
        final valueFontSize = typo.computeUnifiedSize(
          texts: [swVal, twVal],
          maxFontSize: 36.0,
          maxWidth: halfWidth,
          fontWeight: FontWeight.bold,
          textScaler: MediaQuery.textScalerOf(context),
        );

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                          Text('Swing Weight', style: TextStyle(fontSize: typo.cardTitleSize(16), fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onLongPress: () {
                              HapticFeedback.lightImpact();
                              Clipboard.setData(ClipboardData(text: avgSW.toStringAsFixed(moiResolution)));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied SW: ${avgSW.toStringAsFixed(moiResolution)}')),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    swVal,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: valueFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                if (hasSW) ...[
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      swTol,
                                      style: TextStyle(
                                        fontSize: typo.cardTitleSize(15),
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary.withOpacity(0.85),
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onLongPress: () {
                              if (hasSW) {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: avgPeriodSW.toStringAsFixed(periodResolution)));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied Period SW: ${avgPeriodSW.toStringAsFixed(periodResolution)}')),
                                );
                              }
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                periodSWText,
                                style: TextStyle(fontSize: typo.subtextSize(14), fontWeight: FontWeight.w500, color: theme.colorScheme.outline, height: 1.1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 110,
                      color: theme.colorScheme.outline.withOpacity(0.25),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Twist Weight', style: TextStyle(fontSize: typo.cardTitleSize(16), fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onLongPress: () {
                              HapticFeedback.lightImpact();
                              Clipboard.setData(ClipboardData(text: avgTW.toStringAsFixed(moiResolution)));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied TW: ${avgTW.toStringAsFixed(moiResolution)}')),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    twVal,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: valueFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.secondary,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                if (hasTW) ...[
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      twTol,
                                      style: TextStyle(
                                        fontSize: typo.cardTitleSize(15),
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.secondary.withOpacity(0.85),
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onLongPress: () {
                              if (hasTW) {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: avgPeriodTW.toStringAsFixed(periodResolution)));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied Period TW: ${avgPeriodTW.toStringAsFixed(periodResolution)}')),
                                );
                              }
                            },
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                periodTWText,
                                style: TextStyle(fontSize: typo.subtextSize(14), fontWeight: FontWeight.w500, color: theme.colorScheme.outline, height: 1.1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (bpVal != null) ...[
                  Divider(height: 20, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.25)),
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.lightImpact();
                      Clipboard.setData(ClipboardData(text: calculatedBP!.toStringAsFixed(moiResolution)));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied BP: ${calculatedBP!.toStringAsFixed(moiResolution)}')),
                      );
                    },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Balance Point: ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.outline)),
                          Text(bpVal, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                          if (bpTol != null) ...[
                            const SizedBox(width: 4),
                            Text(bpTol, style: TextStyle(fontSize: 15, color: theme.colorScheme.outline)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
  final VoidCallback? onInfoClick;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typo = PageTypography.of(context);
    final note = expectedNote;
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - 48) / (fullLabel2 != null ? 2.0 : 1.0);
        final valueFontSize = typo.computeUnifiedSize(
          texts: [inlineToleranceWithUnits ? inlineVal1 : val1, if (fullLabel2 != null) val2],
          maxFontSize: inlineToleranceWithUnits ? 24.0 : 36.0,
          maxWidth: halfWidth,
          fontWeight: FontWeight.bold,
          textScaler: MediaQuery.textScalerOf(context),
        );

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                          Text(fullLabel1, style: TextStyle(fontSize: typo.cardTitleSize(16), fontWeight: FontWeight.bold, color: theme.colorScheme.primary, letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onLongPress: () {
                              HapticFeedback.lightImpact();
                              Clipboard.setData(ClipboardData(text: val1));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Copied $fullLabel1: $val1')),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    inlineToleranceWithUnits ? inlineVal1 : val1,
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontSize: valueFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                                if (!inlineToleranceWithUnits && hasVal1) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    tol1,
                                    style: TextStyle(fontSize: typo.cardTitleSize(15), fontWeight: FontWeight.bold, color: theme.colorScheme.primary.withOpacity(0.85), height: 1.1),
                                  ),
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
                        color: theme.colorScheme.outline.withOpacity(0.25),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fullLabel2, style: TextStyle(fontSize: typo.cardTitleSize(16), fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, letterSpacing: 0.5)),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onLongPress: () {
                                HapticFeedback.lightImpact();
                                Clipboard.setData(ClipboardData(text: val2));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Copied $fullLabel2: $val2')),
                                );
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      val2,
                                      maxLines: 1,
                                      softWrap: false,
                                      style: TextStyle(
                                        fontSize: valueFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.secondary,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  if (hasVal2) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      tol2,
                                      style: TextStyle(fontSize: typo.cardTitleSize(15), fontWeight: FontWeight.bold, color: theme.colorScheme.secondary.withOpacity(0.85), height: 1.1),
                                    ),
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
                if (note != null && note.isNotEmpty) ...[
                  Divider(height: 20, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.25)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            note,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.outline),
                          ),
                        ),
                      ),
                      if (onInfoClick != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            onInfoClick!();
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.sell,
                              color: theme.colorScheme.onPrimary,
                              size: 22,
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
      },
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.only(left: 6, right: 6, top: 0, bottom: 0),
                    prefixIcon: locked ? Icon(Icons.lock, size: 18, color: theme.colorScheme.outline) : null,
                    prefixIconConstraints: locked ? const BoxConstraints(minWidth: 28, minHeight: 0) : null,
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
      onSelected: (val) {
        HapticFeedback.selectionClick();
        onSelect(val);
      },
      child: Container(
        width: width,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  current,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ),
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
            height: 38,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: 38,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: isSelected ? selectedBg : null,
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
                maxLines: 2,
                softWrap: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            initialValue: current,
            onSelected: (val) {
              HapticFeedback.selectionClick();
              onSelect(val);
            },
            child: Container(
              constraints: BoxConstraints(maxWidth: width),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        current,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
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
                  height: 38,
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: double.infinity,
                    height: 38,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: isSelected ? selectedBg : null,
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
                maxLines: 2,
                softWrap: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onLongPress: () {
              if (onLongClick != null) {
                HapticFeedback.lightImpact();
                onLongClick!();
              }
            },
            child: Container(
              constraints: BoxConstraints(maxWidth: width),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
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
  final String? title;
  final ValueChanged<double> onValueChange;

  const NumberWheelPicker({
    super.key,
    required this.value,
    required this.range,
    this.format = '%.1f',
    this.multiplyBy = 1.0,
    this.title,
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
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _NumberWheelDialog(
            initialValue: value,
            range: range,
            formatVal: _formatVal,
            title: title,
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
  final String? title;
  final ValueChanged<T> onValueChange;

  const ItemWheelPicker({
    super.key,
    required this.value,
    required this.options,
    required this.displayLabel,
    this.title,
    required this.onValueChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => _ItemWheelDialog<T>(
            initialValue: value,
            options: options,
            displayLabel: displayLabel,
            title: title,
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
  final String? title;
  final ValueChanged<T> onConfirm;

  const _ItemWheelDialog({
    required this.initialValue,
    required this.options,
    required this.displayLabel,
    this.title,
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

    return Container(
      decoration: BoxDecoration(
        color: dialogBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OneUiDragHandle(),
            const SizedBox(height: 4),
            Text(
              widget.title?.replaceAll('\n', ' ') ?? 'Select Value',
              style: const TextStyle(
                fontSize: 19,
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
                borderRadius: BorderRadius.circular(20),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.20, 0.80, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListWheelScrollView.useDelegate(
                      controller: _controller,
                      itemExtent: 44,
                      perspective: 0.003,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        HapticFeedback.selectionClick();
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
                              HapticFeedback.lightImpact();
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  widget.onConfirm(widget.options[_selectedIndex]);
                },
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
  final String? title;
  final ValueChanged<double> onConfirm;

  const _NumberWheelDialog({
    required this.initialValue,
    required this.range,
    required this.formatVal,
    this.title,
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

    return Container(
      decoration: BoxDecoration(
        color: dialogBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const OneUiDragHandle(),
            const SizedBox(height: 4),
            Text(
              widget.title?.replaceAll('\n', ' ') ?? 'Select Value',
              style: const TextStyle(
                fontSize: 19,
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
                borderRadius: BorderRadius.circular(20),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black,
                          Colors.black,
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.20, 0.80, 1.0],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ListWheelScrollView.useDelegate(
                      controller: _controller,
                      itemExtent: 44,
                      perspective: 0.003,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        HapticFeedback.selectionClick();
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
                              HapticFeedback.lightImpact();
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  widget.onConfirm(widget.range[_selectedIndex]);
                },
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OneUiDragHandle(),
                const SizedBox(height: 4),
                const Text('Sort Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                RadioGroup<SortType>(
                  groupValue: selectedType,
                  onChanged: (v) {
                    if (v != null) {
                      HapticFeedback.selectionClick();
                      setState(() => selectedType = v);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      RadioListTile<SortType>(
                        title: Text('Name'),
                        value: SortType.NAME,
                      ),
                      RadioListTile<SortType>(
                        title: Text('Date'),
                        value: SortType.DATE,
                      ),
                    ],
                  ),
                ),
                const Divider(),
                RadioGroup<SortDirection>(
                  groupValue: selectedDir,
                  onChanged: (v) {
                    if (v != null) {
                      HapticFeedback.selectionClick();
                      setState(() => selectedDir = v);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      RadioListTile<SortDirection>(
                        title: Text('Ascending'),
                        value: SortDirection.ASCENDING,
                      ),
                      RadioListTile<SortDirection>(
                        title: Text('Descending'),
                        value: SortDirection.DESCENDING,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                            onApply(selectedType, selectedDir);
                          },
                          child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}
