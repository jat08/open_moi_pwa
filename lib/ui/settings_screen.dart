import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  Future<void> _exportBothCsv() async {
    final notifier = ref.read(moiProvider.notifier);
    final measureCsv = await notifier.exportMeasureToCsv();
    final estimateCsv = await notifier.exportEstimateToCsv();

    final measureFilename = getExportFilename('Measurements');
    final estimateFilename = getExportFilename('Estimations');

    final tempDir = await getTemporaryDirectory();
    final measureFile = File('${tempDir.path}/$measureFilename');
    final estimateFile = File('${tempDir.path}/$estimateFilename');

    await measureFile.writeAsString(measureCsv);
    await estimateFile.writeAsString(estimateCsv);

    bool savedToDownloads = false;

    if (Platform.isAndroid) {
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final pubMeasureFile = File('${downloadDir.path}/$measureFilename');
          final pubEstimateFile = File('${downloadDir.path}/$estimateFilename');
          await pubMeasureFile.writeAsString(measureCsv);
          await pubEstimateFile.writeAsString(estimateCsv);
          savedToDownloads = true;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved both files to Downloads: $measureFilename, $estimateFilename'),
              ),
            );
          }
        }
      } catch (_) {}
    }

    await Share.shareXFiles(
      [
        XFile(measureFile.path),
        XFile(estimateFile.path),
      ],
      subject: 'OpenMOI CSV Database Exports',
      text: savedToDownloads
          ? 'Both CSV databases saved to Downloads folder ($measureFilename, $estimateFilename).'
          : 'Exported OpenMOI CSV databases ($measureFilename, $estimateFilename):',
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 8),
                child: Text(
                  'Settings',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ),

              Text('Theme & Display', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              const SizedBox(height: 4),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Theme Mode', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface)),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MOI Units Resolution', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface)),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Period Units Resolution', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface)),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Keep Screen On', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface)),
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

              const SizedBox(height: 10),

              Text('Measurement Control', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              const SizedBox(height: 4),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Measuring Duration (seconds)', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Wait between Measurements (seconds)', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Cycles to Measure', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Trim Last Cycle', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface)),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Skip First Cycles', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Cycle Reference', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Preparation Time (seconds)', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Low Margin', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('High Margin', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
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

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text('Fit Residual Exclusion', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface))),
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

              const SizedBox(height: 10),

              Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              const SizedBox(height: 6),

              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Export CSV'),
                        content: const Text('Select database(s) to export.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _exportBothCsv();
                            },
                            child: const Text('Export Both Databases'),
                          ),
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
                  child: const Text('Export Database', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 6),

              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
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
                  child: const Text('Import Database', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
