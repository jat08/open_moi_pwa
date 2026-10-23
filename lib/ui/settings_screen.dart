import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_version.dart';
import '../data/app_preferences.dart';
import '../providers/moi_provider.dart';
import 'components.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final durationRange = List.generate(100, (i) => (i + 1) / 10.0);
  final waitRange = List.generate(10, (i) => (i + 1).toDouble());
  final cyclesRange = List.generate(7, (i) => (i + 4).toDouble());
  final skipRange = List.generate(5, (i) => i.toDouble());
  final prepRange = List.generate(11, (i) => i.toDouble());
  final marginRange = List.generate(50, (i) => (i + 1) / 1000.0);
  final fitExclusionRange = List.generate(19, (i) => (i + 2) / 2.0); // 1.0 to 10.0 in 0.5 steps

  String getExportFilename(String base) {
    final stamp = DateFormat('MM-dd-yy_HH-mm-ss').format(DateTime.now());
    return '${base}_$stamp.csv';
  }

  Future<void> _exportCsv(String type) async {
    final notifier = ref.read(moiProvider.notifier);
    String csvContent;
    String baseName;

    if (type == 'MEASURE') {
      csvContent = await notifier.exportMeasureToCsv();
      baseName = 'Measurements';
    } else {
      csvContent = await notifier.exportEstimateToCsv();
      baseName = 'Estimations';
    }

    final filename = getExportFilename(baseName);
    final bytes = Uint8List.fromList(utf8.encode(csvContent));

    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: filename, mimeType: 'text/csv')],
        subject: filename,
      );
      return;
    }

    try {
      final outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Export CSV',
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );

      if (outputFile != null) {
        if (!outputFile.startsWith('content://')) {
          try {
            final savedFile = File(outputFile);
            if (!await savedFile.exists() || (await savedFile.length()) == 0) {
              await savedFile.writeAsString(csvContent);
            }
          } catch (_) {}
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved $filename successfully.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
          ),
        );
      }
    }
  }

  Future<void> _importCsv(String type) async {
    final notifier = ref.read(moiProvider.notifier);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: kIsWeb,
    );

    if (result != null) {
      String? content;
      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          content = utf8.decode(bytes);
        }
      } else if (result.files.single.path != null) {
        final file = File(result.files.single.path!);
        content = await file.readAsString();
      }

      if (content != null) {
        if (type == 'MEASURE') {
          await notifier.importMeasureFromCsv(content);
        } else {
          await notifier.importEstimateFromCsv(content);
        }
      }
    }
  }

  void _showSettingDescription(BuildContext context, String title, String description) {
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
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

  Widget _settingLabel(String title, String description) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showSettingDescription(context, title, description),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(moiProvider);
    final notifier = ref.read(moiProvider.notifier);
    final theme = Theme.of(context);

    if (uiState.importError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Error'),
            content: Text(uiState.importError!),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  notifier.clearImportError();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }

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
                    'Settings',
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          "Tap any setting's name for more info.",
                          style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
                        ),
                      ),

                      Text('Theme & Display', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(height: 4),

                      Card(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Theme Mode', 'Controls the visual appearance of the application. Choose Light mode, Dark mode, or follow your System settings.'),
                                    ItemWheelPicker<AppThemeMode>(
                                      value: uiState.themeMode,
                                      options: AppThemeMode.values,
                                      title: 'Theme Mode',
                                      displayLabel: (mode) {
                                        switch (mode) {
                                          case AppThemeMode.SYSTEM:
                                            return 'System';
                                          case AppThemeMode.LIGHT:
                                            return 'Light';
                                          case AppThemeMode.DARK:
                                            return 'Dark';
                                        }
                                      },
                                      onValueChange: (mode) {
                                        notifier.prefs.saveThemeMode(mode);
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('MOI Units Resolution', 'Specifies the number of decimal places displayed for Moment of Inertia (MOI) values throughout the app (0 to 4 decimal places).'),
                                    ItemWheelPicker<int>(
                                      value: uiState.moiUnitsResolution,
                                      options: const [0, 1, 2, 3, 4],
                                      title: 'MOI Units Resolution',
                                      displayLabel: (res) {
                                        if (res == 0) return '0';
                                        return '0.${'0' * res}';
                                      },
                                      onValueChange: (res) {
                                        notifier.prefs.saveMoiUnitsResolution(res);
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Period Units Resolution', 'Specifies the number of decimal places displayed for period timing values in seconds (1 to 6 decimal places).'),
                                    ItemWheelPicker<int>(
                                      value: uiState.periodUnitsResolution,
                                      options: const [1, 2, 3, 4, 5, 6],
                                      title: 'Period Units Resolution',
                                      displayLabel: (res) {
                                        return '0.${'0' * res}';
                                      },
                                      onValueChange: (res) {
                                        notifier.prefs.savePeriodUnitsResolution(res);
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Keep Screen On', 'Prevents your device screen from turning off or sleeping while using OpenMOI.'),
                                    ItemWheelPicker<bool>(
                                      value: uiState.keepScreenOn,
                                      options: const [true, false],
                                      title: 'Keep Screen On',
                                      displayLabel: (val) => val ? 'Yes' : 'No',
                                      onValueChange: (val) {
                                        notifier.prefs.saveKeepScreenOn(val);
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text('Measurement Control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(height: 4),

                      Card(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Measurement Duration\n(seconds)', 'The amount of time in seconds the sensor records motion data for each measurement cycle. This setting is inter-dependent with Cycles to Measure: measurement data collection will conclude as soon as either this time duration elapses OR the required number of cycles occurs first.'),
                                    NumberWheelPicker(
                                      value: uiState.measuringDuration,
                                      range: durationRange,
                                      title: 'Measurement Duration',
                                      onValueChange: (v) {
                                        notifier.prefs.saveMeasuringDuration(v);
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Wait After Measurement\n(seconds)', 'The cooldown delay in seconds after a measurement completes before the system is ready for the next reading.'),
                                    NumberWheelPicker(
                                      value: uiState.waitDuration,
                                      range: waitRange,
                                      format: '%.0f',
                                      title: 'Wait After Measurement',
                                      onValueChange: (v) {
                                        notifier.prefs.saveWaitDuration(v);
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Cycles to Measure', 'The total number of full oscillation cycles counted and included during data collection. This setting is inter-dependent with Measurement Duration: measurement concludes as soon as either the required cycle count is reached OR the time duration expires first. Cycle Reference selection is also constrained by this value.'),
                                    NumberWheelPicker(
                                      value: uiState.cyclesToMeasure.toDouble(),
                                      range: cyclesRange,
                                      format: '%.0f',
                                      title: 'Cycles to Measure',
                                      onValueChange: (v) {
                                        notifier.prefs.saveCyclesToMeasure(v.toInt());
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Trim Last Cycle', 'Automatically discards the final oscillation cycle from calculations to eliminate noise or damping artifacts at the end of a run.'),
                                    ItemWheelPicker<bool>(
                                      value: uiState.trimLastCycle,
                                      options: const [true, false],
                                      title: 'Trim Last Cycle',
                                      displayLabel: (val) => val ? 'Yes' : 'No',
                                      onValueChange: (val) {
                                        notifier.prefs.saveTrimLastCycle(val);
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Skip First Cycles', 'Ignores the specified number of initial oscillation cycles to allow the system to settle before recording data. Inter-dependent with Cycles to Measure and Measurement Duration: initial cycles are skipped prior to counting valid cycles toward the required total, and recording ends when required cycles or duration completes first.'),
                                    NumberWheelPicker(
                                      value: uiState.skipFirstCycles.toDouble(),
                                      range: skipRange,
                                      format: '%.0f',
                                      title: 'Skip First Cycles',
                                      onValueChange: (v) {
                                        notifier.prefs.saveSkipFirstCycles(v.toInt());
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Cycle Reference', 'Designates a specific cycle index as the reference benchmark for deviation comparison, or 0 to use the overall mean period. Inter-dependent with Cycles to Measure: the range of selectable reference cycle indices is constrained up to the total Cycles to Measure configured.'),
                                    NumberWheelPicker(
                                      value: uiState.cycleReference.toDouble(),
                                      range: List.generate(uiState.cyclesToMeasure + 1, (i) => i.toDouble()),
                                      format: '%.0f',
                                      title: 'Cycle Reference',
                                      onValueChange: (v) {
                                        notifier.prefs.saveCycleReference(v.toInt());
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Apply Optimization', 'When enabled, applies a pure-Dart Levenberg-Marquardt non-linear least squares optimizer to fit recorded gyroscope data to a damped sine wave, analytically yielding highly precise periods resistant to noise and phase shift. If curve fitting fails, the measurement is rejected in strict mode.'),
                                    ItemWheelPicker<bool>(
                                      value: uiState.applyOptimization,
                                      options: const [true, false],
                                      title: 'Apply Optimization',
                                      displayLabel: (b) => b ? "Yes" : "No",
                                      onValueChange: (v) {
                                        notifier.setApplyOptimization(v);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Preparation Time\n(seconds)', 'A countdown period in seconds after tapping Start before the device begins arming and detecting oscillations.'),
                                    NumberWheelPicker(
                                      value: uiState.preparationTime.toDouble(),
                                      range: prepRange,
                                      format: '%.0f',
                                      title: 'Preparation Time',
                                      onValueChange: (v) {
                                        notifier.prefs.savePreparationTime(v.toInt());
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Low Margin', 'The maximum allowable percentage variation threshold applied to Swing Weight (SW) and low inertia measurements (including Object A calibration). Measurements whose value deviates from the group mean by more than this percentage margin are highlighted as statistical outliers.'),
                                    NumberWheelPicker(
                                      value: uiState.swMargin,
                                      range: marginRange,
                                      format: '%.1f%%',
                                      multiplyBy: 100.0,
                                      title: 'Low Margin',
                                      onValueChange: (v) {
                                        notifier.prefs.saveSwMargin(v);
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('High Margin', 'The maximum allowable percentage variation threshold applied to Twist Weight (TW) and high inertia measurements (including Object B calibration). Measurements whose value deviates from the group mean by more than this percentage margin are highlighted as statistical outliers.'),
                                    NumberWheelPicker(
                                      value: uiState.twMargin,
                                      range: marginRange,
                                      format: '%.1f%%',
                                      multiplyBy: 100.0,
                                      title: 'High Margin',
                                      onValueChange: (v) {
                                        notifier.prefs.saveTwMargin(v);
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 8, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _settingLabel('Fit Residual Exclusion', 'The threshold for sine-wave fit quality. Measurements with a fit residual equal to or exceeding this threshold are marked as poor fit quality. It is best to keep this setting at 1.5 for optimal accuracy.'),
                                    NumberWheelPicker(
                                      value: uiState.fitResidualExclusion,
                                      range: fitExclusionRange,
                                      format: '%.1f',
                                      title: 'Fit Residual Exclusion',
                                      onValueChange: (v) {
                                        notifier.prefs.saveFitResidualExclusion(v);
                                        notifier.loadPreferences();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
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
                                            const Text('Export CSV', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 12),
                                            const Text('Select database to export.', style: TextStyle(fontSize: 15)),
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
                                                      onPressed: () {
                                                        Navigator.of(ctx).pop();
                                                        _exportCsv('MEASURE');
                                                      },
                                                      child: const Text('Measure DB'),
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
                                                        Navigator.of(ctx).pop();
                                                        _exportCsv('ESTIMATE');
                                                      },
                                                      child: const Text('Estimate DB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                                icon: const Icon(Icons.download_for_offline, size: 18),
                                label: const Text('Import', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
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
                                            const Text('Import CSV', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                            const SizedBox(height: 12),
                                            const Text('Select which database to import. Data will be appended.', style: TextStyle(fontSize: 15), textAlign: TextAlign.center),
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
                                                      onPressed: () {
                                                        Navigator.of(ctx).pop();
                                                        _importCsv('MEASURE');
                                                      },
                                                      child: const Text('Measure DB'),
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
                                                        Navigator.of(ctx).pop();
                                                        _importCsv('ESTIMATE');
                                                      },
                                                      child: const Text('Estimate DB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Center(
                        child: GestureDetector(
                          onTap: () async {
                            final uri = Uri.parse('https://jat08.github.io/OpenMOI-Home/');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Text.rich(
                            TextSpan(
                              text: 'For more information, visit ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.outline,
                              ),
                              children: [
                                TextSpan(
                                  text: 'OpenMOI',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          AppVersion.fullVersionNote,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),

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
