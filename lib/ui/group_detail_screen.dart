import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../providers/moi_provider.dart';
import 'components.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final int groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  Set<int> selectedIds = {};
  bool isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(moiProvider);
    final notifier = ref.read(moiProvider.notifier);
    final theme = Theme.of(context);

    final summary = uiState.groups.firstWhere(
      (g) => g.group.id == widget.groupId,
      orElse: () => GroupSummary(
        group: MeasurementGroup(name: 'Group Details'),
        count: 0,
        avgSW: 0,
        stdDevSW: 0,
        avgTW: 0,
        stdDevTW: 0,
      ),
    );

    final group = summary.group;

    // Balance Point Calculation Logic
    double? calculatedBP;
    double? stdDevBP;

    if (group.mass > 0 && group.length > 0) {
      final sw = uiState.currentSWAverage;
      final swStdDev = uiState.currentSWStdDev;

      double mKg = group.mass;
      if (group.massUnit == 'oz') mKg = group.mass * 0.028349523125;
      if (group.massUnit == 'lb') mKg = group.mass * 0.45359237;

      final l = group.length;

      if (group.groupType == 'Pickleball Paddle') {
        final lInches = group.lengthUnit == 'cm' ? l / 2.54 : l;
        calculatedBP = (sw - (492.0045 * mKg) - (6.8663 * lInches) + 259.5087) / 6.2811;

        final swContribution = swStdDev / 6.2811;
        final inherentContribution = (sw * 0.014) / 6.2811;
        stdDevBP = sqrt(pow(swContribution, 2) + pow(inherentContribution, 2));
      } else {
        final lCm = group.lengthUnit == 'in' ? l * 2.54 : l;
        final tOffset = (group.groupType == 'Racquet' || group.groupType == 'MOI-10') ? 10.0 : 5.0;
        const r = 9.1;

        final insideSqrt = (sw / mKg) - (pow(lCm, 2) / 12.0) - (pow(r, 2) / 4.0);
        if (insideSqrt >= 0) {
          final root = sqrt(insideSqrt);
          calculatedBP = root + tOffset;

          if (root > 0.01) {
            final swContribution = swStdDev / (2.0 * mKg * root);
            stdDevBP = sqrt(pow(swContribution, 2) + pow(0.25, 2));
          } else {
            stdDevBP = 0.25;
          }
        }
      }
    }

    final tareLabel = uiState.selectedTareMode == 'PICKLEBALL'
        ? 'PB'
        : uiState.selectedTareMode == 'TWIST'
            ? 'TW'
            : 'None';

    final measurements = uiState.selectedGroupMeasurements;
    final swMeasurements = measurements.where((m) => m.moi >= 40).toList();
    final twMeasurements = measurements.where((m) => m.moi < 40).toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isSelectionMode) {
          setState(() {
            selectedIds.clear();
            isSelectionMode = false;
          });
        } else {
          notifier.selectGroup(null);
        }
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
                      onPressed: () => notifier.selectGroup(null),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => RenameDialog(
                              currentName: group.name,
                              onConfirm: (newName) => notifier.renameGroup(group, newName),
                            ),
                          );
                        },
                        child: DynamicTitleText(
                          text: group.name,
                          maxFontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                SummaryHeaderLarge(
                  avgSW: uiState.currentSWAverage,
                  stdDevSW: uiState.currentSWStdDev,
                  avgTW: uiState.currentTWAverage,
                  stdDevTW: uiState.currentTWStdDev,
                  avgPeriodSW: uiState.currentSWPeriodAverage,
                  stdDevPeriodSW: uiState.currentSWPeriodStdDev,
                  avgPeriodTW: uiState.currentTWPeriodAverage,
                  stdDevPeriodTW: uiState.currentTWPeriodStdDev,
                  moiResolution: uiState.moiUnitsResolution,
                  periodResolution: uiState.periodUnitsResolution,
                  calculatedBP: calculatedBP,
                  stdDevBP: stdDevBP,
                ),

                const SizedBox(height: 4),

                // Harmonized Tare Selector & Info Button Control Row
                Row(
                  children: [
                    Expanded(
                      child: PopupMenuButton<String>(
                        initialValue: uiState.selectedTareMode,
                        onSelected: (mode) => notifier.setTareMode(mode),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tare Adapter: $tareLabel',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Icon(Icons.keyboard_arrow_down, size: 20, color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                        itemBuilder: (context) {
                          final isDark = theme.brightness == Brightness.dark;
                          final selectedBg = isDark ? const Color(0xFF1E3A52) : const Color(0xFFE2F0FE);
                          final isNone = uiState.selectedTareMode == 'NONE';
                          final isPB = uiState.selectedTareMode == 'PICKLEBALL';
                          final isTW = uiState.selectedTareMode == 'TWIST';
                          return [
                            PopupMenuItem<String>(
                              value: 'NONE',
                              height: 38,
                              padding: EdgeInsets.zero,
                              child: Container(
                                width: double.infinity,
                                height: 38,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                color: isNone ? selectedBg : null,
                                child: Text(
                                  'None',
                                  style: TextStyle(
                                    fontWeight: isNone ? FontWeight.bold : FontWeight.normal,
                                    color: isNone ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'PICKLEBALL',
                              enabled: uiState.pickleballTareOffset > 0,
                              height: 38,
                              padding: EdgeInsets.zero,
                              child: Container(
                                width: double.infinity,
                                height: 38,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                color: isPB ? selectedBg : null,
                                child: Text(
                                  uiState.pickleballTareOffset > 0 ? 'Pickleball Adapter' : 'PB-Tare Adapter First',
                                  style: TextStyle(
                                    fontWeight: isPB ? FontWeight.bold : FontWeight.normal,
                                    color: isPB ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            PopupMenuItem<String>(
                              value: 'TWIST',
                              enabled: uiState.twistTareOffset > 0,
                              height: 38,
                              padding: EdgeInsets.zero,
                              child: Container(
                                width: double.infinity,
                                height: 38,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                color: isTW ? selectedBg : null,
                                child: Text(
                                  uiState.twistTareOffset > 0 ? 'Twist Weight Adapter' : 'TW-Tare Adapter First',
                                  style: TextStyle(
                                    fontWeight: isTW ? FontWeight.bold : FontWeight.normal,
                                    color: isTW ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => notifier.selectEditingAttributesGroup(widget.groupId),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(18),
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
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 48,
                  child: isSelectionMode
                      ? SelectionTopBar(
                          count: selectedIds.length,
                          isAllSelected: selectedIds.length >= measurements.length && measurements.isNotEmpty,
                          onToggleAll: () {
                            setState(() {
                              if (selectedIds.length >= measurements.length) {
                                selectedIds.clear();
                              } else {
                                selectedIds = measurements.map((m) => m.id!).toSet();
                              }
                            });
                          },
                          onClear: () {
                            setState(() {
                              selectedIds.clear();
                              isSelectionMode = false;
                            });
                          },
                          onDelete: () {
                            notifier.deleteMeasurements(selectedIds);
                            setState(() {
                              selectedIds.clear();
                              isSelectionMode = false;
                            });
                          },
                        )
                      : MeasurementControlButton(
                          state: uiState.detectorState,
                          progress: uiState.progress,
                          isCalibrated: uiState.isCalibrated,
                          cooldownRemaining: uiState.cooldownRemaining,
                          preparationRemaining: uiState.preparationRemaining,
                          onStart: () => notifier.startMeasurement(),
                        ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: ListView(
                    children: [
                      if (swMeasurements.isNotEmpty) ...[
                        Text(
                          'Swing Weight (kg·cm²)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ...swMeasurements.asMap().entries.map((entry) {
                          final index = entry.key;
                          final m = entry.value;
                          final isSelected = selectedIds.contains(m.id);
                          return MeasurementItem(
                            measurement: m,
                            selected: isSelected,
                            index: swMeasurements.length - index,
                            resolution: uiState.moiUnitsResolution,
                            periodResolution: uiState.periodUnitsResolution,
                            averageVal: uiState.currentSWAverage,
                            hideUnits: true,
                            fitThreshold: uiState.fitResidualExclusion,
                            margin: uiState.swMargin,
                            trimLast: uiState.trimLastCycle,
                            onClick: () {
                              if (isSelectionMode) {
                                setState(() {
                                  if (isSelected) {
                                    selectedIds.remove(m.id);
                                  } else {
                                    selectedIds.add(m.id!);
                                  }
                                });
                              } else {
                                notifier.selectMeasurement(m);
                              }
                            },
                            onLongClick: () {
                              if (!isSelectionMode) {
                                setState(() {
                                  selectedIds = {m.id!};
                                  isSelectionMode = true;
                                });
                              }
                            },
                            onDelete: () {
                              notifier.deleteMeasurement(m);
                              setState(() {
                                selectedIds.clear();
                                isSelectionMode = false;
                              });
                            },
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                      if (twMeasurements.isNotEmpty) ...[
                        Text(
                          'Twist Weight (kg·cm²)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        ...twMeasurements.asMap().entries.map((entry) {
                          final index = entry.key;
                          final m = entry.value;
                          final isSelected = selectedIds.contains(m.id);
                          return MeasurementItem(
                            measurement: m,
                            selected: isSelected,
                            index: twMeasurements.length - index,
                            resolution: uiState.moiUnitsResolution,
                            periodResolution: uiState.periodUnitsResolution,
                            averageVal: uiState.currentTWAverage,
                            hideUnits: true,
                            fitThreshold: uiState.fitResidualExclusion,
                            margin: uiState.twMargin,
                            trimLast: uiState.trimLastCycle,
                            onClick: () {
                              if (isSelectionMode) {
                                setState(() {
                                  if (isSelected) {
                                    selectedIds.remove(m.id);
                                  } else {
                                    selectedIds.add(m.id!);
                                  }
                                });
                              } else {
                                notifier.selectMeasurement(m);
                              }
                            },
                            onLongClick: () {
                              if (!isSelectionMode) {
                                setState(() {
                                  selectedIds = {m.id!};
                                  isSelectionMode = true;
                                });
                              }
                            },
                            onDelete: () {
                              notifier.deleteMeasurement(m);
                              setState(() {
                                selectedIds.clear();
                                isSelectionMode = false;
                              });
                            },
                          );
                        }),
                      ],
                    ],
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
