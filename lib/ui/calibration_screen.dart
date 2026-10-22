import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/theme/page_typography.dart';
import '../data/models.dart';
import '../logic/moi_calculator.dart';
import '../logic/web_helper.dart';
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

  void _showSectionDescription(BuildContext context, String title, String description) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OneUiDragHandle(),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showCalibrationGuideDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OneUiDragHandle(),
              const SizedBox(height: 4),
              const Text(
                'How to Calibrate Device',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Text(
                '1. Prepare 2 Calibration Objects:\n'
                'You will need two objects (Object A and Object B) with known, distinct Moment of Inertia (MOI) values. Object A should be a low inertia object (preferably under 25 kg·cm²), and Object B should be a high inertia object (preferably over 140 kg·cm²).\n\n'
                '2. Enter Known MOI Values:\n'
                'Scroll to the "Calibration Objects MOI" section below and enter the known MOI values in the corresponding Object A (kg·cm²) and Object B (kg·cm²) fields.\n\n'
                '3. Perform Period Measurements:\n'
                'Tap the Object A and Object B cards to open the measurement screen and collect period data for both objects.\n\n'
                '4. Automatic Calculation:\n'
                'Once valid period measurements are recorded for both objects, OpenMOI automatically calculates the device spring constant (K) and internal device inertia (I).',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 14.5, height: 1.35, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showTareGuideDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const OneUiDragHandle(),
              const SizedBox(height: 4),
              const Text(
                'How to Tare Adapters',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Text(
                '1. Prepare Tare Adapters:\n'
                'Attach the Pickleball or Twist Weight adapter to your device without any paddle installed.\n\n'
                '2. Measure Empty Adapter Period:\n'
                'Tap the Pickleball Adapter or Twist Weight Adapter card below to open the detail screen and record oscillation measurements for the empty adapter.\n\n'
                '3. Automatic Tare Offset Calculation:\n'
                'OpenMOI automatically calculates the tare offset inertia for each adapter using the calibrated device spring constant and device inertia.\n\n'
                '4. Automatic Inertia Subtraction:\n'
                'When measuring paddles on the Measure page, selecting the active Tare Adapter mode will automatically subtract the adapter\'s inertia from your total measurement.',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 14.5, height: 1.35, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startNfcScan(BuildContext context, MoiNotifier notifier) async {
    final theme = Theme.of(context);
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC tag reading is supported on Android devices.')),
      );
      return;
    }

    const channel = MethodChannel('com.openmoi.open_moi_cp/nfc');

    try {
      final bool available = await channel.invokeMethod('isNfcAvailable') ?? false;
      if (!available) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('NFC Unavailable'),
              content: const Text('NFC is disabled or not available on this device. Please enable NFC in system settings.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    channel.invokeMethod('openNfcSettings');
                  },
                  child: const Text('Settings'),
                ),
              ],
            ),
          );
        }
        return;
      }

      await channel.invokeMethod('enableNfc');

      bool isScanning = true;

      channel.setMethodCallHandler((call) async {
        if (call.method == 'onNfcScanned') {
          final List<dynamic>? rawRecords = call.arguments as List<dynamic>?;
          if (rawRecords != null && rawRecords.isNotEmpty && isScanning) {
            isScanning = false;
            await channel.invokeMethod('disableNfc');
            if (context.mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }

            bool updated = false;
            for (final record in rawRecords) {
              final str = record.toString();
              final clean = str.toUpperCase().replaceAll(' ', '');
              final numMatch = RegExp(r'[-+]?[0-9]*\.?[0-9]+').firstMatch(str);
              if (numMatch != null) {
                final value = double.tryParse(numMatch.group(0)!);
                if (value != null) {
                  if (clean.startsWith('OBJAT')) {
                    await notifier.prefs.saveExpectedValue('OBJECT_A', value);
                    updated = true;
                  } else if (clean.startsWith('OBJBT')) {
                    await notifier.prefs.saveExpectedValue('OBJECT_B', value);
                    updated = true;
                  } else if (clean.startsWith('OBJA')) {
                    await notifier.prefs.saveKnownObjectAInertia(value);
                    updated = true;
                  } else if (clean.startsWith('OBJB')) {
                    await notifier.prefs.saveKnownObjectBInertia(value);
                    updated = true;
                  } else if (clean.startsWith('PB')) {
                    await notifier.prefs.saveExpectedValue('TARE_PB', value);
                    updated = true;
                  } else if (clean.startsWith('TW')) {
                    await notifier.prefs.saveExpectedValue('TARE_TW', value);
                    updated = true;
                  }
                }
              }
            }

            if (updated) {
              notifier.loadPreferences();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('NFC Calibration Data Updated Successfully!')),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No valid calibration records found on NFC tag.')),
                );
              }
            }
          }
        }
      });

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isDismissible: true,
          builder: (ctx) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const OneUiDragHandle(),
                  const SizedBox(height: 12),
                  Icon(Icons.nfc, size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  const Text('Ready to Scan NFC Tag', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Hold your device near the calibration NFC tag...',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      ),
                      onPressed: () {
                        isScanning = false;
                        channel.invokeMethod('disableNfc');
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).then((_) {
          if (isScanning) {
            isScanning = false;
            channel.invokeMethod('disableNfc');
          }
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('NFC Error: $e')),
        );
      }
    }
  }

  Widget _sectionHeader(BuildContext context, String title, String description) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showSectionDescription(context, title, description),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
      ),
    );
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

    final areAdaptersTared = uiState.measurementsTarePB.isNotEmpty && uiState.measurementsTareTW.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showModalBottomSheet<bool>(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            final isDark = theme.brightness == Brightness.dark;
            final sheetBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);
            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OneUiDragHandle(),
                    const SizedBox(height: 4),
                    const Text('Exit OpenMOI?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const Text('Are you sure you want to exit the app?', style: TextStyle(fontSize: 15)),
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
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('No'),
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
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
                  title: Text(
                    'Calibration',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    if (kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            icon: const Icon(Icons.sensors, size: 20),
                            label: const Text(
                              'Enable Motion and Orientation',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              notifier.requestPermission();
                            },
                          ),
                        ),
                      ),
                    ],

                    // Device Calibration Health Banner
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: uiState.isCalibrated
                            ? null
                            : () => _showCalibrationGuideDialog(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: uiState.isCalibrated
                                ? (theme.brightness == Brightness.dark ? const Color(0xFF003828) : const Color(0xFFE6F4EA))
                                : theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                uiState.isCalibrated ? Icons.check_circle : Icons.warning_amber_rounded,
                                color: uiState.isCalibrated ? const Color(0xFF34A853) : theme.colorScheme.onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  uiState.isCalibrated
                                      ? 'Device Calibrated'
                                      : 'Device Not Calibrated  •  Tap for Help',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: uiState.isCalibrated
                                        ? (theme.brightness == Brightness.dark ? const Color(0xFFA8FABD) : const Color(0xFF137333))
                                        : theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                              if (!uiState.isCalibrated) ...[
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.onErrorContainer,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        "Tap any section header for more info.",
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                      ),
                    ),

                    _sectionHeader(
                      context,
                      'Known Calibration Objects',
                      'Measure oscillation periods for two objects with distinct, known inertia to compute device spring constant and device inertia.\n\nNote: Updates to these calibration parameters will not affect existing measurements.',
                    ),
                    const SizedBox(height: 4),

                    CalibrationObjectCard(
                      title: 'Object A',
                      measurements: uiState.measurementsA,
                      fitThreshold: uiState.fitResidualExclusion,
                      trimLast: uiState.trimLastCycle,
                      periodResolution: uiState.periodUnitsResolution,
                      isTareCard: false,
                      onClick: () {
                        HapticFeedback.lightImpact();
                        notifier.selectCalibrationTarget(CalibrationTarget.OBJECT_A);
                      },
                    ),

                    CalibrationObjectCard(
                      title: 'Object B',
                      measurements: uiState.measurementsB,
                      fitThreshold: uiState.fitResidualExclusion,
                      trimLast: uiState.trimLastCycle,
                      periodResolution: uiState.periodUnitsResolution,
                      isTareCard: false,
                      onClick: () {
                        HapticFeedback.lightImpact();
                        notifier.selectCalibrationTarget(CalibrationTarget.OBJECT_B);
                      },
                    ),

                    if (uiState.measurementsA.isNotEmpty || uiState.measurementsB.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => DeleteConfirmationDialog(
                                title: 'Recalibrate?',
                                text: 'This will delete all measurements for both Object A and Object B. Are you sure?',
                                onConfirm: () => notifier.recalibrate(),
                              ),
                            );
                          },
                          child: const Text('Recalibrate', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    _sectionHeader(
                      context,
                      'Calibration Objects MOI',
                      'Enter the exact known moment of inertia values for Object A and Object B.\n\nNote: Updates to these calibration parameters will not affect existing measurements.',
                    ),
                    const SizedBox(height: 4),

                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text('Object A (kg·cm²)', style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 130),
                                    height: 38,
                                    child: TextField(
                                      controller: _knownAController,
                                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.end,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: theme.colorScheme.surface,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                                ),
                              ],
                            ),
                            Divider(height: 12, thickness: 0.5, color: theme.colorScheme.outline.withValues(alpha: 0.25)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text('Object B (kg·cm²)', style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 130),
                                    height: 38,
                                    child: TextField(
                                      controller: _knownBController,
                                      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.end,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: theme.colorScheme.surface,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    _sectionHeader(
                      context,
                      'Derived Device Parameters',
                      'Calculated spring constant and internal device inertia derived from Object A and Object B calibration measurements.\n\nNote: Updates to these calibration parameters will not affect existing measurements.',
                    ),
                    const SizedBox(height: 4),

                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Column(
                          children: [
                            ReadOnlySettingField(
                              label: 'Spring Constant\n(kg·cm/rad)',
                              value: displayKappa,
                              width: 130,
                              onLongClick: () {
                                if (uiState.isCalibrated) {
                                  HapticFeedback.lightImpact();
                                  final numStr = (uiState.deviceKappa / MomentOfInertiaCalculator.kappaConversion).toString();
                                  Clipboard.setData(ClipboardData(text: numStr));
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copied Spring Constant: $numStr')));
                                }
                              },
                            ),
                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withValues(alpha: 0.25)),
                            ReadOnlySettingField(
                              label: 'Device Inertia\n(kg·cm²)',
                              value: displayI,
                              width: 130,
                              onLongClick: () {
                                if (uiState.isCalibrated) {
                                  HapticFeedback.lightImpact();
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

                    const SizedBox(height: 14),

                    _sectionHeader(
                      context,
                      'Tare Adapters',
                      'Measure adapter periods so the system can automatically tare adapter inertia from paddle measurements.\n\nNote: Updates to these calibration parameters will not affect existing measurements.',
                    ),
                    const SizedBox(height: 4),

                    // Tare Adapters Health Banner
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showTareGuideDialog(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: areAdaptersTared
                                ? (theme.brightness == Brightness.dark ? const Color(0xFF003828) : const Color(0xFFE6F4EA))
                                : theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                areAdaptersTared ? Icons.check_circle : Icons.warning_amber_rounded,
                                color: areAdaptersTared ? const Color(0xFF34A853) : theme.colorScheme.onErrorContainer,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  areAdaptersTared
                                      ? 'Adapters Tared'
                                      : 'Adapters Not Tared  •  Tap for Help',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: areAdaptersTared
                                        ? (theme.brightness == Brightness.dark ? const Color(0xFFA8FABD) : const Color(0xFF137333))
                                        : theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                              if (!areAdaptersTared) ...[
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.onErrorContainer,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    CalibrationObjectCard(
                      title: 'Pickleball Adapter',
                      measurements: uiState.measurementsTarePB,
                      fitThreshold: uiState.fitResidualExclusion,
                      trimLast: uiState.trimLastCycle,
                      periodResolution: uiState.periodUnitsResolution,
                      moiResolution: uiState.moiUnitsResolution,
                      isTareCard: true,
                      onClick: () {
                        HapticFeedback.lightImpact();
                        notifier.selectCalibrationTarget(CalibrationTarget.TARE_PB);
                      },
                    ),

                    CalibrationObjectCard(
                      title: 'Twist Weight Adapter',
                      measurements: uiState.measurementsTareTW,
                      fitThreshold: uiState.fitResidualExclusion,
                      trimLast: uiState.trimLastCycle,
                      periodResolution: uiState.periodUnitsResolution,
                      moiResolution: uiState.moiUnitsResolution,
                      isTareCard: true,
                      onClick: () {
                        HapticFeedback.lightImpact();
                        notifier.selectCalibrationTarget(CalibrationTarget.TARE_TW);
                      },
                    ),

                    if (uiState.measurementsTarePB.isNotEmpty || uiState.measurementsTareTW.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => DeleteConfirmationDialog(
                                title: 'Re-Tare?',
                                text: 'This will delete all measurements for both Tare adapters. Are you sure?',
                                onConfirm: () => notifier.reTare(),
                              ),
                            );
                          },
                          child: const Text('Re-Tare', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    _sectionHeader(
                      context,
                      'Sensor Warm-Up',
                      'Runs high-frequency hardware motion sensors to warm up the device gyroscope ASIC to thermal equilibrium prior to taking high-precision calibration measurements.',
                    ),
                    const SizedBox(height: 4),

                    const SensorWarmUpCard(),

                    const SizedBox(height: 28),
                  ],
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

    if (!isTareCard) {
      final periodText = filtered.isEmpty || avgPeriod <= 0
          ? 'T: No Data'
          : 'T: ${avgPeriod.toStringAsFixed(periodResolution)}';
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(vertical: 2.0),
        child: InkWell(
          onTap: onClick,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

    final moiStr = moiValues.isNotEmpty && avgMoi > 0
        ? avgMoi.toStringAsFixed(moiResolution)
        : 'No Data';

    final fullPeriodStr = 'T: $periodStr';
    final fullMoiStr = 'MOI: $moiStr';

    final metaStr = 'Readings: ${measurements.length}';

    final swBg = isDark ? const Color(0xFF172836) : const Color(0xFFE8F4FD);
    final twBg = isDark ? const Color(0xFF0F2E2B) : const Color(0xFFE0F2F1);

    final typo = PageTypography.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - 28) / 2.0;
        final valueFontSize = typo.computeUnifiedSize(
          texts: [fullPeriodStr, fullMoiStr],
          maxFontSize: 16.0,
          maxWidth: halfWidth,
          fontWeight: FontWeight.bold,
        );

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.symmetric(vertical: 2.0),
          child: InkWell(
            onTap: onClick,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: swBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text('T: ', style: TextStyle(fontSize: valueFontSize * 0.88, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                              Expanded(
                                child: Text(
                                  periodStr,
                                  style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: twBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text('MOI: ', style: TextStyle(fontSize: valueFontSize * 0.88, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                              Expanded(
                                child: Text(
                                  moiStr,
                                  style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
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
      },
    );
  }
}

class SensorWarmUpCard extends StatefulWidget {
  const SensorWarmUpCard({super.key});

  @override
  State<SensorWarmUpCard> createState() => _SensorWarmUpCardState();
}

class _SensorWarmUpCardState extends State<SensorWarmUpCard> {
  bool _isWarmingUp = false;
  int _remainingSeconds = 30;
  static const int _totalSeconds = 30;
  Timer? _timer;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  void _startWarmUp() {
    HapticFeedback.lightImpact();
    setState(() {
      _isWarmingUp = true;
      _remainingSeconds = _totalSeconds;
    });

    if (kIsWeb) {
      registerWebMotionListener((gx, gy, gz, ax, ay, az, ts) {});
    } else {
      _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.fastestInterval).listen(
        (_) {},
        onError: (_) {},
        cancelOnError: false,
      );
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _stopWarmUp(completed: true);
      }
    });
  }

  void _stopWarmUp({bool completed = false}) {
    _timer?.cancel();
    _timer = null;

    if (kIsWeb) {
      unregisterWebMotionListener();
    } else {
      _gyroSub?.cancel();
      _gyroSub = null;
    }

    if (mounted) {
      setState(() {
        _isWarmingUp = false;
        _remainingSeconds = _totalSeconds;
      });

      if (completed) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sensor Warm-Up Complete! Gyroscope is at thermal equilibrium.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (kIsWeb) {
      unregisterWebMotionListener();
    } else {
      _gyroSub?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_totalSeconds - _remainingSeconds) / _totalSeconds;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            if (!_isWarmingUp) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.whatshot, color: theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sensor Warm-Up',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                        Text(
                          '30s high-frequency sensor active warm-up',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: kMultipurposeBarHeight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kMultipurposeBarRadius)),
                  ),
                  icon: const Icon(Icons.whatshot, size: 20),
                  label: const Text(
                    'Sensor Warm-Up',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _startWarmUp,
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.whatshot, color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Warming Up Sensors...',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                  Text(
                    '${_remainingSeconds}s',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _stopWarmUp(completed: false);
                  },
                  child: const Text('Cancel Warm-Up'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
