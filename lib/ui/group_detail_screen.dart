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
      onPopInvoked: (didPop) {
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

                const SizedBox(height: 10),

                // Centered Tare Button with Info Button on Far Right
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: PopupMenuButton<String>(
                        initialValue: uiState.selectedTareMode,
                        onSelected: (mode) => notifier.setTareMode(mode),
                        child: Container(
                          height: 40,
                          width: 170,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Tare: $tareLabel',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'NONE', child: Text('None')),
                          PopupMenuItem(
                            value: 'PICKLEBALL',
                            enabled: uiState.pickleballTareOffset > 0,
                            child: Text(uiState.pickleballTareOffset > 0 ? 'Pickleball Adapter' : 'PB-Tare Adapter First'),
                          ),
                          PopupMenuItem(
                            value: 'TWIST',
                            enabled: uiState.twistTareOffset > 0,
                            child: Text(uiState.twistTareOffset > 0 ? 'Twist Weight Adapter' : 'TW-Tare Adapter First'),
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => notifier.selectEditingAttributesGroup(widget.groupId),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'i',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (isSelectionMode) ...[
                  SelectionTopBar(
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
                  ),
                ] else ...[
                  MeasurementControlButton(
                    state: uiState.detectorState,
                    progress: uiState.progress,
                    isCalibrated: uiState.isCalibrated,
                    cooldownRemaining: uiState.cooldownRemaining,
                    preparationRemaining: uiState.preparationRemaining,
                    onStart: () => notifier.startMeasurement(),
                  ),
                ],

                const SizedBox(height: 8),

                Expanded(
                  child: ListView(
                    children: [
                      if (swMeasurements.isNotEmpty) ...[
                        Text(
                          'Swing Weight (SW)',
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
                          'Twist Weight (TW)',
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
