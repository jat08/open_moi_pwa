import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { LIGHT, DARK, SYSTEM }

class AppPreferences {
  static const String keyDeviceKappa = 'device_kappa';
  static const String keyDeviceInertia = 'device_inertia';
  static const String keyKnownObjectAInertia = 'known_object_a_inertia_v3';
  static const String keyKnownObjectBInertia = 'known_object_b_inertia_v3';
  static const String keyThemeMode = 'theme_mode';
  static const String keyMoiUnitsResolution = 'units_resolution';
  static const String keyPeriodUnitsResolution = 'period_units_resolution';
  static const String keyPickleballTare = 'pickleball_tare';
  static const String keyTwistTare = 'twist_tare';
  static const String keySelectedTareMode = 'selected_tare_mode';
  static const String keyMeasuringDuration = 'measuring_duration';
  static const String keyWaitDuration = 'wait_duration';
  static const String keyCyclesToMeasure = 'cycles_to_measure';
  static const String keySwMargin = 'sw_margin';
  static const String keyTwMargin = 'tw_margin';
  static const String keyFitResidualExclusion = 'fit_residual_exclusion';
  static const String keyKeepScreenOn = 'keep_screen_on';
  static const String keyPreparationTime = 'preparation_time';
  static const String keySortType = 'sort_type';
  static const String keySortDirection = 'sort_direction';
  static const String keyTrimLastCycle = 'trim_last_cycle';
  static const String keySkipFirstCycles = 'skip_first_cycles';
  static const String keyCycleReference = 'cycle_reference';
  static const String keyExpectedPeriodA = 'expected_period_a';
  static const String keyExpectedPeriodB = 'expected_period_b';
  static const String keyExpectedMoiPb = 'expected_moi_pb';
  static const String keyExpectedMoiTw = 'expected_moi_tw';
  static const String keyExpectedK = 'expected_k';
  static const String keyApplyOptimization = 'apply_optimization';

  static const double defaultKnownAInertia = 20.0;
  static const double defaultKnownBInertia = 200.0;
  static const double defaultExpectedPeriodA = 0.6947;
  static const double defaultExpectedPeriodB = 0.2607;
  static const double defaultExpectedMoiPb = 1.16;
  static const double defaultExpectedMoiTw = 2.16;

  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  static Future<AppPreferences> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(prefs);
  }

  double get deviceKappa => _prefs.getDouble(keyDeviceKappa) ?? 0.0;
  Future<void> saveDeviceKappa(double value) => _prefs.setDouble(keyDeviceKappa, value);

  double get deviceInertia => _prefs.getDouble(keyDeviceInertia) ?? 0.0;
  Future<void> saveDeviceInertia(double value) => _prefs.setDouble(keyDeviceInertia, value);

  double get knownObjectAInertia => _prefs.getDouble(keyKnownObjectAInertia) ?? defaultKnownAInertia;
  Future<void> saveKnownObjectAInertia(double value) => _prefs.setDouble(keyKnownObjectAInertia, value);

  double get knownObjectBInertia => _prefs.getDouble(keyKnownObjectBInertia) ?? defaultKnownBInertia;
  Future<void> saveKnownObjectBInertia(double value) => _prefs.setDouble(keyKnownObjectBInertia, value);

  double get expectedPeriodA => _prefs.getDouble(keyExpectedPeriodA) ?? defaultExpectedPeriodA;
  Future<void> saveExpectedPeriodA(double value) => _prefs.setDouble(keyExpectedPeriodA, value);

  double get expectedPeriodB => _prefs.getDouble(keyExpectedPeriodB) ?? defaultExpectedPeriodB;
  Future<void> saveExpectedPeriodB(double value) => _prefs.setDouble(keyExpectedPeriodB, value);

  double get expectedMoiPb => _prefs.getDouble(keyExpectedMoiPb) ?? defaultExpectedMoiPb;
  Future<void> saveExpectedMoiPb(double value) => _prefs.setDouble(keyExpectedMoiPb, value);

  double get expectedMoiTw => _prefs.getDouble(keyExpectedMoiTw) ?? defaultExpectedMoiTw;
  Future<void> saveExpectedMoiTw(double value) => _prefs.setDouble(keyExpectedMoiTw, value);

  double? get expectedK => _prefs.containsKey(keyExpectedK) ? _prefs.getDouble(keyExpectedK) : null;
  Future<void> saveExpectedK(double? value) async {
    if (value == null) {
      await _prefs.remove(keyExpectedK);
    } else {
      await _prefs.setDouble(keyExpectedK, value);
    }
  }

  AppThemeMode get themeMode {
    final name = _prefs.getString(keyThemeMode) ?? AppThemeMode.SYSTEM.name;
    return AppThemeMode.values.firstWhere(
      (e) => e.name == name,
      orElse: () => AppThemeMode.SYSTEM,
    );
  }
  Future<void> saveThemeMode(AppThemeMode mode) => _prefs.setString(keyThemeMode, mode.name);

  int get moiUnitsResolution => _prefs.getInt(keyMoiUnitsResolution) ?? 1;
  Future<void> saveMoiUnitsResolution(int res) => _prefs.setInt(keyMoiUnitsResolution, res);

  int get periodUnitsResolution => _prefs.getInt(keyPeriodUnitsResolution) ?? 4;
  Future<void> savePeriodUnitsResolution(int res) => _prefs.setInt(keyPeriodUnitsResolution, res);

  double get pickleballTare => _prefs.getDouble(keyPickleballTare) ?? 0.0;
  Future<void> savePickleballTare(double tare) => _prefs.setDouble(keyPickleballTare, tare);

  double get twistTare => _prefs.getDouble(keyTwistTare) ?? 0.0;
  Future<void> saveTwistTare(double tare) => _prefs.setDouble(keyTwistTare, tare);

  String get selectedTareMode => _prefs.getString(keySelectedTareMode) ?? 'NONE';
  Future<void> saveSelectedTareMode(String mode) => _prefs.setString(keySelectedTareMode, mode);

  double get measuringDuration => _prefs.getDouble(keyMeasuringDuration) ?? 8.0;
  Future<void> saveMeasuringDuration(double seconds) => _prefs.setDouble(keyMeasuringDuration, seconds);

  double get waitDuration => _prefs.getDouble(keyWaitDuration) ?? 2.0;
  Future<void> saveWaitDuration(double seconds) => _prefs.setDouble(keyWaitDuration, seconds);

  int get cyclesToMeasure => _prefs.getInt(keyCyclesToMeasure) ?? 5;
  Future<void> saveCyclesToMeasure(int count) => _prefs.setInt(keyCyclesToMeasure, count);

  double get swMargin => _prefs.getDouble(keySwMargin) ?? 0.003;
  Future<void> saveSwMargin(double margin) => _prefs.setDouble(keySwMargin, margin);

  double get twMargin => _prefs.getDouble(keyTwMargin) ?? 0.01;
  Future<void> saveTwMargin(double margin) => _prefs.setDouble(keyTwMargin, margin);

  double get fitResidualExclusion => _prefs.getDouble(keyFitResidualExclusion) ?? 1.5;
  Future<void> saveFitResidualExclusion(double threshold) => _prefs.setDouble(keyFitResidualExclusion, threshold);

  bool get keepScreenOn => _prefs.getBool(keyKeepScreenOn) ?? true;
  Future<void> saveKeepScreenOn(bool keepOn) => _prefs.setBool(keyKeepScreenOn, keepOn);

  int get preparationTime => _prefs.getInt(keyPreparationTime) ?? 2;
  Future<void> savePreparationTime(int seconds) => _prefs.setInt(keyPreparationTime, seconds);

  String get sortType => _prefs.getString(keySortType) ?? 'DATE';
  Future<void> saveSortType(String type) => _prefs.setString(keySortType, type);

  String get sortDirection => _prefs.getString(keySortDirection) ?? 'ASCENDING';
  Future<void> saveSortDirection(String dir) => _prefs.setString(keySortDirection, dir);

  bool get trimLastCycle => _prefs.getBool(keyTrimLastCycle) ?? false;
  Future<void> saveTrimLastCycle(bool trim) => _prefs.setBool(keyTrimLastCycle, trim);

  int get skipFirstCycles => _prefs.getInt(keySkipFirstCycles) ?? 1;
  Future<void> saveSkipFirstCycles(int count) => _prefs.setInt(keySkipFirstCycles, count);

  int get cycleReference => _prefs.getInt(keyCycleReference) ?? 0;
  Future<void> saveCycleReference(int index) => _prefs.setInt(keyCycleReference, index);

  bool get applyOptimization => _prefs.getBool(keyApplyOptimization) ?? true;
  Future<void> saveApplyOptimization(bool apply) => _prefs.setBool(keyApplyOptimization, apply);

  Future<void> saveCalibration(double kappa, double deviceInertia) async {
    await saveDeviceKappa(kappa);
    await saveDeviceInertia(deviceInertia);
  }

  Future<void> saveExpectedValue(String target, double value) async {
    switch (target) {
      case 'OBJECT_A':
        await saveExpectedPeriodA(value);
        break;
      case 'OBJECT_B':
        await saveExpectedPeriodB(value);
        break;
      case 'TARE_PB':
        await saveExpectedMoiPb(value);
        break;
      case 'TARE_TW':
        await saveExpectedMoiTw(value);
        break;
    }
  }
}
