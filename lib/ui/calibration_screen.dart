import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
        : 'No Data';

    final displayI = uiState.isCalibrated
        ? uiState.deviceInertia.toStringAsFixed(4)
        : 'No Data';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Exit OpenMOI?'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            'Device Calibration',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                          const Spacer(),
                          Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              icon: const Icon(Icons.nfc, size: 22),
                              label: const Text('Read NFC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              onPressed: () => notifier.setNfcScanning(true),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text('Known Calibration Objects', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),

                    CalibrationObjectCard(
                      title: 'Object A',
                      measurements: uiState.measurementsA,
                      fitThreshold: uiState.fitResidualExclusion,
                      trimLast: uiState.trimLastCycle,
                      periodResolution: uiState.periodUnitsResolution,
                      isTareCard: false,
                      onClick: () => notifier.selectCalibrationTarget(CalibrationTarget.OBJECT_A),
                    ),

                    CalibrationObjectCard(
                      title: 'Object B',
                      measurements: uiState.measurementsB,
                      fitThreshold: uiState.fitResidualExclusion,
                      trimLast: uiState.trimLastCycle,
                      periodResolution: uiState.periodUnitsResolution,
                      isTareCard: false,
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

                    const SizedBox(height: 12),

                    Text('Calibration Objects MOI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),

                    Card(
                      color: theme.colorScheme.surfaceVariant,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Object A (kg·cm²)', style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
                                SizedBox(
                                  width: 140,
                                  height: 38,
                                  child: TextField(
                                    controller: _knownAController,
                                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.end,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    ),
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
                            Divider(height: 12, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Object B (kg·cm²)', style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
                                SizedBox(
                                  width: 140,
                                  height: 38,
                                  child: TextField(
                                    controller: _knownBController,
                                    style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    textAlign: TextAlign.end,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: theme.colorScheme.surface,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    ),
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
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text('Derived Device Parameters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),

                    Card(
                      color: theme.colorScheme.surfaceVariant,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Column(
                          children: [
                            ReadOnlySettingField(
                              label: 'Spring Constant (kg·cm/rad)',
                              value: displayKappa,
                              width: 160,
                              onLongClick: () {
                                if (uiState.isCalibrated) {
                                  final numStr = (uiState.deviceKappa / MomentOfInertiaCalculator.kappaConversion).toString();
                                  Clipboard.setData(ClipboardData(text: numStr));
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied Spring Constant: $numStr')));
                                }
                              },
                            ),
                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                            ReadOnlySettingField(
                              label: 'Device Inertia (kg·cm²)',
                              value: displayI,
                              width: 160,
                              onLongClick: () {
                                if (uiState.isCalibrated) {
                                  final numStr = uiState.deviceInertia.toString();
                                  Clipboard.setData(ClipboardData(text: numStr));
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied Device Inertia: $numStr')));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text('Tare Adapters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const SizedBox(height: 4),

                    CalibrationObjectCard(
                      title: 'Pickleball Adapter',
                      measurements: uiState.measurementsTarePB,
                      fitThreshold: uiState.fitResidualExclusion,
                      trimLast: uiState.trimLastCycle,
                      periodResolution: uiState.periodUnitsResolution,
                      moiResolution: uiState.moiUnitsResolution,
                      isTareCard: true,
                      onClick: () => notifier.selectCalibrationTarget(CalibrationTarget.TARE_PB),
                    ),

                    CalibrationObjectCard(
                      title: 'Twist Weight Adapter',
                      measurements: uiState.measurementsTareTW,
                      fitThreshold: uiState.fitResidualExclusion,
                      trimLast: uiState.trimLastCycle,
                      periodResolution: uiState.periodUnitsResolution,
                      moiResolution: uiState.moiUnitsResolution,
                      isTareCard: true,
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
  final int moiResolution;
  final bool isTareCard;
  final VoidCallback onClick;

  const CalibrationObjectCard({
    super.key,
    required this.title,
    required this.measurements,
    required this.fitThreshold,
    required this.trimLast,
    required this.periodResolution,
    this.moiResolution = 2,
    this.isTareCard = false,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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

    double periodStdDev = 0.0;
    if (mPeriods.length > 1) {
      final variance = mPeriods.map((p) => pow(p - avgPeriod, 2)).reduce((a, b) => a + b) / mPeriods.length;
      periodStdDev = sqrt(variance);
    }

    if (!isTareCard) {
      final periodText = filtered.isEmpty || avgPeriod <= 0
          ? 'Period: No Data'
          : 'Period: ${avgPeriod.toStringAsFixed(periodResolution)}';
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 1.0),
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DynamicTitleText(
                        text: title,
                        maxFontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: theme.colorScheme.outline,
                    ),
                  ],
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

    final periodStr = filtered.isNotEmpty && avgPeriod > 0
        ? avgPeriod.toStringAsFixed(periodResolution)
        : 'No Data';

    final moiValues = filtered.map((m) => m.moi).toList();
    final avgMoi = moiValues.isNotEmpty ? moiValues.reduce((a, b) => a + b) / moiValues.length : 0.0;
    double moiStdDev = 0.0;
    if (moiValues.length > 1) {
      final variance = moiValues.map((v) => pow(v - avgMoi, 2)).reduce((a, b) => a + b) / moiValues.length;
      moiStdDev = sqrt(variance);
    }

    final moiStr = moiValues.isNotEmpty && avgMoi > 0
        ? avgMoi.toStringAsFixed(moiResolution)
        : 'No Data';

    final metaStr = 'Readings: ${measurements.length}';

    final swBg = isDark ? const Color(0xFF172836) : const Color(0xFFE8F4FD);
    final twBg = isDark ? const Color(0xFF0F2E2B) : const Color(0xFFE0F2F1);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 1.5),
      child: InkWell(
        onTap: onClick,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: DynamicTitleText(
                      text: title,
                      maxFontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: swBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text('Period: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                          Expanded(
                            child: Text(
                              periodStr,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: twBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text('MOI: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                          Expanded(
                            child: Text(
                              moiStr,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  metaStr,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.outline, height: 1.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
