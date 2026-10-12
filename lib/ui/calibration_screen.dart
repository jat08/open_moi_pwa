import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../logic/moi_calculator.dart';
import '../providers/moi_provider.dart';
import 'calibration_detail_screen.dart';
import 'calibration_info_screen.dart';
import 'components.dart';
import 'measurement_detail_screen.dart';

class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  late TextEditingController _knownAController;
  late TextEditingController _knownBController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(moiProvider);
    _knownAController = TextEditingController(text: state.knownObjectAInertia.toString().replaceAll(RegExp(r'\.0$'), ''));
    _knownBController = TextEditingController(text: state.knownObjectBInertia.toString().replaceAll(RegExp(r'\.0$'), ''));
  }

  @override
  void dispose() {
    _knownAController.dispose();
    _knownBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<UiState>(moiProvider, (previous, next) {
      if (previous?.knownObjectAInertia != next.knownObjectAInertia) {
        final str = next.knownObjectAInertia.toString().replaceAll(RegExp(r'\.0$'), '');
        if (_knownAController.text != str) {
          _knownAController.text = str;
        }
      }
      if (previous?.knownObjectBInertia != next.knownObjectBInertia) {
        final str = next.knownObjectBInertia.toString().replaceAll(RegExp(r'\.0$'), '');
        if (_knownBController.text != str) {
          _knownBController.text = str;
        }
      }
    });

    final uiState = ref.watch(moiProvider);
    final notifier = ref.read(moiProvider.notifier);
    final theme = Theme.of(context);

    if (uiState.editingExpectedValueTarget != null) {
      return CalibrationInfoScreen(target: uiState.editingExpectedValueTarget!);
    } else if (uiState.selectedMeasurement != null) {
      return MeasurementDetailScreen(measurement: uiState.selectedMeasurement!);
    } else if (uiState.selectedCalibrationTarget != null) {
      return CalibrationDetailScreen(target: uiState.selectedCalibrationTarget!);
    }

    final displayKappa = uiState.isCalibrated
        ? (uiState.deviceKappa / MomentOfInertiaCalculator.kappaConversion).toStringAsFixed(4)
        : '0.0000';

    final displayI = uiState.isCalibrated
        ? uiState.deviceInertia.toStringAsFixed(4)
        : '0.0';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      'Device Calibration',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ),

                  Text('Calibration Objects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),

                  CalibrationObjectCard(
                    title: 'Object A',
                    measurements: uiState.measurementsA,
                    fitThreshold: uiState.fitResidualExclusion,
                    trimLast: uiState.trimLastCycle,
                    periodResolution: uiState.periodUnitsResolution,
                    onClick: () => notifier.selectCalibrationTarget(CalibrationTarget.OBJECT_A),
                  ),

                  CalibrationObjectCard(
                    title: 'Object B',
                    measurements: uiState.measurementsB,
                    fitThreshold: uiState.fitResidualExclusion,
                    trimLast: uiState.trimLastCycle,
                    periodResolution: uiState.periodUnitsResolution,
                    onClick: () => notifier.selectCalibrationTarget(CalibrationTarget.OBJECT_B),
                  ),

                  if (uiState.measurementsA.isNotEmpty || uiState.measurementsB.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => DeleteConfirmationDialog(
                              title: 'Recalibrate?',
                              text: 'This will delete all measurements for both Object A and Object B. Are you sure?',
                              onConfirm: () => notifier.recalibrate(),
                            ),
                          );
                        },
                        child: const Text('Recalibrate', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  Text('Calibration Objects MOI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Object A (kg·cm²)', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface)),
                      SizedBox(
                        width: 160,
                        height: 40,
                        child: TextField(
                          controller: _knownAController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                          onChanged: (val) {
                            final d = double.tryParse(val);
                            if (d != null) {
                              notifier.prefs.saveKnownObjectAInertia(d);
                              notifier.loadPreferences();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Object B (kg·cm²)', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface)),
                      SizedBox(
                        width: 160,
                        height: 40,
                        child: TextField(
                          controller: _knownBController,
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                          onChanged: (val) {
                            final d = double.tryParse(val);
                            if (d != null) {
                              notifier.prefs.saveKnownObjectBInertia(d);
                              notifier.loadPreferences();
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                      onPressed: () => notifier.setNfcScanning(true),
                      child: Text('Read NFC', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text('Derived Device Parameters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),

                  ReadOnlySettingField(
                    label: 'Spring Constant (kg·cm/rad)',
                    value: displayKappa,
                    onLongClick: () {
                      if (uiState.isCalibrated) {
                        final numStr = (uiState.deviceKappa / MomentOfInertiaCalculator.kappaConversion).toString();
                        Clipboard.setData(ClipboardData(text: numStr));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied Spring Constant: $numStr')));
                      }
                    },
                  ),
                  ReadOnlySettingField(
                    label: 'Device Inertia (kg·cm²)',
                    value: displayI,
                    onLongClick: () {
                      if (uiState.isCalibrated) {
                        final numStr = uiState.deviceInertia.toString();
                        Clipboard.setData(ClipboardData(text: numStr));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied Device Inertia: $numStr')));
                      }
                    },
                  ),

                  const SizedBox(height: 10),

                  Text('Tare Adapters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),

                  CalibrationObjectCard(
                    title: 'Pickleball Adapter',
                    measurements: uiState.measurementsTarePB,
                    fitThreshold: uiState.fitResidualExclusion,
                    trimLast: uiState.trimLastCycle,
                    periodResolution: uiState.periodUnitsResolution,
                    onClick: () => notifier.selectCalibrationTarget(CalibrationTarget.TARE_PB),
                  ),

                  CalibrationObjectCard(
                    title: 'Twist Weight Adapter',
                    measurements: uiState.measurementsTareTW,
                    fitThreshold: uiState.fitResidualExclusion,
                    trimLast: uiState.trimLastCycle,
                    periodResolution: uiState.periodUnitsResolution,
                    onClick: () => notifier.selectCalibrationTarget(CalibrationTarget.TARE_TW),
                  ),

                  if (uiState.measurementsTarePB.isNotEmpty || uiState.measurementsTareTW.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => DeleteConfirmationDialog(
                              title: 'Re-Tare?',
                              text: 'This will delete all measurements for both Tare adapters. Are you sure?',
                              onConfirm: () => notifier.reTare(),
                            ),
                          );
                        },
                        child: const Text('Re-Tare', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),

            if (uiState.isNfcScanning || uiState.nfcStatus != null)
              Container(
                color: Colors.black54,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Material(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'NFC Calibration',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          uiState.nfcStatus ?? 'Ready to Scan...',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
                        ),
                        if (uiState.isNfcScanning) ...[
                          const SizedBox(height: 24),
                          CircularProgressIndicator(color: theme.colorScheme.primary),
                        ],
                        const SizedBox(height: 24),
                        if (!uiState.nfcEnabled) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              onPressed: () {
                                notifier.openNfcSettings();
                                notifier.setNfcScanning(false);
                              },
                              child: const Text('Open System Settings'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => notifier.setNfcScanning(false),
                            child: Text(!uiState.nfcEnabled ? 'Cancel' : 'Close'),
                          ),
                        ),
                      ],
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

class CalibrationObjectCard extends StatelessWidget {
  final String title;
  final List<Measurement> measurements;
  final double fitThreshold;
  final bool trimLast;
  final int periodResolution;
  final VoidCallback onClick;

  const CalibrationObjectCard({
    super.key,
    required this.title,
    required this.measurements,
    required this.fitThreshold,
    required this.trimLast,
    required this.periodResolution,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = measurements.where((m) => m.fitResidual < fitThreshold).toList();

    final mPeriods = filtered.map((m) {
      final cycles = m.cyclePeriods.split(',').where((s) => s.isNotEmpty).map((s) => double.tryParse(s) ?? 0.0).toList();
      if (trimLast && cycles.length > 1) {
        return cycles.sublist(0, cycles.length - 1).reduce((a, b) => a + b) / (cycles.length - 1);
      } else if (cycles.isNotEmpty) {
        return cycles.reduce((a, b) => a + b) / cycles.length;
      } else {
        return m.period;
      }
    }).toList();

    final avgPeriod = mPeriods.isNotEmpty ? mPeriods.reduce((a, b) => a + b) / mPeriods.length : 0.0;

    double stdDev = 0.0;
    if (mPeriods.length > 1) {
      final variance = mPeriods.map((p) => pow(p - avgPeriod, 2)).reduce((a, b) => a + b) / mPeriods.length;
      stdDev = sqrt(variance);
    }

    final periodText = 'Period: ${avgPeriod.toStringAsFixed(periodResolution)} ± ${stdDev.toStringAsFixed(periodResolution)}s';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.symmetric(vertical: 1.0),
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DynamicTitleText(
                text: title,
                maxFontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(periodText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary, height: 1.1)),
                  Text('Readings: ${measurements.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.outline, height: 1.0)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
