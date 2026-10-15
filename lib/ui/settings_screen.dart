import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
    bool savedToDownloads = false;

    if (Platform.isAndroid) {
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final pubFile = File('${downloadDir.path}/$filename');
          await pubFile.writeAsString(csvContent);
          savedToDownloads = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved to Downloads: $filename'),
              ),
            );
          }
        }
      } catch (_) {}
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$filename');
    await tempFile.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(tempFile.path)],
      subject: filename,
      text: savedToDownloads ? 'Saved $filename to Downloads.' : 'Exported CSV $filename:',
    );
  }

  Future<void> _importCsv(String type) async {
    final notifier = ref.read(moiProvider.notifier);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      if (type == 'MEASURE') {
        await notifier.importMeasureFromCsv(content);
      } else {
        await notifier.importEstimateFromCsv(content);
      }
    }
  }

  void _showSettingDescription(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(description, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 2),
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                ),
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
                  color: theme.colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                  color: theme.colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _settingLabel('Measurement Duration\n(seconds)', 'The amount of time in seconds the sensor records motion data for each measurement cycle.'),
                              NumberWheelPicker(
                                value: uiState.measuringDuration,
                                range: durationRange,
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
                              _settingLabel('Cycles to Measure', 'The total number of full oscillation cycles counted and included during data collection.'),
                              NumberWheelPicker(
                                value: uiState.cyclesToMeasure.toDouble(),
                                range: cyclesRange,
                                format: '%.0f',
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
                              _settingLabel('Skip First Cycles', 'Ignores the specified number of initial oscillation cycles to allow the system to settle before recording data.'),
                              NumberWheelPicker(
                                value: uiState.skipFirstCycles.toDouble(),
                                range: skipRange,
                                format: '%.0f',
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
                              _settingLabel('Cycle Reference', 'Designates a specific cycle index as the reference benchmark for deviation comparison, or 0 to use the overall mean period.'),
                              NumberWheelPicker(
                                value: uiState.cycleReference.toDouble(),
                                range: List.generate(uiState.cyclesToMeasure + 1, (i) => i.toDouble()),
                                format: '%.0f',
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
                              _settingLabel('Preparation Time\n(seconds)', 'A countdown period in seconds after tapping Start before the device begins arming and detecting oscillations.'),
                              NumberWheelPicker(
                                value: uiState.preparationTime.toDouble(),
                                range: prepRange,
                                format: '%.0f',
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
                              _settingLabel('Low Margin', 'The maximum allowable percentage variation threshold for Swing Weight (SW) / low inertia cycle periods before flagging an outlier.'),
                              NumberWheelPicker(
                                value: uiState.swMargin,
                                range: marginRange,
                                format: '%.1f%%',
                                multiplyBy: 100.0,
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
                              _settingLabel('High Margin', 'The maximum allowable percentage variation threshold for Twist Weight (TW) / high inertia cycle periods before flagging an outlier.'),
                              NumberWheelPicker(
                                value: uiState.twMargin,
                                range: marginRange,
                                format: '%.1f%%',
                                multiplyBy: 100.0,
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
                              _settingLabel('Fit Residual Exclusion', 'The threshold for sine-wave fit quality. Measurements with a fit residual equal to or exceeding this threshold are marked as poor fit quality.'),
                              NumberWheelPicker(
                                value: uiState.fitResidualExclusion,
                                range: fitExclusionRange,
                                format: '%.1f',
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Export CSV'),
                                content: const Text('Select database to export.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _exportCsv('MEASURE');
                                    },
                                    child: const Text('Measure Database'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _exportCsv('ESTIMATE');
                                    },
                                    child: const Text('Estimate Database'),
                                  ),
                                ],
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
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          icon: const Icon(Icons.download_for_offline, size: 18),
                          label: const Text('Import', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Import CSV'),
                                content: const Text('Select which database to import. Data will be appended.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _importCsv('MEASURE');
                                    },
                                    child: const Text('Measure Database'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _importCsv('ESTIMATE');
                                    },
                                    child: const Text('Estimate Database'),
                                  ),
                                ],
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
                  child: Text(
                    AppVersion.fullVersionNote,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
