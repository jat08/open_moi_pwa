import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/app_preferences.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../logic/moi_calculator.dart';
import '../logic/oscillation_detector.dart';
import '../logic/web_helper.dart';

enum SortType { NAME, DATE }
enum SortDirection { ASCENDING, DESCENDING }
enum CalibrationTarget { NONE, OBJECT_A, OBJECT_B, TARE_PB, TARE_TW }

class UiState {
  final OscillationState detectorState;
  final double progress;
  final double lastMeasuredPeriod;
  final double calculatedMOI;
  final CalibrationTarget calibrationTarget;
  final CalibrationTarget? selectedCalibrationTarget;
  final List<Measurement> measurementsA;
  final List<Measurement> measurementsB;
  final int? selectedGroupId;
  final List<Measurement> selectedGroupMeasurements;
  final List<GroupSummary> groups;
  final String searchQuery;
  final SortType sortType;
  final SortDirection sortDirection;
  final bool isCalibrated;
  final double deviceKappa;
  final double deviceInertia;
  final AppThemeMode themeMode;
  final int moiUnitsResolution;
  final int periodUnitsResolution;

  final double currentSWAverage;
  final double currentSWStdDev;
  final double currentTWAverage;
  final double currentTWStdDev;

  final double currentSWPeriodAverage;
  final double currentSWPeriodStdDev;
  final double currentTWPeriodAverage;
  final double currentTWPeriodStdDev;

  final double currentCalibrationPeriodAverage;
  final double currentCalibrationPeriodStdDev;

  final List<Measurement> measurementsTarePB;
  final List<Measurement> measurementsTareTW;
  final String selectedTareMode;
  final double pickleballTareOffset;
  final double twistTareOffset;

  final double measuringDuration;
  final double waitDuration;
  final int cyclesToMeasure;
  final double swMargin;
  final double twMargin;
  final double fitResidualExclusion;
  final bool trimLastCycle;
  final int skipFirstCycles;

  final int cycleReference;
  final bool keepScreenOn;
  final int preparationTime;
  final int preparationRemaining;
  final double cooldownRemaining;

  final Measurement? selectedMeasurement;
  final int? editingAttributesGroupId;
  final MeasurementGroup? currentAttributeGroup;
  final CalibrationTarget? editingExpectedValueTarget;

  final double knownObjectAInertia;
  final double knownObjectBInertia;
  final double expectedPeriodA;
  final double expectedPeriodB;
  final double expectedMoiPB;
  final double expectedMoiTW;

  final String estimationSearchQuery;
  final int? selectedEstimationGroupId;
  final List<EstimationGroup> estimationGroups;
  final EstimationGroup? currentEstimationGroup;

  final String? importError;
  final int activeTab;
  final List<dynamic>? comparisonGroups;
  final bool isWarmingUp;
  final int warmUpRemaining;

  UiState({
    this.detectorState = OscillationState.WRONG_ORIENTATION,
    this.progress = 0.0,
    this.lastMeasuredPeriod = 0.0,
    this.calculatedMOI = 0.0,
    this.calibrationTarget = CalibrationTarget.NONE,
    this.selectedCalibrationTarget,
    this.measurementsA = const [],
    this.measurementsB = const [],
    this.selectedGroupId,
    this.selectedGroupMeasurements = const [],
    this.groups = const [],
    this.searchQuery = '',
    this.sortType = SortType.DATE,
    this.sortDirection = SortDirection.ASCENDING,
    this.isCalibrated = false,
    this.deviceKappa = 0.0,
    this.deviceInertia = 0.0,
    this.themeMode = AppThemeMode.SYSTEM,
    this.moiUnitsResolution = 1,
    this.periodUnitsResolution = 4,
    this.currentSWAverage = 0.0,
    this.currentSWStdDev = 0.0,
    this.currentTWAverage = 0.0,
    this.currentTWStdDev = 0.0,
    this.currentSWPeriodAverage = 0.0,
    this.currentSWPeriodStdDev = 0.0,
    this.currentTWPeriodAverage = 0.0,
    this.currentTWPeriodStdDev = 0.0,
    this.currentCalibrationPeriodAverage = 0.0,
    this.currentCalibrationPeriodStdDev = 0.0,
    this.measurementsTarePB = const [],
    this.measurementsTareTW = const [],
    this.selectedTareMode = 'NONE',
    this.pickleballTareOffset = 0.0,
    this.twistTareOffset = 0.0,
    this.measuringDuration = 8.0,
    this.waitDuration = 2.0,
    this.cyclesToMeasure = 4,
    this.swMargin = 0.003,
    this.twMargin = 0.01,
    this.fitResidualExclusion = 1.5,
    this.trimLastCycle = false,
    this.skipFirstCycles = 1,
    this.cycleReference = 0,
    this.keepScreenOn = true,
    this.preparationTime = 2,
    this.preparationRemaining = 0,
    this.cooldownRemaining = 0.0,
    this.isWarmingUp = false,
    this.warmUpRemaining = 0,
    this.selectedMeasurement,
    this.editingAttributesGroupId,
    this.currentAttributeGroup,
    this.editingExpectedValueTarget,
    this.knownObjectAInertia = AppPreferences.defaultKnownAInertia,
    this.knownObjectBInertia = AppPreferences.defaultKnownBInertia,
    this.expectedPeriodA = AppPreferences.defaultExpectedPeriodA,
    this.expectedPeriodB = AppPreferences.defaultExpectedPeriodB,
    this.expectedMoiPB = AppPreferences.defaultExpectedMoiPb,
    this.expectedMoiTW = AppPreferences.defaultExpectedMoiTw,
    this.estimationSearchQuery = '',
    this.selectedEstimationGroupId,
    this.estimationGroups = const [],
    this.currentEstimationGroup,
    this.importError,
    this.activeTab = 0,
    this.comparisonGroups,
  });

  UiState copyWith({
    OscillationState? detectorState,
    double? progress,
    double? lastMeasuredPeriod,
    double? calculatedMOI,
    CalibrationTarget? calibrationTarget,
    CalibrationTarget? Function()? selectedCalibrationTarget,
    List<Measurement>? measurementsA,
    List<Measurement>? measurementsB,
    int? Function()? selectedGroupId,
    List<Measurement>? selectedGroupMeasurements,
    List<GroupSummary>? groups,
    String? searchQuery,
    SortType? sortType,
    SortDirection? sortDirection,
    bool? isCalibrated,
    double? deviceKappa,
    double? deviceInertia,
    AppThemeMode? themeMode,
    int? moiUnitsResolution,
    int? periodUnitsResolution,
    double? currentSWAverage,
    double? currentSWStdDev,
    double? currentTWAverage,
    double? currentTWStdDev,
    double? currentSWPeriodAverage,
    double? currentSWPeriodStdDev,
    double? currentTWPeriodAverage,
    double? currentTWPeriodStdDev,
    double? currentCalibrationPeriodAverage,
    double? currentCalibrationPeriodStdDev,
    List<Measurement>? measurementsTarePB,
    List<Measurement>? measurementsTareTW,
    String? selectedTareMode,
    double? pickleballTareOffset,
    double? twistTareOffset,
    double? measuringDuration,
    double? waitDuration,
    int? cyclesToMeasure,
    double? swMargin,
    double? twMargin,
    double? fitResidualExclusion,
    bool? trimLastCycle,
    int? skipFirstCycles,
    int? cycleReference,
    bool? keepScreenOn,
    int? preparationTime,
    int? preparationRemaining,
    double? cooldownRemaining,
    bool? isWarmingUp,
    int? warmUpRemaining,
    Measurement? Function()? selectedMeasurement,
    int? Function()? editingAttributesGroupId,
    MeasurementGroup? Function()? currentAttributeGroup,
    CalibrationTarget? Function()? editingExpectedValueTarget,
    double? knownObjectAInertia,
    double? knownObjectBInertia,
    double? expectedPeriodA,
    double? expectedPeriodB,
    double? expectedMoiPB,
    double? expectedMoiTW,
    String? estimationSearchQuery,
    int? Function()? selectedEstimationGroupId,
    List<EstimationGroup>? estimationGroups,
    EstimationGroup? Function()? currentEstimationGroup,
    String? Function()? importError,
    int? activeTab,
    List<dynamic>? Function()? comparisonGroups,
  }) {
    return UiState(
      detectorState: detectorState ?? this.detectorState,
      progress: progress ?? this.progress,
      lastMeasuredPeriod: lastMeasuredPeriod ?? this.lastMeasuredPeriod,
      calculatedMOI: calculatedMOI ?? this.calculatedMOI,
      calibrationTarget: calibrationTarget ?? this.calibrationTarget,
      selectedCalibrationTarget: selectedCalibrationTarget != null ? selectedCalibrationTarget() : this.selectedCalibrationTarget,
      measurementsA: measurementsA ?? this.measurementsA,
      measurementsB: measurementsB ?? this.measurementsB,
      selectedGroupId: selectedGroupId != null ? selectedGroupId() : this.selectedGroupId,
      selectedGroupMeasurements: selectedGroupMeasurements ?? this.selectedGroupMeasurements,
      groups: groups ?? this.groups,
      searchQuery: searchQuery ?? this.searchQuery,
      sortType: sortType ?? this.sortType,
      sortDirection: sortDirection ?? this.sortDirection,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      deviceKappa: deviceKappa ?? this.deviceKappa,
      deviceInertia: deviceInertia ?? this.deviceInertia,
      themeMode: themeMode ?? this.themeMode,
      moiUnitsResolution: moiUnitsResolution ?? this.moiUnitsResolution,
      periodUnitsResolution: periodUnitsResolution ?? this.periodUnitsResolution,
      currentSWAverage: currentSWAverage ?? this.currentSWAverage,
      currentSWStdDev: currentSWStdDev ?? this.currentSWStdDev,
      currentTWAverage: currentTWAverage ?? this.currentTWAverage,
      currentTWStdDev: currentTWStdDev ?? this.currentTWStdDev,
      currentSWPeriodAverage: currentSWPeriodAverage ?? this.currentSWPeriodAverage,
      currentSWPeriodStdDev: currentSWPeriodStdDev ?? this.currentSWPeriodStdDev,
      currentTWPeriodAverage: currentTWPeriodAverage ?? this.currentTWPeriodAverage,
      currentTWPeriodStdDev: currentTWPeriodStdDev ?? this.currentTWPeriodStdDev,
      currentCalibrationPeriodAverage: currentCalibrationPeriodAverage ?? this.currentCalibrationPeriodAverage,
      currentCalibrationPeriodStdDev: currentCalibrationPeriodStdDev ?? this.currentCalibrationPeriodStdDev,
      measurementsTarePB: measurementsTarePB ?? this.measurementsTarePB,
      measurementsTareTW: measurementsTareTW ?? this.measurementsTareTW,
      selectedTareMode: selectedTareMode ?? this.selectedTareMode,
      pickleballTareOffset: pickleballTareOffset ?? this.pickleballTareOffset,
      twistTareOffset: twistTareOffset ?? this.twistTareOffset,
      measuringDuration: measuringDuration ?? this.measuringDuration,
      waitDuration: waitDuration ?? this.waitDuration,
      cyclesToMeasure: cyclesToMeasure ?? this.cyclesToMeasure,
      swMargin: swMargin ?? this.swMargin,
      twMargin: twMargin ?? this.twMargin,
      fitResidualExclusion: fitResidualExclusion ?? this.fitResidualExclusion,
      trimLastCycle: trimLastCycle ?? this.trimLastCycle,
      skipFirstCycles: skipFirstCycles ?? this.skipFirstCycles,
      cycleReference: cycleReference ?? this.cycleReference,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      preparationTime: preparationTime ?? this.preparationTime,
      preparationRemaining: preparationRemaining ?? this.preparationRemaining,
      cooldownRemaining: cooldownRemaining ?? this.cooldownRemaining,
      isWarmingUp: isWarmingUp ?? this.isWarmingUp,
      warmUpRemaining: warmUpRemaining ?? this.warmUpRemaining,
      selectedMeasurement: selectedMeasurement != null ? selectedMeasurement() : this.selectedMeasurement,
      editingAttributesGroupId: editingAttributesGroupId != null ? editingAttributesGroupId() : this.editingAttributesGroupId,
      currentAttributeGroup: currentAttributeGroup != null ? currentAttributeGroup() : this.currentAttributeGroup,
      editingExpectedValueTarget: editingExpectedValueTarget != null ? editingExpectedValueTarget() : this.editingExpectedValueTarget,
      knownObjectAInertia: knownObjectAInertia ?? this.knownObjectAInertia,
      knownObjectBInertia: knownObjectBInertia ?? this.knownObjectBInertia,
      expectedPeriodA: expectedPeriodA ?? this.expectedPeriodA,
      expectedPeriodB: expectedPeriodB ?? this.expectedPeriodB,
      expectedMoiPB: expectedMoiPB ?? this.expectedMoiPB,
      expectedMoiTW: expectedMoiTW ?? this.expectedMoiTW,
      estimationSearchQuery: estimationSearchQuery ?? this.estimationSearchQuery,
      selectedEstimationGroupId: selectedEstimationGroupId != null ? selectedEstimationGroupId() : this.selectedEstimationGroupId,
      estimationGroups: estimationGroups ?? this.estimationGroups,
      currentEstimationGroup: currentEstimationGroup != null ? currentEstimationGroup() : this.currentEstimationGroup,
      importError: importError != null ? importError() : this.importError,
      activeTab: activeTab ?? this.activeTab,
      comparisonGroups: comparisonGroups != null ? comparisonGroups() : this.comparisonGroups,
    );
  }
}

class Stats {
  final double average;
  final double stdDev;
  Stats(this.average, this.stdDev);
}

final moiProvider = StateNotifierProvider<MoiNotifier, UiState>((ref) {
  return MoiNotifier();
});

class MoiNotifier extends StateNotifier<UiState> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late AppPreferences _prefs;
  OscillationDetector? _detector;
  Timer? _cooldownTimer;
  Timer? _prepTimer;
  Timer? _warmUpTimer;

  MoiNotifier() : super(UiState()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await AppPreferences.getInstance();

    _detector = OscillationDetector(
      onStateChanged: (state) {
        this.state = this.state.copyWith(detectorState: state);
      },
      onMeasurementComplete: (result) {
        handleMeasurementComplete(result);
      },
      onProgressUpdate: (progress) {
        state = state.copyWith(progress: progress);
      },
    );
    _detector?.startListening();

    loadPreferences();
    await refreshData();
  }

  void loadPreferences() {
    state = state.copyWith(
      deviceKappa: _prefs.deviceKappa,
      deviceInertia: _prefs.deviceInertia,
      knownObjectAInertia: _prefs.knownObjectAInertia,
      knownObjectBInertia: _prefs.knownObjectBInertia,
      expectedPeriodA: _prefs.expectedPeriodA,
      expectedPeriodB: _prefs.expectedPeriodB,
      expectedMoiPB: _prefs.expectedMoiPb,
      expectedMoiTW: _prefs.expectedMoiTw,
      themeMode: _prefs.themeMode,
      moiUnitsResolution: _prefs.moiUnitsResolution,
      periodUnitsResolution: _prefs.periodUnitsResolution,
      pickleballTareOffset: _prefs.pickleballTare,
      twistTareOffset: _prefs.twistTare,
      selectedTareMode: _prefs.selectedTareMode,
      measuringDuration: _prefs.measuringDuration,
      waitDuration: _prefs.waitDuration,
      cyclesToMeasure: _prefs.cyclesToMeasure,
      swMargin: _prefs.swMargin,
      twMargin: _prefs.twMargin,
      fitResidualExclusion: _prefs.fitResidualExclusion,
      keepScreenOn: _prefs.keepScreenOn,
      preparationTime: _prefs.preparationTime,
      sortType: SortType.values.firstWhere((e) => e.name == _prefs.sortType, orElse: () => SortType.DATE),
      sortDirection: SortDirection.values.firstWhere((e) => e.name == _prefs.sortDirection, orElse: () => SortDirection.ASCENDING),
      trimLastCycle: _prefs.trimLastCycle,
      skipFirstCycles: _prefs.skipFirstCycles,
      cycleReference: _prefs.cycleReference,
    );

    _detector?.setMaxDuration(state.measuringDuration);
    _detector?.setRequiredCycles(state.cyclesToMeasure);
    _detector?.setSkipFirstCycles(state.skipFirstCycles);
  }

  AppPreferences get prefs => _prefs;

  Future<void> refreshData() async {
    await refreshGroups();
    await refreshCalibrationData();
    await refreshTareData();
    await refreshSelectedGroupData();
    await refreshEstimationGroups();
  }

  Future<void> refreshGroups() async {
    final rawGroups = state.searchQuery.isEmpty
        ? await _db.getAllGroups()
        : await _db.searchGroups(state.searchQuery);

    rawGroups.sort((a, b) {
      if (state.sortType == SortType.NAME) {
        return state.sortDirection == SortDirection.ASCENDING
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name);
      } else {
        return state.sortDirection == SortDirection.ASCENDING
            ? a.timestamp.compareTo(b.timestamp)
            : b.timestamp.compareTo(a.timestamp);
      }
    });

    final summaries = <GroupSummary>[];
    for (var g in rawGroups) {
      final measurements = await _db.getMeasurementsByGroup(g.id!);
      final swMeasurements = measurements.where((m) => m.moi >= 40).toList();
      final twMeasurements = measurements.where((m) => m.moi < 40).toList();

      final swStats = calculateStats(swMeasurements, 10.0);
      final twStats = calculateStats(twMeasurements, 10.0);

      summaries.add(GroupSummary(
        group: g,
        count: measurements.length,
        avgSW: swStats.average,
        stdDevSW: swStats.stdDev,
        avgTW: twStats.average,
        stdDevTW: twStats.stdDev,
      ));
    }

    state = state.copyWith(groups: summaries);
  }

  Future<void> refreshCalibrationData() async {
    final listA = await _db.getMeasurementsByType('OBJECT_A');
    final listB = await _db.getMeasurementsByType('OBJECT_B');

    listA.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    listB.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final isCalibrated = listA.isNotEmpty && listB.isNotEmpty;

    state = state.copyWith(
      measurementsA: listA,
      measurementsB: listB,
      isCalibrated: isCalibrated,
    );

    await calculateCalibrationIfReady();
    updateCalibrationStats();
  }

  Future<void> refreshTareData() async {
    final listPB = await _db.getMeasurementsByType('TARE_PB');
    final listTW = await _db.getMeasurementsByType('TARE_TW');

    listPB.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    listTW.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    state = state.copyWith(
      measurementsTarePB: listPB,
      measurementsTareTW: listTW,
    );

    await calculateTareIfReady('TARE_PB');
    await calculateTareIfReady('TARE_TW');
    updateCalibrationStats();
  }

  Future<void> refreshSelectedGroupData() async {
    if (state.selectedGroupId == null) return;

    final list = await _db.getMeasurementsByGroup(state.selectedGroupId!);
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final swMeasurements = list.where((m) => m.moi >= 40).toList();
    final twMeasurements = list.where((m) => m.moi < 40).toList();

    final swStats = calculateStats(swMeasurements, state.fitResidualExclusion);
    final twStats = calculateStats(twMeasurements, state.fitResidualExclusion);

    final swPeriodStats = calculatePeriodStats(swMeasurements, state.fitResidualExclusion);
    final twPeriodStats = calculatePeriodStats(twMeasurements, state.fitResidualExclusion);

    state = state.copyWith(
      selectedGroupMeasurements: list,
      currentSWAverage: swStats.average,
      currentSWStdDev: swStats.stdDev,
      currentTWAverage: twStats.average,
      currentTWStdDev: twStats.stdDev,
      currentSWPeriodAverage: swPeriodStats.average,
      currentSWPeriodStdDev: swPeriodStats.stdDev,
      currentTWPeriodAverage: twPeriodStats.average,
      currentTWPeriodStdDev: twPeriodStats.stdDev,
    );
  }

  Future<void> refreshEstimationGroups() async {
    final rawList = state.estimationSearchQuery.isEmpty
        ? await _db.getAllEstimationGroups()
        : await _db.searchEstimationGroups(state.estimationSearchQuery);

    rawList.sort((a, b) {
      if (state.sortType == SortType.NAME) {
        return state.sortDirection == SortDirection.ASCENDING
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name);
      } else {
        return state.sortDirection == SortDirection.ASCENDING
            ? a.timestamp.compareTo(b.timestamp)
            : b.timestamp.compareTo(a.timestamp);
      }
    });

    EstimationGroup? current;
    if (state.selectedEstimationGroupId != null) {
      current = await _db.getEstimationGroupById(state.selectedEstimationGroupId!);
    }

    state = state.copyWith(
      estimationGroups: rawList,
      currentEstimationGroup: () => current,
    );
  }

  Stats calculateStats(List<Measurement> measurements, double fitThreshold) {
    if (measurements.isEmpty) return Stats(0.0, 0.0);

    final qualityList = measurements.where((m) => m.fitResidual < fitThreshold).toList();
    if (qualityList.isEmpty) return Stats(0.0, 0.0);

    final avg = qualityList.map((m) => m.moi).reduce((a, b) => a + b) / qualityList.length;
    final variance = qualityList.map((m) => pow(m.moi - avg, 2)).reduce((a, b) => a + b) / qualityList.length;
    final stdDev = sqrt(variance);

    return Stats(avg, stdDev);
  }

  Stats calculatePeriodStats(List<Measurement> measurements, double fitThreshold) {
    if (measurements.isEmpty) return Stats(0.0, 0.0);

    final qualityList = measurements.where((m) => m.fitResidual < fitThreshold).toList();
    if (qualityList.isEmpty) return Stats(0.0, 0.0);

    final avg = qualityList.map((m) => m.period).reduce((a, b) => a + b) / qualityList.length;
    final variance = qualityList.map((m) => pow(m.period - avg, 2)).reduce((a, b) => a + b) / qualityList.length;
    final stdDev = sqrt(variance);

    return Stats(avg, stdDev);
  }

  void updateCalibrationStats() {
    final target = state.selectedCalibrationTarget;
    if (target == null) return;

    List<Measurement> list;
    switch (target) {
      case CalibrationTarget.OBJECT_A:
        list = state.measurementsA;
        break;
      case CalibrationTarget.OBJECT_B:
        list = state.measurementsB;
        break;
      case CalibrationTarget.TARE_PB:
        list = state.measurementsTarePB;
        break;
      case CalibrationTarget.TARE_TW:
        list = state.measurementsTareTW;
        break;
      case CalibrationTarget.NONE:
        list = [];
        break;
    }

    final stats = calculatePeriodStats(list, state.fitResidualExclusion);
    state = state.copyWith(
      currentCalibrationPeriodAverage: stats.average,
      currentCalibrationPeriodStdDev: stats.stdDev,
    );
  }

  void setTab(int index) {
    state = state.copyWith(
      activeTab: index,
      selectedGroupId: () => null,
      selectedCalibrationTarget: () => null,
      selectedEstimationGroupId: () => null,
      selectedMeasurement: () => null,
      editingAttributesGroupId: () => null,
      currentAttributeGroup: () => null,
      editingExpectedValueTarget: () => null,
      calibrationTarget: CalibrationTarget.NONE,
      comparisonGroups: () => null,
    );
  }

  void openComparison(List<dynamic> groups) {
    state = state.copyWith(comparisonGroups: () => groups);
  }

  void closeComparison() {
    state = state.copyWith(comparisonGroups: () => null);
  }

  void startWarmUp() {
    _warmUpTimer?.cancel();
    _detector?.startListening();
    state = state.copyWith(isWarmingUp: true, warmUpRemaining: 30);
    _warmUpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.warmUpRemaining - 1;
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(isWarmingUp: false, warmUpRemaining: 0);
      } else {
        state = state.copyWith(warmUpRemaining: remaining);
      }
    });
  }

  void cancelWarmUp() {
    _warmUpTimer?.cancel();
    state = state.copyWith(isWarmingUp: false, warmUpRemaining: 0);
  }

  void navigateToCalibrate() {
    setTab(2);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    refreshGroups();
  }

  void setSortOrder(SortType type, SortDirection direction) async {
    await _prefs.saveSortType(type.name);
    await _prefs.saveSortDirection(direction.name);
    state = state.copyWith(sortType: type, sortDirection: direction);
    refreshGroups();
    refreshEstimationGroups();
  }

  void selectGroup(int? groupId) async {
    if (groupId == null) {
      state = state.copyWith(
        selectedGroupId: () => null,
        selectedGroupMeasurements: [],
        selectedCalibrationTarget: () => null,
        calibrationTarget: CalibrationTarget.NONE,
        currentSWAverage: 0.0,
        currentSWStdDev: 0.0,
        currentTWAverage: 0.0,
        currentTWStdDev: 0.0,
        currentSWPeriodAverage: 0.0,
        currentSWPeriodStdDev: 0.0,
        currentTWPeriodAverage: 0.0,
        currentTWPeriodStdDev: 0.0,
      );
    } else {
      state = state.copyWith(
        selectedGroupId: () => groupId,
        selectedCalibrationTarget: () => null,
        calibrationTarget: CalibrationTarget.NONE,
      );
      await refreshSelectedGroupData();
    }
  }

  void selectCalibrationTarget(CalibrationTarget? target) {
    state = state.copyWith(
      selectedCalibrationTarget: () => target,
      calibrationTarget: target ?? CalibrationTarget.NONE,
      selectedGroupId: () => null,
    );
    updateCalibrationStats();
  }

  Future<void> addGroup(String name) async {
    final count = await _db.getGroupCount();
    final finalName = name.trim().isEmpty ? 'Group ${count + 1}' : name;
    final id = await _db.insertGroup(MeasurementGroup(name: finalName));
    await refreshGroups();
    selectGroup(id);
  }

  Future<void> renameGroup(MeasurementGroup group, String newName) async {
    await _db.updateGroup(group.copyWith(name: newName));
    await refreshGroups();
  }

  Future<void> deleteGroups(Set<int> ids) async {
    await _db.deleteGroupsByIds(ids.toList());
    await refreshGroups();
  }

  void selectEditingAttributesGroup(int? groupId) async {
    MeasurementGroup? group;
    if (groupId != null) {
      group = await _db.getGroupById(groupId);
    }
    state = state.copyWith(
      editingAttributesGroupId: () => groupId,
      currentAttributeGroup: () => group,
    );
  }

  Future<void> updateGroupAttributes(
    MeasurementGroup group,
    double m,
    String mUnit,
    double l,
    String lUnit,
    double w,
    String wUnit,
    String type,
  ) async {
    await _db.updateGroup(group.copyWith(
      mass: m,
      massUnit: mUnit,
      length: l,
      lengthUnit: lUnit,
      width: w,
      widthUnit: wUnit,
      groupType: type,
    ));
    await refreshGroups();
  }

  void selectEditingExpectedValue(CalibrationTarget? target) {
    state = state.copyWith(editingExpectedValueTarget: () => target);
  }

  Future<void> updateExpectedValue(CalibrationTarget target, double value) async {
    await _prefs.saveExpectedValue(target.name, value);
    loadPreferences();
    selectEditingExpectedValue(null);
  }

  Future<void> requestPermission() async {
    if (!kIsWeb) return;
    final granted = await requestWebMotionPermission();
    if (granted) {
      _detector?.stopListening();
      _detector?.startListening();
    }
  }

  void startMeasurement() {
    if (state.cooldownRemaining > 0) return;

    _prepTimer?.cancel();
    _cooldownTimer?.cancel();

    _detector?.setMaxDuration(state.measuringDuration);
    _detector?.setRequiredCycles(state.cyclesToMeasure);
    _detector?.setSkipFirstCycles(state.skipFirstCycles);

    final prepTime = state.preparationTime;
    if (prepTime > 0) {
      state = state.copyWith(preparationRemaining: prepTime);
      var remaining = prepTime;
      _prepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        remaining--;
        state = state.copyWith(preparationRemaining: remaining);
        if (remaining <= 0) {
          timer.cancel();
          _detector?.arm();
        }
      });
    } else {
      _detector?.arm();
    }
  }

  void cancelMeasurement() {
    _prepTimer?.cancel();
    _cooldownTimer?.cancel();
    _detector?.reset();
    state = state.copyWith(
      detectorState: OscillationState.READY,
      progress: 0.0,
      preparationRemaining: 0,
      cooldownRemaining: 0.0,
    );
  }

  Future<void> handleMeasurementComplete(OscillationResult result) async {
    final kappa = state.deviceKappa;
    final deviceI = state.deviceInertia;
    final trimLast = state.trimLastCycle;

    final rawCycles = result.cyclePeriods
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s) ?? 0.0)
        .toList();

    if (rawCycles.isNotEmpty) {
      final rawPeriod = (trimLast && rawCycles.length > 1)
          ? rawCycles.sublist(0, rawCycles.length - 1).reduce((a, b) => a + b) / (rawCycles.length - 1)
          : rawCycles.reduce((a, b) => a + b) / rawCycles.length;

      final uniformMeasuredCycles = List.filled(
        rawCycles.length,
        rawPeriod.toStringAsFixed(6),
      ).join(',');

      final residual = calculateFitResidual(result.rawData, rawPeriod, result.totalDuration);

      final target = (state.selectedCalibrationTarget != null && state.selectedCalibrationTarget != CalibrationTarget.NONE)
          ? state.selectedCalibrationTarget!
          : state.calibrationTarget;

      switch (target) {
        case CalibrationTarget.OBJECT_A:
          await _db.insertMeasurement(Measurement(
            type: 'OBJECT_A',
            period: rawPeriod,
            moi: 0.0,
            rawData: result.rawData,
            cyclePeriods: uniformMeasuredCycles,
            totalDuration: result.totalDuration,
            fitResidual: residual,
          ));
          await refreshCalibrationData();
          break;
        case CalibrationTarget.OBJECT_B:
          await _db.insertMeasurement(Measurement(
            type: 'OBJECT_B',
            period: rawPeriod,
            moi: 0.0,
            rawData: result.rawData,
            cyclePeriods: uniformMeasuredCycles,
            totalDuration: result.totalDuration,
            fitResidual: residual,
          ));
          await refreshCalibrationData();
          break;
        case CalibrationTarget.TARE_PB:
          final physicalMoi = MomentOfInertiaCalculator.calculateObjectMOI(rawPeriod, kappa, deviceI);
          await _db.insertMeasurement(Measurement(
            type: 'TARE_PB',
            period: rawPeriod,
            moi: physicalMoi,
            rawData: result.rawData,
            cyclePeriods: uniformMeasuredCycles,
            totalDuration: result.totalDuration,
            fitResidual: residual,
          ));
          await refreshTareData();
          break;
        case CalibrationTarget.TARE_TW:
          final physicalMoi = MomentOfInertiaCalculator.calculateObjectMOI(rawPeriod, kappa, deviceI);
          await _db.insertMeasurement(Measurement(
            type: 'TARE_TW',
            period: rawPeriod,
            moi: physicalMoi,
            rawData: result.rawData,
            cyclePeriods: uniformMeasuredCycles,
            totalDuration: result.totalDuration,
            fitResidual: residual,
          ));
          await refreshTareData();
          break;
        case CalibrationTarget.NONE:
          final rawMoi = MomentOfInertiaCalculator.calculateObjectMOI(rawPeriod, kappa, deviceI);
          final tareMode = state.selectedTareMode;
          double tareOffset = 0.0;
          if (tareMode == 'PICKLEBALL') {
            tareOffset = state.pickleballTareOffset;
          } else if (tareMode == 'TWIST') {
            tareOffset = state.twistTareOffset;
          }

          final finalMoi = max(0.0, rawMoi - tareOffset);

          String modeAbbr = 'None';
          if (tareMode == 'PICKLEBALL') modeAbbr = 'PB';
          if (tareMode == 'TWIST') modeAbbr = 'TW';

          if (state.selectedGroupId != null) {
            await _db.insertMeasurement(Measurement(
              groupId: state.selectedGroupId,
              type: 'PADDLE',
              period: rawPeriod,
              moi: finalMoi,
              tareMode: modeAbbr,
              rawData: result.rawData,
              cyclePeriods: uniformMeasuredCycles,
              totalDuration: result.totalDuration,
              fitResidual: residual,
            ));
            await refreshSelectedGroupData();
            await refreshGroups();
          }
          state = state.copyWith(calculatedMOI: finalMoi);
          break;
      }
    }
    startCooldown();
  }

  double calculateFitResidual(String rawData, double period, double totalDuration) {
    if (period <= 0) return 1.0;
    final points = rawData
        .split(',')
        .where((s) => s.isNotEmpty)
        .map((s) => double.tryParse(s) ?? 0.0)
        .toList();
    if (points.isEmpty) return 1.0;

    final n = points.length;
    final omega = (2.0 * pi) / period;

    double sumSinSq = 0.0;
    double sumCosSq = 0.0;
    double sumYSin = 0.0;
    double sumYCos = 0.0;

    for (var i = 0; i < n; i++) {
      final t = (i / max(1, n - 1)) * totalDuration;
      final s = sin(omega * t);
      final c = cos(omega * t);
      final y = points[i];

      sumSinSq += s * s;
      sumCosSq += c * c;
      sumYSin += y * s;
      sumYCos += y * c;
    }

    final c1 = sumSinSq > 0 ? sumYSin / sumSinSq : 0.0;
    final c2 = sumCosSq > 0 ? sumYCos / sumCosSq : 0.0;
    final amplitude = sqrt(c1 * c1 + c2 * c2);

    if (amplitude == 0.0) return 1.0;

    double totalError = 0.0;
    for (var i = 0; i < n; i++) {
      final t = (i / max(1, n - 1)) * totalDuration;
      final fittedVal = c1 * sin(omega * t) + c2 * cos(omega * t);
      totalError += (points[i] - fittedVal).abs();
    }

    final avgError = totalError / n;
    return (avgError / amplitude) * 10.0;
  }

  void startCooldown() {
    _cooldownTimer?.cancel();
    final totalWait = state.waitDuration;
    var remaining = totalWait;

    _cooldownTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      remaining -= 0.1;
      if (remaining <= 0) {
        state = state.copyWith(cooldownRemaining: 0.0);
        timer.cancel();
      } else {
        state = state.copyWith(cooldownRemaining: remaining);
      }
    });
  }

  Future<void> calculateCalibrationIfReady() async {
    if (state.measurementsA.isNotEmpty && state.measurementsB.isNotEmpty) {
      final statsA = calculatePeriodStats(state.measurementsA, state.fitResidualExclusion);
      final statsB = calculatePeriodStats(state.measurementsB, state.fitResidualExclusion);

      if (statsA.average > 0 && statsB.average > 0) {
        final result = MomentOfInertiaCalculator.calibrateWithTwoObjects(
          statsA.average,
          state.knownObjectAInertia,
          statsB.average,
          state.knownObjectBInertia,
        );

        if (result.springConstant > 0) {
          await _prefs.saveCalibration(result.springConstant, result.deviceInertia);
          loadPreferences();
        }
      }
    }
  }

  Future<void> deleteMeasurement(Measurement measurement) async {
    if (measurement.id != null) {
      await _db.deleteMeasurement(measurement.id!);
      await refreshData();
    }
  }

  Future<void> deleteMeasurements(Set<int> ids) async {
    await _db.deleteMeasurementsByIds(ids.toList());
    await refreshData();
  }

  Future<void> recalibrate() async {
    await _db.deleteMeasurementsByType('OBJECT_A');
    await _db.deleteMeasurementsByType('OBJECT_B');
    await refreshCalibrationData();
  }

  Future<void> reTare() async {
    await _db.deleteMeasurementsByType('TARE_PB');
    await _db.deleteMeasurementsByType('TARE_TW');
    await refreshTareData();
  }

  Future<void> calculateTareIfReady(String type) async {
    final list = await _db.getMeasurementsByType(type);
    if (list.isNotEmpty) {
      final kappa = state.deviceKappa;
      final deviceI = state.deviceInertia;
      if (kappa > 0) {
        final stats = calculatePeriodStats(list, state.fitResidualExclusion);
        final moi = MomentOfInertiaCalculator.calculateObjectMOI(stats.average, kappa, deviceI);
        if (type == 'TARE_PB') {
          await _prefs.savePickleballTare(moi);
        } else if (type == 'TARE_TW') {
          await _prefs.saveTwistTare(moi);
        }
      }
    } else {
      if (type == 'TARE_PB') {
        await _prefs.savePickleballTare(0.0);
      } else if (type == 'TARE_TW') {
        await _prefs.saveTwistTare(0.0);
      }
    }
    loadPreferences();
  }

  void setTareMode(String mode) async {
    await _prefs.saveSelectedTareMode(mode);
    loadPreferences();
  }

  void selectMeasurement(Measurement? measurement) {
    state = state.copyWith(selectedMeasurement: () => measurement);
  }

  // --- Estimation Methods ---

  void setEstimationSearchQuery(String query) {
    state = state.copyWith(estimationSearchQuery: query);
    refreshEstimationGroups();
  }

  void selectEstimationGroup(int? groupId) async {
    if (groupId == null) {
      state = state.copyWith(
        selectedEstimationGroupId: () => null,
        currentEstimationGroup: () => null,
      );
    } else {
      final group = await _db.getEstimationGroupById(groupId);
      state = state.copyWith(
        selectedEstimationGroupId: () => groupId,
        currentEstimationGroup: () => group,
      );
    }
  }

  Future<void> addEstimationGroup(String name) async {
    final count = await _db.getEstimationGroupsCount();
    final finalName = name.trim().isEmpty ? 'Estimation ${count + 1}' : name;
    final id = await _db.insertEstimationGroup(EstimationGroup(name: finalName));
    await refreshEstimationGroups();
    selectEstimationGroup(id);
  }

  Future<void> deleteEstimationGroups(Set<int> ids) async {
    await _db.deleteEstimationGroupsByIds(ids.toList());
    await refreshEstimationGroups();
  }

  Future<void> renameEstimationGroup(EstimationGroup group, String newName) async {
    await _db.updateEstimationGroup(group.copyWith(name: newName));
    await refreshEstimationGroups();
  }

  Future<void> calculateAndSaveEstimation(
    EstimationGroup group,
    double m,
    String mUnit,
    double l,
    String lUnit,
    double w,
    String wUnit,
    double bp,
    String bpUnit,
    double r,
    String rUnit,
    String type,
  ) async {
    double massKg = m;
    if (mUnit == 'oz') massKg = m * 0.028349523125;
    if (mUnit == 'lb') massKg = m * 0.45359237;

    final lengthCm = lUnit == 'in' ? l * 2.54 : l;
    final widthCm = wUnit == 'in' ? w * 2.54 : w;
    final bpCm = bpUnit == 'in' ? bp * 2.54 : bp;
    final radiusCm = rUnit == 'in' ? r * 2.54 : r;
    final lengthInches = lUnit == 'cm' ? l / 2.54 : l;

    double sw = 0.0;
    double tw = 0.0;

    if (type == 'Pickleball Paddle') {
      sw = -259.5087 + (492.0045 * massKg) + (6.2811 * bpCm) + (6.8663 * lengthInches);
      tw = 0.075 * massKg * pow(widthCm, 2);
    } else {
      final f = type == 'MOI-5' ? 5.0 : 10.0;
      final d = bpCm - f;

      double swRadius = radiusCm;
      double twRadius = radiusCm;
      double sFactor = 0.0;
      double tFactor = 0.0;

      if (type == 'Racquet') {
        swRadius = 9.1;
        twRadius = 0.2584;
        sFactor = 0.0;
        tFactor = 0.13;
      }

      sw = (((1.0 / 12.0) * massKg * pow(lengthCm, 2)) +
              ((1.0 / 4.0) * massKg * pow(swRadius, 2)) +
              (massKg * pow(d, 2))) *
          (1.0 - sFactor);

      tw = (((1.0 / 12.0) * massKg * pow(widthCm, 2)) +
              ((1.0 / 4.0) * massKg * pow(twRadius, 2))) *
          (1.0 - tFactor);
    }

    final updated = group.copyWith(
      mass: m,
      massUnit: mUnit,
      length: l,
      lengthUnit: lUnit,
      width: w,
      widthUnit: wUnit,
      balancePoint: bp,
      bpUnit: bpUnit,
      radius: r,
      radiusUnit: rUnit,
      type: type,
      resultSW: sw,
      resultTW: tw,
    );

    await _db.updateEstimationGroup(updated);
    await refreshEstimationGroups();
  }

  // --- CSV Export/Import ---

  Future<String> exportMeasureToCsv() async {
    final groups = await _db.getAllGroups();
    final sb = StringBuffer();
    sb.writeln('Group Name,Type,Period (s),MOI (kg.cm2),Tare Mode,Raw Data,Cycle Periods,Total Duration,Timestamp,Mass,Mass Unit,Length,Length Unit,Width,Width Unit,Group Type,Fit Residual');

    for (var group in groups) {
      final measurements = await _db.getMeasurementsByGroup(group.id!);
      for (var m in measurements) {
        final row = [
          group.name,
          m.type,
          m.period.toString(),
          m.moi.toString(),
          m.tareMode,
          m.rawData,
          m.cyclePeriods,
          m.totalDuration.toString(),
          m.timestamp.toString(),
          group.mass.toString(),
          group.massUnit,
          group.length.toString(),
          group.lengthUnit,
          group.width.toString(),
          group.widthUnit,
          group.groupType,
          m.fitResidual.toString(),
        ];
        sb.writeln(row.map((f) => escapeCsvField(f)).join(','));
      }
    }
    return sb.toString();
  }

  Future<String> exportEstimateToCsv() async {
    final groups = await _db.getAllEstimationGroups();
    final sb = StringBuffer();
    sb.writeln('Group Name,Mass,Mass Unit,Length,Length Unit,Width,Width Unit,BP,BP Unit,Radius,Radius Unit,Type,SW,TW,Timestamp');

    for (var g in groups) {
      final row = [
        g.name,
        g.mass.toString(),
        g.massUnit,
        g.length.toString(),
        g.lengthUnit,
        g.width.toString(),
        g.widthUnit,
        g.balancePoint.toString(),
        g.bpUnit,
        g.radius.toString(),
        g.radiusUnit,
        g.type,
        g.resultSW.toString(),
        g.resultTW.toString(),
        g.timestamp.toString(),
      ];
      sb.writeln(row.map((f) => escapeCsvField(f)).join(','));
    }
    return sb.toString();
  }

  String escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    } else {
      return field;
    }
  }

  Future<void> importMeasureFromCsv(String csv) async {
    final lines = csv.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty || !lines[0].startsWith('Group Name,Type,Period (s)')) {
      state = state.copyWith(importError: () => 'The selected file is not a valid Measure database backup.');
      return;
    }

    for (var line in lines.skip(1)) {
      final parts = splitCsvLine(line);
      if (parts.length >= 9) {
        final groupName = parts[0];
        final type = parts[1];
        final period = double.tryParse(parts[2]) ?? 0.0;
        final moi = double.tryParse(parts[3]) ?? 0.0;
        final tareMode = parts[4];
        final rawData = parts[5];
        final cyclePeriods = parts[6];
        final totalDuration = double.tryParse(parts[7]) ?? 0.0;
        final timestamp = int.tryParse(parts[8]) ?? DateTime.now().millisecondsSinceEpoch;

        final mass = parts.length > 9 ? double.tryParse(parts[9]) ?? 0.0 : 0.0;
        final mUnit = parts.length > 10 ? parts[10] : 'oz';
        final length = parts.length > 11 ? double.tryParse(parts[11]) ?? 0.0 : 0.0;
        final lUnit = parts.length > 12 ? parts[12] : 'in';
        final width = parts.length > 13 ? double.tryParse(parts[13]) ?? 0.0 : 0.0;
        final wUnit = parts.length > 14 ? parts[14] : 'in';
        final gType = parts.length > 15 ? parts[15] : 'Pickleball Paddle';

        final residual = parts.length > 16 ? double.tryParse(parts[16]) ?? 0.0 : 0.0;

        final existingGroups = await _db.getAllGroups();
        MeasurementGroup? group;
        for (var g in existingGroups) {
          if (g.name == groupName) {
            group = g;
            break;
          }
        }

        if (group == null) {
          final id = await _db.insertGroup(MeasurementGroup(
            name: groupName,
            timestamp: timestamp,
            mass: mass,
            massUnit: mUnit,
            length: length,
            lengthUnit: lUnit,
            width: width,
            widthUnit: wUnit,
            groupType: gType,
          ));
          group = MeasurementGroup(
            id: id,
            name: groupName,
            timestamp: timestamp,
            mass: mass,
            massUnit: mUnit,
            length: length,
            lengthUnit: lUnit,
            width: width,
            widthUnit: wUnit,
            groupType: gType,
          );
        }

        await _db.insertMeasurement(Measurement(
          groupId: group.id,
          type: type,
          period: period,
          moi: moi,
          tareMode: tareMode,
          rawData: rawData,
          cyclePeriods: cyclePeriods,
          totalDuration: totalDuration,
          fitResidual: residual,
          timestamp: timestamp,
        ));
      }
    }
    await refreshData();
  }

  Future<void> importEstimateFromCsv(String csv) async {
    final lines = csv.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty || !lines[0].startsWith('Group Name,Mass,Mass Unit')) {
      state = state.copyWith(importError: () => 'The selected file is not a valid Estimate database backup.');
      return;
    }

    for (var line in lines.skip(1)) {
      final parts = splitCsvLine(line);
      if (parts.length >= 15) {
        await _db.insertEstimationGroup(EstimationGroup(
          name: parts[0],
          mass: double.tryParse(parts[1]) ?? 0.0,
          massUnit: parts[2],
          length: double.tryParse(parts[3]) ?? 0.0,
          lengthUnit: parts[4],
          width: double.tryParse(parts[5]) ?? 0.0,
          widthUnit: parts[6],
          balancePoint: double.tryParse(parts[7]) ?? 0.0,
          bpUnit: parts[8],
          radius: double.tryParse(parts[9]) ?? 9.1,
          radiusUnit: parts[10],
          type: parts[11],
          resultSW: double.tryParse(parts[12]) ?? 0.0,
          resultTW: double.tryParse(parts[13]) ?? 0.0,
          timestamp: int.tryParse(parts[14]) ?? DateTime.now().millisecondsSinceEpoch,
        ));
      }
    }
    await refreshEstimationGroups();
  }

  void clearImportError() {
    state = state.copyWith(importError: () => null);
  }

  List<String> splitCsvLine(String line) {
    final result = <String>[];
    final current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current.clear();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  @override
  void dispose() {
    _prepTimer?.cancel();
    _cooldownTimer?.cancel();
    _warmUpTimer?.cancel();
    _detector?.dispose();
    super.dispose();
  }
}
