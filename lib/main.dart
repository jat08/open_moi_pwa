import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'data/app_preferences.dart';
import 'providers/moi_provider.dart';
import 'ui/calibration_detail_screen.dart';
import 'ui/calibration_info_screen.dart';
import 'ui/calibration_screen.dart';
import 'ui/estimate_detail_screen.dart';
import 'ui/estimate_screen.dart';
import 'ui/group_attributes_screen.dart';
import 'ui/group_detail_screen.dart';
import 'ui/measure_screen.dart';
import 'ui/measurement_detail_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    const ProviderScope(
      child: OpenMOIApp(),
    ),
  );
}

class OpenMOIApp extends ConsumerWidget {
  const OpenMOIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(moiProvider);

    // Screen Wakelock management
    if (!kIsWeb) {
      if (uiState.keepScreenOn) {
        try {
          WakelockPlus.enable();
        } catch (_) {}
      } else {
        try {
          WakelockPlus.disable();
        } catch (_) {}
      }
    }

    ThemeMode themeMode;
    switch (uiState.themeMode) {
      case AppThemeMode.LIGHT:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.DARK:
        themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.SYSTEM:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp(
      title: AppVersion.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.8,
              maxScaleFactor: 1.3,
            ),
          ),
          child: child!,
        );
      },
      home: const MainNavigationScaffold(),
    );
  }
}

class MainNavigationScaffold extends ConsumerStatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  ConsumerState<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends ConsumerState<MainNavigationScaffold> {
  bool _hasRequestedWebMotionPermission = false;

  void _handleFirstUserTap() {
    if (kIsWeb && !_hasRequestedWebMotionPermission) {
      _hasRequestedWebMotionPermission = true;
      ref.read(moiProvider.notifier).requestPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(moiProvider);

    // Navigation subview check to control bottom bar visibility
    final showBottomBar = uiState.selectedGroupId == null &&
        uiState.selectedCalibrationTarget == null &&
        uiState.selectedEstimationGroupId == null &&
        uiState.selectedMeasurement == null &&
        uiState.editingAttributesGroupId == null &&
        uiState.editingExpectedValueTarget == null;

    Widget body;
    String screenKey;

    if (uiState.editingAttributesGroupId != null && uiState.currentAttributeGroup != null) {
      body = GroupAttributesScreen(group: uiState.currentAttributeGroup!);
      screenKey = 'attributes_${uiState.editingAttributesGroupId}';
    } else if (uiState.editingExpectedValueTarget != null) {
      body = CalibrationInfoScreen(target: uiState.editingExpectedValueTarget!);
      screenKey = 'expected_${uiState.editingExpectedValueTarget}';
    } else if (uiState.selectedMeasurement != null) {
      body = MeasurementDetailScreen(measurement: uiState.selectedMeasurement!);
      screenKey = 'measurement_${uiState.selectedMeasurement!.id}';
    } else if (uiState.selectedGroupId != null) {
      body = GroupDetailScreen(groupId: uiState.selectedGroupId!);
      screenKey = 'group_${uiState.selectedGroupId}';
    } else if (uiState.selectedEstimationGroupId != null && uiState.currentEstimationGroup != null) {
      body = EstimateDetailScreen(group: uiState.currentEstimationGroup!);
      screenKey = 'estimation_${uiState.selectedEstimationGroupId}';
    } else if (uiState.selectedCalibrationTarget != null) {
      body = CalibrationDetailScreen(target: uiState.selectedCalibrationTarget!);
      screenKey = 'calibration_${uiState.selectedCalibrationTarget}';
    } else {
      switch (uiState.activeTab) {
        case 0:
          body = const MeasureScreen();
          screenKey = 'tab_0';
          break;
        case 1:
          body = const EstimateScreen();
          screenKey = 'tab_1';
          break;
        case 2:
          body = const CalibrationScreen();
          screenKey = 'tab_2';
          break;
        case 3:
          body = const SettingsScreen();
          screenKey = 'tab_3';
          break;
        default:
          body = const MeasureScreen();
          screenKey = 'tab_0';
      }
    }

    return Listener(
      onPointerDown: (_) => _handleFirstUserTap(),
      child: Scaffold(
        body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<String>(screenKey),
          child: body,
        ),
      ),
      bottomNavigationBar: showBottomBar
          ? NavigationBar(
              selectedIndex: uiState.activeTab,
              onDestinationSelected: (index) {
                HapticFeedback.selectionClick();
                ref.read(moiProvider.notifier).setTab(index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: 'Measure',
                ),
                NavigationDestination(
                  icon: Icon(Icons.functions_outlined),
                  selectedIcon: Icon(Icons.functions),
                  label: 'Estimate',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'Calibrate',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
      ),
    );
  }
}
