import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../providers/moi_provider.dart';
import 'components.dart';

class CalibrationDetailScreen extends ConsumerStatefulWidget {
  final CalibrationTarget target;

  const CalibrationDetailScreen({
    super.key,
    required this.target,
  });

  @override
  ConsumerState<CalibrationDetailScreen> createState() => _CalibrationDetailScreenState();
}

class _CalibrationDetailScreenState extends ConsumerState<CalibrationDetailScreen> {
  Set<int> selectedIds = {};
  bool isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(moiProvider);
    final notifier = ref.read(moiProvider.notifier);
    final theme = Theme.of(context);

    List<Measurement> measurements;
    String title;

    switch (widget.target) {
      case CalibrationTarget.OBJECT_A:
        measurements = uiState.measurementsA;
        title = 'Object A Calibration';
        break;
      case CalibrationTarget.OBJECT_B:
        measurements = uiState.measurementsB;
        title = 'Object B Calibration';
        break;
      case CalibrationTarget.TARE_PB:
        measurements = uiState.measurementsTarePB;
        title = 'Pickleball Adapter Tare';
        break;
      case CalibrationTarget.TARE_TW:
        measurements = uiState.measurementsTareTW;
        title = 'Twist Weight Adapter Tare';
        break;
      default:
        measurements = [];
        title = 'Details';
        break;
    }

    final isTare = widget.target == CalibrationTarget.TARE_PB || widget.target == CalibrationTarget.TARE_TW;

    Stats? moiStats;
    if (isTare) {
      final threshold = uiState.fitResidualExclusion;
      final moiValues = measurements.where((m) => m.fitResidual < threshold).map((m) => m.moi).toList();
      if (moiValues.isNotEmpty) {
        final avg = moiValues.reduce((a, b) => a + b) / moiValues.length;
        final variance = moiValues.map((v) => pow(v - avg, 2)).reduce((a, b) => a + b) / moiValues.length;
        moiStats = Stats(avg, sqrt(variance));
      }
    }

    String? expectedNote;
    switch (widget.target) {
      case CalibrationTarget.OBJECT_A:
      case CalibrationTarget.OBJECT_B:
        expectedNote = null;
        break;
      case CalibrationTarget.TARE_PB:
        expectedNote = 'Expected MOI: ${uiState.expectedMoiPB.toStringAsFixed(4)} kg·cm²';
        break;
      case CalibrationTarget.TARE_TW:
        expectedNote = 'Expected MOI: ${uiState.expectedMoiTW.toStringAsFixed(4)} kg·cm²';
        break;
      default:
        break;
    }

    return Scaffold(
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.15))),
          ),
          child: SafeArea(
            top: false,
            child: isSelectionMode
                ? SelectionTopBar(
                    count: selectedIds.length,
                    isAllSelected: selectedIds.length >= measurements.length && measurements.isNotEmpty,
                    isPartialSelected: selectedIds.isNotEmpty && selectedIds.length < measurements.length,
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
                    isCalibrated: !isTare ? true : uiState.isCalibrated,
                    cooldownRemaining: uiState.cooldownRemaining,
                    preparationRemaining: uiState.preparationRemaining,
                    onStart: () => notifier.startMeasurement(),
                    onCancel: () => notifier.cancelMeasurement(),
                    onRequestPermission: () => notifier.requestPermission(),
                  ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageBreadcrumb(paths: ['Calibrate', title]),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface, size: 28),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        notifier.selectCalibrationTarget(null);
                      },
                    ),
                    Expanded(
                      child: DynamicTitleText(
                        text: title,
                        maxFontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                SingleSummaryHeader(
                  label: 'Period',
                  avg: uiState.currentCalibrationPeriodAverage,
                  stdDev: uiState.currentCalibrationPeriodStdDev,
                  moiResolution: uiState.moiUnitsResolution,
                  periodResolution: uiState.periodUnitsResolution,
                  isPeriod: true,
                  inlineToleranceWithUnits: !isTare,
                  label2: isTare ? 'MOI' : null,
                  avg2: moiStats?.average ?? 0.0,
                  stdDev2: moiStats?.stdDev ?? 0.0,
                  expectedNote: expectedNote,
                  onInfoClick: isTare ? () => notifier.selectEditingExpectedValue(widget.target) : null,
                ),

                const SizedBox(height: 10),

                measurements.isEmpty
                    ? const EmptyStateCard(
                        icon: Icons.tune_outlined,
                        title: 'No Calibration Runs',
                        subtitle: 'Tap Start Measurement below to record data',
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: measurements.length,
                    itemBuilder: (context, index) {
                      final m = measurements[index];
                      final isSelected = selectedIds.contains(m.id);
                      final mIndex = measurements.length - index;

                      return Dismissible(
                        key: ValueKey<int>(m.id!),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 2.0),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(width: 6),
                              Icon(Icons.delete, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          HapticFeedback.mediumImpact();
                          return true;
                        },
                        onDismissed: (direction) {
                          notifier.deleteMeasurement(m);
                          setState(() {
                            selectedIds.clear();
                            isSelectionMode = false;
                          });
                        },
                        child: MeasurementItem(
                          measurement: m,
                          selected: isSelected,
                          index: mIndex,
                          resolution: uiState.moiUnitsResolution,
                          periodResolution: uiState.periodUnitsResolution,
                          averageVal: uiState.currentCalibrationPeriodAverage,
                          showType: false,
                          isPeriod: true,
                          fitThreshold: uiState.fitResidualExclusion,
                          margin: (widget.target == CalibrationTarget.TARE_PB || widget.target == CalibrationTarget.TARE_TW)
                              ? uiState.twMargin
                              : uiState.swMargin,
                          trimLast: uiState.trimLastCycle,
                          onClick: () {
                            if (isSelectionMode) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (isSelected) {
                                  selectedIds.remove(m.id);
                                } else {
                                  selectedIds.add(m.id!);
                                }
                              });
                            } else {
                              HapticFeedback.lightImpact();
                              notifier.selectMeasurement(m);
                            }
                          },
                          onLongClick: () {
                            HapticFeedback.mediumImpact();
                            if (!isSelectionMode) {
                              setState(() {
                                selectedIds = {m.id!};
                                isSelectionMode = true;
                              });
                            }
                          },
                        ),
                      );
                    },
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
