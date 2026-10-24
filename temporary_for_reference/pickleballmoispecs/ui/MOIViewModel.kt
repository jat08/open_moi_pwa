package com.example.pickleballmoispecs.ui

import android.app.Application
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.pickleballmoispecs.data.*
import com.example.pickleballmoispecs.logic.MomentOfInertiaCalculator
import com.example.pickleballmoispecs.logic.OscillationDetector
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

import java.util.Locale
import kotlin.math.*

class MOIViewModel(application: Application) : AndroidViewModel(application) {

    private val sensorManager = application.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    val appPreferences = AppPreferences(application)
    private val dao = AppDatabase.getDatabase(application).measurementDao()

    private val oscillationDetector = OscillationDetector(
        onStateChanged = { state ->
            _uiState.update { it.copy(detectorState = state) }
        },
        onMeasurementComplete = { result ->
            handleMeasurementComplete(result)
        },
    ) { progress ->
        _uiState.update { it.copy(progress = progress) }
    }

    private val _uiState = MutableStateFlow(UiState())
    val uiState: StateFlow<UiState> = _uiState.asStateFlow()

    private val _importError = MutableSharedFlow<String>()
    val importError: SharedFlow<String> = _importError.asSharedFlow()

    private var cooldownJob: Job? = null

    enum class SortType { NAME, DATE }
    enum class SortDirection { ASCENDING, DESCENDING }

    data class UiState(
        val detectorState: OscillationDetector.State = OscillationDetector.State.WRONG_ORIENTATION,
        val progress: Float = 0f,
        val lastMeasuredPeriod: Double = 0.0,
        val calculatedMOI: Double = 0.0,
        val calibrationTarget: CalibrationTarget = CalibrationTarget.NONE,
        val selectedCalibrationTarget: CalibrationTarget? = null,
        val measurementsA: List<Measurement> = emptyList(),
        val measurementsB: List<Measurement> = emptyList(),
        val selectedGroupId: Int? = null,
        val selectedGroupMeasurements: List<Measurement> = emptyList(),
        val groups: List<GroupSummary> = emptyList(),
        val searchQuery: String = "",
        val sortType: SortType = SortType.DATE,
        val sortDirection: SortDirection = SortDirection.ASCENDING,
        val isCalibrated: Boolean = false,
        val deviceKappa: Double = 0.0,
        val deviceInertia: Double = 0.0,
        val themeMode: ThemeMode = ThemeMode.SYSTEM,
        val moiUnitsResolution: Int = 1,
        val periodUnitsResolution: Int = 4,
        
        // Detailed stats for currently selected paddle group
        val currentSWAverage: Double = 0.0,
        val currentSWStdDev: Double = 0.0,
        val currentTWAverage: Double = 0.0,
        val currentTWStdDev: Double = 0.0,
        
        val currentSWPeriodAverage: Double = 0.0,
        val currentSWPeriodTheoAverage: Double = 0.0,
        val currentSWPeriodStdDev: Double = 0.0,
        val currentSWPeriodTheoStdDev: Double = 0.0,
        val currentTWPeriodAverage: Double = 0.0,
        val currentTWPeriodTheoAverage: Double = 0.0,
        val currentTWPeriodStdDev: Double = 0.0,
        val currentTWPeriodTheoStdDev: Double = 0.0,
        
        // Detailed stats for calibration (PERIOD focus)
        val currentCalibrationPeriodAverage: Double = 0.0,
        val currentCalibrationPeriodTheoAverage: Double = 0.0,
        val currentCalibrationPeriodStdDev: Double = 0.0,
        val currentCalibrationPeriodTheoStdDev: Double = 0.0,
        
        // Tare values
        val measurementsTarePB: List<Measurement> = emptyList(),
        val measurementsTareTW: List<Measurement> = emptyList(),
        val selectedTareMode: String = "NONE",
        val pickleballTareOffset: Double = 0.0,
        val twistTareOffset: Double = 0.0,
        
        // Timing settings
        val measuringDuration: Double = 8.0,
        val waitDuration: Double = 6.0,
        val cyclesToMeasure: Int = 5,
        val swMargin: Double = 0.003,
        val twMargin: Double = 0.01,
        val fitResidualExclusion: Double = 1.0,
        val trimLastCycle: Boolean = true,
        val skipFirstCycles: Int = 0,
    
        val cycleReference: Int = 0,
        val keepScreenOn: Boolean = false,
        val preparationTime: Int = 2,
        val preparationRemaining: Int = 0,
        val cooldownRemaining: Double = 0.0,
        
        // Detail View Selection
        val selectedMeasurement: Measurement? = null,
        val editingAttributesGroupId: Int? = null,
        val currentAttributeGroup: MeasurementGroup? = null,
        val editingExpectedValueTarget: CalibrationTarget? = null,
        
        // Expected Values (Calibration)
        val knownObjectAInertia: Double = 0.0,
        val knownObjectBInertia: Double = 0.0,
        val expectedPeriodA: Double = 0.6947,
        val expectedPeriodB: Double = 0.2607,
        val expectedMoiPB: Double = 1.16,
        val expectedMoiTW: Double = 2.16,
        
        // --- Estimation State ---
        val estimationSearchQuery: String = "",
        val selectedEstimationGroupId: Int? = null,
        val estimationGroups: List<EstimationGroup> = emptyList(),
        val currentEstimationGroup: EstimationGroup? = null,
        
        // NFC State
        val isNfcScanning: Boolean = false,
        val nfcEnabled: Boolean = true,
        val nfcStatus: String? = null
    )

    data class GroupSummary(
        val group: MeasurementGroup,
        val count: Int,
        val avgSW: Double,
        val stdDevSW: Double,
        val avgTW: Double,
        val stdDevTW: Double
    )

    enum class CalibrationTarget {
        NONE, OBJECT_A, OBJECT_B, TARE_PB, TARE_TW
    }

    init {
        registerSensors()
        observePreferences()
        observeData()
    }

    private fun registerSensors() {
        val accel = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        val gyro = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
        sensorManager.registerListener(oscillationDetector, accel, SensorManager.SENSOR_DELAY_FASTEST)
        sensorManager.registerListener(oscillationDetector, gyro, SensorManager.SENSOR_DELAY_FASTEST)
    }

    private fun observePreferences() {
        viewModelScope.launch {
            appPreferences.themeMode.collect { mode ->
                _uiState.update { it.copy(themeMode = mode) }
            }
        }
        viewModelScope.launch {
            appPreferences.moiUnitsResolution.collect { res ->
                _uiState.update { it.copy(moiUnitsResolution = res) }
            }
        }
        viewModelScope.launch {
            appPreferences.periodUnitsResolution.collect { res ->
                _uiState.update { it.copy(periodUnitsResolution = res) }
            }
        }
        viewModelScope.launch {
            appPreferences.deviceKappa.collect { kappa ->
                _uiState.update { it.copy(deviceKappa = kappa) }
            }
        }
        viewModelScope.launch {
            appPreferences.deviceInertia.collect { inertia ->
                _uiState.update { it.copy(deviceInertia = inertia) }
            }
        }
        viewModelScope.launch {
            combine(
                appPreferences.knownObjectAInertia,
                appPreferences.knownObjectBInertia
            ) { _, _ -> }.collect {
                calculateCalibrationIfReady()
            }
        }
        viewModelScope.launch {
            combine(
                _uiState.map { it.measurementsA }.distinctUntilChanged(),
                _uiState.map { it.measurementsB }.distinctUntilChanged()
            ) { a, b ->
                a.isNotEmpty() && b.isNotEmpty()
            }.collect { calibrated ->
                _uiState.update { it.copy(isCalibrated = calibrated) }
            }
        }
        viewModelScope.launch {
            appPreferences.pickleballTare.collect { tare ->
                _uiState.update { it.copy(pickleballTareOffset = tare) }
            }
        }
        viewModelScope.launch {
            appPreferences.twistTare.collect { tare ->
                _uiState.update { it.copy(twistTareOffset = tare) }
            }
        }
        viewModelScope.launch {
            appPreferences.selectedTareMode.collect { mode ->
                _uiState.update { it.copy(selectedTareMode = mode) }
            }
        }
        viewModelScope.launch {
            appPreferences.sortType.collect { type ->
                _uiState.update { it.copy(sortType = SortType.valueOf(type)) }
            }
        }
        viewModelScope.launch {
            appPreferences.sortDirection.collect { dir ->
                _uiState.update { it.copy(sortDirection = SortDirection.valueOf(dir)) }
            }
        }
        viewModelScope.launch {
            appPreferences.measuringDuration.collect { duration ->
                _uiState.update { it.copy(measuringDuration = duration) }
                oscillationDetector.setMaxDuration(duration)
            }
        }
        viewModelScope.launch {
            appPreferences.waitDuration.collect { duration ->
                _uiState.update { it.copy(waitDuration = duration) }
            }
        }
        viewModelScope.launch {
            appPreferences.cyclesToMeasure.collect { count ->
                _uiState.update { it.copy(cyclesToMeasure = count) }
                oscillationDetector.setRequiredCycles(count)
            }
        }
        viewModelScope.launch {
            appPreferences.swMargin.collect { margin ->
                _uiState.update { it.copy(swMargin = margin) }
            }
        }
        viewModelScope.launch {
            appPreferences.twMargin.collect { margin ->
                _uiState.update { it.copy(twMargin = margin) }
            }
        }
        viewModelScope.launch {
            appPreferences.fitResidualExclusion.collect { threshold ->
                _uiState.update { it.copy(fitResidualExclusion = threshold) }
                recalculateAllCalculations()
            }
        }
        viewModelScope.launch {
            appPreferences.keepScreenOn.collect { keepOn ->
                _uiState.update { it.copy(keepScreenOn = keepOn) }
            }
        }
        viewModelScope.launch {
            appPreferences.preparationTime.collect { time ->
                _uiState.update { it.copy(preparationTime = time) }
            }
        }
        viewModelScope.launch {
            appPreferences.expectedPeriodA.collect { v -> _uiState.update { it.copy(expectedPeriodA = v) } }
        }
        viewModelScope.launch {
            appPreferences.expectedPeriodB.collect { v -> _uiState.update { it.copy(expectedPeriodB = v) } }
        }
        viewModelScope.launch {
            appPreferences.expectedMoiPB.collect { v -> _uiState.update { it.copy(expectedMoiPB = v) } }
        }
        viewModelScope.launch {
            appPreferences.expectedMoiTW.collect { v -> _uiState.update { it.copy(expectedMoiTW = v) } }
        }
        viewModelScope.launch {
            appPreferences.trimLastCycle.collect { v ->
                _uiState.update { it.copy(trimLastCycle = v) }
                recalculateAllCalculations()
            }
        }
        viewModelScope.launch {
            appPreferences.skipFirstCycles.collect { count ->
                _uiState.update { it.copy(skipFirstCycles = count) }
                oscillationDetector.setSkipFirstCycles(count)
            }
        }
        viewModelScope.launch {
            appPreferences.knownObjectAInertia.collect { v -> _uiState.update { it.copy(knownObjectAInertia = v) } }
        }
        viewModelScope.launch {
            appPreferences.knownObjectBInertia.collect { v -> _uiState.update { it.copy(knownObjectBInertia = v) } }
        }

        viewModelScope.launch {
            appPreferences.cycleReference.collect { v -> _uiState.update { it.copy(cycleReference = v) } }
        }
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    private fun observeData() {
        // Observe Groups with sorting and measurements (Reactive summaries)
        viewModelScope.launch {
            combine(
                _uiState.map { it.searchQuery }.distinctUntilChanged(),
                _uiState.map { it.sortType }.distinctUntilChanged(),
                _uiState.map { it.sortDirection }.distinctUntilChanged()
            ) { query, type, dir ->
                Triple(query, type, dir)
            }.flatMapLatest { (query, type, dir) ->
                val baseFlow = if (query.isEmpty()) dao.getAllGroups() else dao.searchGroups(query)
                baseFlow.map { groups ->
                    when (type) {
                        SortType.NAME -> if (dir == SortDirection.ASCENDING) groups.sortedBy { it.name } else groups.sortedByDescending { it.name }
                        SortType.DATE -> if (dir == SortDirection.ASCENDING) groups.sortedBy { it.timestamp } else groups.sortedByDescending { it.timestamp }
                    }
                }
            }.flatMapLatest { sortedGroups ->
                if (sortedGroups.isEmpty()) flowOf(emptyList())
                else {
                    val summaryFlows = sortedGroups.map { group ->
                        dao.getMeasurementsByGroup(group.id).map { measurements ->
                            val swStats = calculateStats(measurements.filter { it.moi >= 40 }, 10.0) // No filtering in summary
                            val twStats = calculateStats(measurements.filter { it.moi < 40 }, 10.0)
                            GroupSummary(
                                group = group,
                                count = measurements.size,
                                avgSW = swStats.average,
                                stdDevSW = swStats.stdDev,
                                avgTW = twStats.average,
                                stdDevTW = twStats.stdDev
                            )
                        }
                    }
                    combine(summaryFlows) { it.toList() }
                }
            }.collect { summaries ->
                _uiState.update { it.copy(groups = summaries) }
            }
        }

        // Observe Calibration
        viewModelScope.launch {
            dao.getMeasurementsByType("OBJECT_A").collect { list ->
                _uiState.update { it.copy(measurementsA = list.sortedByDescending { m -> m.timestamp }) }
                calculateCalibrationIfReady()
                updateCalibrationStats()
            }
        }
        viewModelScope.launch {
            dao.getMeasurementsByType("OBJECT_B").collect { list ->
                _uiState.update { it.copy(measurementsB = list.sortedByDescending { m -> m.timestamp }) }
                calculateCalibrationIfReady()
                updateCalibrationStats()
            }
        }
        
        // Observe Tares
        viewModelScope.launch {
            dao.getMeasurementsByType("TARE_PB").collect { list ->
                _uiState.update { it.copy(measurementsTarePB = list.sortedByDescending { m -> m.timestamp }) }
                calculateTareIfReady("TARE_PB")
                updateCalibrationStats()
            }
        }
        viewModelScope.launch {
            dao.getMeasurementsByType("TARE_TW").collect { list ->
                _uiState.update { it.copy(measurementsTareTW = list.sortedByDescending { it.timestamp }) }
                calculateTareIfReady("TARE_TW")
                updateCalibrationStats()
            }
        }

        // Observe Selected Group
        viewModelScope.launch {
            _uiState.map { it.selectedGroupId }.distinctUntilChanged().collectLatest { groupId ->
                groupId?.let { id ->
                    dao.getMeasurementsByGroup(id).collect { list ->
                        _uiState.update { it.copy(selectedGroupMeasurements = list.sortedByDescending { m -> m.timestamp }) }
                        updateStatsForSelectedGroup()
                    }
                }
            }
        }

        // Observe Editing Attributes Group
        viewModelScope.launch {
            _uiState.map { it.editingAttributesGroupId }.distinctUntilChanged().collectLatest { id ->
                if (id != null) {
                    dao.getGroupById(id).collect { group ->
                        _uiState.update { it.copy(currentAttributeGroup = group) }
                    }
                }
            }
        }

        // Observe Estimation Groups (Search & Sort)
        viewModelScope.launch {
            combine(
                _uiState.map { it.estimationSearchQuery }.distinctUntilChanged(),
                _uiState.map { it.sortType }.distinctUntilChanged(),
                _uiState.map { it.sortDirection }.distinctUntilChanged()
            ) { query, type, dir ->
                Triple(query, type, dir)
            }.flatMapLatest { (query, type, dir) ->
                val baseFlow = if (query.isEmpty()) dao.getAllEstimationGroups() else dao.searchEstimationGroups(query)
                baseFlow.map { groups ->
                    when (type) {
                        SortType.NAME -> if (dir == SortDirection.ASCENDING) groups.sortedBy { it.name } else groups.sortedByDescending { it.name }
                        SortType.DATE -> if (dir == SortDirection.ASCENDING) groups.sortedBy { it.timestamp } else groups.sortedByDescending { it.timestamp }
                    }
                }
            }.collect { list ->
                _uiState.update { it.copy(estimationGroups = list) }
            }
        }

        // Observe Selected Estimation Group
        viewModelScope.launch {
            _uiState.map { it.selectedEstimationGroupId }.distinctUntilChanged().collectLatest { id ->
                id?.let {
                    dao.getEstimationGroupById(it).collect { group ->
                        _uiState.update { it.copy(currentEstimationGroup = group) }
                    }
                }
            }
        }
    }

    private fun updateStatsForSelectedGroup() {
        val state = uiState.value
        if (state.selectedGroupId == null) return
        
        val measurements = state.selectedGroupMeasurements
        val swMeasurements = measurements.filter { it.moi >= 40 }
        val twMeasurements = measurements.filter { it.moi < 40 }

        val swStats = calculateStats(swMeasurements, state.fitResidualExclusion)
        val twStats = calculateStats(twMeasurements, state.fitResidualExclusion)
        
        val swPeriodStats = calculatePeriodStats(swMeasurements, state.fitResidualExclusion)
        val twPeriodStats = calculatePeriodStats(twMeasurements, state.fitResidualExclusion)

        _uiState.update { it.copy(
            currentSWAverage = swStats.average,
            currentSWStdDev = swStats.stdDev,
            currentTWAverage = twStats.average,
            currentTWStdDev = twStats.stdDev,
            currentSWPeriodAverage = swPeriodStats.average,
            currentSWPeriodStdDev = swPeriodStats.stdDev,
            currentTWPeriodAverage = twPeriodStats.average,
            currentTWPeriodStdDev = twPeriodStats.stdDev
        ) }
    }

    private fun updateCalibrationStats() {
        val state = uiState.value
        val target = state.selectedCalibrationTarget ?: return
        
        val measurements = when (target) {
            CalibrationTarget.OBJECT_A -> state.measurementsA
            CalibrationTarget.OBJECT_B -> state.measurementsB
            CalibrationTarget.TARE_PB -> state.measurementsTarePB
            CalibrationTarget.TARE_TW -> state.measurementsTareTW
            else -> emptyList()
        }
        
        val stats = calculatePeriodStats(measurements, state.fitResidualExclusion)
        _uiState.update { it.copy(
            currentCalibrationPeriodAverage = stats.average,
            currentCalibrationPeriodStdDev = stats.stdDev
        ) }
    }

    private fun recalculateAllCalculations() {
        viewModelScope.launch {
            updateStatsForSelectedGroup()
            updateCalibrationStats()
            calculateCalibrationIfReady()
            calculateTareIfReady("TARE_PB")
            calculateTareIfReady("TARE_TW")
        }
    }

    data class Stats(val average: Double, val stdDev: Double)

    private fun calculateStats(measurements: List<Measurement>, fitThreshold: Double): Stats {
        if (measurements.isEmpty()) return Stats(0.0, 0.0)
        
        // Quality Filter: Ignore Fit Residual >= threshold
        val qualityList = measurements.asSequence().filter { it.fitResidual < fitThreshold }.toList()
        
        if (qualityList.isEmpty()) return Stats(0.0, 0.0)

        val finalAverage = qualityList.asSequence().map { m -> m.moi }.average()
        
        val variance = qualityList.asSequence().map { m ->
            (m.moi - finalAverage).let { d -> d * d }
        }.average()
        
        val stdDev = sqrt(variance)
        return Stats(finalAverage, stdDev)
    }

    private fun calculatePeriodStats(measurements: List<Measurement>, fitThreshold: Double): Stats {
        if (measurements.isEmpty()) return Stats(0.0, 0.0)
        
        // Quality Filter: Ignore Fit Residual >= threshold
        val qualityList = measurements.asSequence().filter { it.fitResidual < fitThreshold }.toList()
        
        if (qualityList.isEmpty()) return Stats(0.0, 0.0)

        val finalAverage = qualityList.asSequence().map { m -> m.period }.average()
        
        val variance = qualityList.asSequence().map { m ->
            (m.period - finalAverage).let { d -> d * d }
        }.average()
        
        val stdDev = sqrt(variance)
        return Stats(finalAverage, stdDev)
    }

    fun setSearchQuery(query: String) {
        _uiState.update { it.copy(searchQuery = query) }
    }

    fun setSortOrder(type: SortType, direction: SortDirection) {
        viewModelScope.launch {
            appPreferences.saveSortType(type.name)
            appPreferences.saveSortDirection(direction.name)
        }
    }

    fun selectGroup(groupId: Int?) {
        if (groupId == null) {
            _uiState.update { it.copy(
                selectedGroupId = null,
                selectedGroupMeasurements = emptyList(),
                selectedCalibrationTarget = null,
                calibrationTarget = CalibrationTarget.NONE,
                currentSWAverage = 0.0,
                currentSWStdDev = 0.0,
                currentTWAverage = 0.0,
                currentTWStdDev = 0.0,
                currentSWPeriodAverage = 0.0,
                currentSWPeriodStdDev = 0.0,
                currentTWPeriodAverage = 0.0,
                currentTWPeriodStdDev = 0.0
            ) }
        } else {
            viewModelScope.launch {
                val list = dao.getMeasurementsByGroup(groupId).first()
                val measurements = list.sortedByDescending { m -> m.timestamp }
                val swMeasurements = measurements.filter { it.moi >= 40 }
                val twMeasurements = measurements.filter { it.moi < 40 }

                val swStats = calculateStats(swMeasurements, uiState.value.fitResidualExclusion)
                val twStats = calculateStats(twMeasurements, uiState.value.fitResidualExclusion)
                
                val swPeriodStats = calculatePeriodStats(swMeasurements, uiState.value.fitResidualExclusion)
                val twPeriodStats = calculatePeriodStats(twMeasurements, uiState.value.fitResidualExclusion)

                _uiState.update { it.copy(
                    selectedGroupId = groupId,
                    selectedGroupMeasurements = measurements,
                    selectedCalibrationTarget = null,
                    calibrationTarget = CalibrationTarget.NONE,
                    currentSWAverage = swStats.average,
                    currentSWStdDev = swStats.stdDev,
                    currentTWAverage = twStats.average,
                    currentTWStdDev = twStats.stdDev,
                    currentSWPeriodAverage = swPeriodStats.average,
                    currentSWPeriodStdDev = swPeriodStats.stdDev,
                    currentTWPeriodAverage = twPeriodStats.average,
                    currentTWPeriodStdDev = twPeriodStats.stdDev
                ) }
            }
        }
    }

    fun selectCalibrationTarget(target: CalibrationTarget?) {
        _uiState.update { it.copy(
            selectedCalibrationTarget = target, 
            calibrationTarget = target ?: CalibrationTarget.NONE,
            selectedGroupId = null
        ) }
        updateCalibrationStats()
    }

    fun addGroup(name: String) {
        viewModelScope.launch {
            val finalName = name.ifBlank {
                "Group ${dao.getGroupCount() + 1}"
            }
            val id = dao.insertGroup(MeasurementGroup(name = finalName))
            selectGroup(id.toInt())
        }
    }

    fun renameGroup(group: MeasurementGroup, newName: String) {
        viewModelScope.launch {
            dao.updateGroup(group.copy(name = newName))
        }
    }

    fun deleteGroups(ids: Set<Int>) {
        viewModelScope.launch {
            dao.deleteGroupsByIds(ids.toList())
        }
    }

    fun selectEditingAttributesGroup(groupId: Int?) {
        _uiState.update { it.copy(editingAttributesGroupId = groupId) }
    }

    fun updateGroupAttributes(
        group: MeasurementGroup,
        m: Double, mUnit: String,
        l: Double, lUnit: String,
        w: Double, wUnit: String,
        type: String
    ) {
        viewModelScope.launch {
            dao.updateGroup(group.copy(
                mass = m, massUnit = mUnit,
                length = l, lengthUnit = lUnit,
                width = w, widthUnit = wUnit,
                groupType = type
            ))
        }
    }

    fun selectEditingExpectedValue(target: CalibrationTarget?) {
        _uiState.update { it.copy(editingExpectedValueTarget = target) }
    }

    fun updateExpectedValue(target: CalibrationTarget, value: Double) {
        viewModelScope.launch {
            appPreferences.saveExpectedValue(target.name, value)
            selectEditingExpectedValue(null)
        }
    }

    fun startMeasurement() {
        if (uiState.value.cooldownRemaining > 0) return
        
        val prepTime = uiState.value.preparationTime
        if (prepTime > 0) {
            viewModelScope.launch {
                var remaining = prepTime
                while (remaining > 0) {
                    _uiState.update { it.copy(preparationRemaining = remaining) }
                    delay(timeMillis = 1000L)
                    remaining--
                }
                _uiState.update { it.copy(preparationRemaining = 0) }
                oscillationDetector.arm()
            }
        } else {
            oscillationDetector.arm()
        }
    }

    private fun handleMeasurementComplete(result: OscillationDetector.Result) {
        viewModelScope.launch {
            val state = uiState.value
            val kappa = state.deviceKappa
            val deviceI = state.deviceInertia
            val trimLast = state.trimLastCycle
            
            // PHYSICS: High-Precision Hardware-Locked Timing
            // 1. Extract high-precision cycle durations
            val rawCycles = result.cyclePeriods.split(",").asSequence().filter { it.isNotEmpty() }.map { it.toDouble() }.toList()
            
            if (rawCycles.isNotEmpty()) {
                // Precise Measured Period (Total Time / Cycles)
                // This preserves hardware precision by cancelling intermediate jitter
                val rawPeriod = if (trimLast && rawCycles.size > 1) {
                    rawCycles.dropLast(1).average()
                } else {
                    rawCycles.average()
                }

                // Uniform Measured Cycles for UI consistency (fixes "error stacking" visual)
                // All entries in the analysis table will show the same high-precision average
                val uniformMeasuredCycles = List(rawCycles.size) { String.format(Locale.US, "%.6f", rawPeriod) }.joinToString(",")

                val residual = calculateFitResidual(result.rawData, rawPeriod, result.totalDuration)
                
                when (state.calibrationTarget) {
                    CalibrationTarget.OBJECT_A -> {
                        dao.insertMeasurement(Measurement(
                            type = "OBJECT_A", 
                            period = rawPeriod, 
                            moi = 0.0,
                            rawData = result.rawData,
                            cyclePeriods = uniformMeasuredCycles,
                            totalDuration = result.totalDuration,
                            fitResidual = residual
                        ))
                    }
                    CalibrationTarget.OBJECT_B -> {
                        dao.insertMeasurement(Measurement(
                            type = "OBJECT_B", 
                            period = rawPeriod, 
                            moi = 0.0,
                            rawData = result.rawData,
                            cyclePeriods = uniformMeasuredCycles,
                            totalDuration = result.totalDuration,
                            fitResidual = residual
                        ))
                    }
                    CalibrationTarget.TARE_PB -> {
                        val physicalMoi = MomentOfInertiaCalculator.calculateObjectMOI(rawPeriod, kappa, deviceI)
                        dao.insertMeasurement(Measurement(
                            type = "TARE_PB", 
                            period = rawPeriod, 
                            moi = physicalMoi,
                            rawData = result.rawData,
                            cyclePeriods = uniformMeasuredCycles,
                            totalDuration = result.totalDuration,
                            fitResidual = residual
                        ))
                    }
                    CalibrationTarget.TARE_TW -> {
                        val physicalMoi = MomentOfInertiaCalculator.calculateObjectMOI(rawPeriod, kappa, deviceI)
                        dao.insertMeasurement(Measurement(
                            type = "TARE_TW", 
                            period = rawPeriod, 
                            moi = physicalMoi,
                            rawData = result.rawData,
                            cyclePeriods = uniformMeasuredCycles,
                            totalDuration = result.totalDuration,
                            fitResidual = residual
                        ))
                    }
                    CalibrationTarget.NONE -> {
                        val rawMoi = MomentOfInertiaCalculator.calculateObjectMOI(rawPeriod, kappa, deviceI)
                        
                        val tareMode = state.selectedTareMode
                        val tareOffset = when (tareMode) {
                            "PICKLEBALL" -> state.pickleballTareOffset
                            "TWIST" -> state.twistTareOffset
                            else -> 0.0
                        }
                        
                        val finalMoi = (rawMoi - tareOffset).coerceAtLeast(0.0)
                        
                        val modeAbbr = when (tareMode) {
                            "PICKLEBALL" -> "PB"
                            "TWIST" -> "TW"
                            else -> "None"
                        }
                        
                        if (state.selectedGroupId != null) {
                            dao.insertMeasurement(Measurement(
                                groupId = state.selectedGroupId,
                                type = "PADDLE",
                                period = rawPeriod,
                                moi = finalMoi,
                                tareMode = modeAbbr,
                                rawData = result.rawData,
                                cyclePeriods = uniformMeasuredCycles,
                                totalDuration = result.totalDuration,
                                fitResidual = residual
                            ))
                        }
                        _uiState.update { it.copy(calculatedMOI = finalMoi) }
                    }
                }
            }
            startCooldown()
        }
    }

    private fun calculateFitResidual(rawData: String, period: Double, totalDuration: Double): Double {
        if (period <= 0) return 1.0
        val points = rawData.split(",").filter { it.isNotEmpty() }.map { it.toDouble() }
        if (points.isEmpty()) return 1.0
        
        val maxAmp = points.maxOfOrNull { abs(it) } ?: 1.0
        if (maxAmp == 0.0) return 1.0
        
        // Estimate initial phase (phi) to account for measurement start delay
        // We use a small window (first 3 points) to determine the initial slope more robustly
        val y0 = points[0].coerceIn(-maxAmp, maxAmp)
        var phi = kotlin.math.asin(y0 / maxAmp)
        
        // Robust Direction Detection (Multi-Sample Confirmation)
        var initialSlope = 0.0
        val motionThreshold = 0.05 * maxAmp // 5% noise margin
        var upCount = 0
        var downCount = 0
        val confirmationRequired = 5 // Must stay beyond threshold for 5 consecutive samples
        
        for (i in 1 until points.size) {
            val yi = points[i]
            
            if (y0 >= 0) { // Started high or at center
                if (yi > (y0 + motionThreshold)) {
                    upCount++; downCount = 0
                } else if (yi < y0 - motionThreshold || yi < -motionThreshold) {
                    downCount++; upCount = 0
                } else {
                    upCount = 0; downCount = 0
                }
            } else { // Started low
                if (yi < y0 - motionThreshold) {
                    downCount++; upCount = 0
                } else if (yi > y0 + motionThreshold || yi > motionThreshold) {
                    upCount++; downCount = 0
                } else {
                    upCount = 0; downCount = 0
                }
            }

            if (upCount >= confirmationRequired) {
                initialSlope = 1.0; break
            }
            if (downCount >= confirmationRequired) {
                initialSlope = -1.0; break
            }
        }
        
        // Final fallback to simple check
        if (initialSlope == 0.0 && points.size > 1) {
            initialSlope = points[1] - points[0]
        }

        if (initialSlope < 0) {
            phi = PI - phi
        }

        var totalError = 0.0
        points.forEachIndexed { index, actual ->
            val time = (index.toDouble() / (points.size - 1).coerceAtLeast(1)) * totalDuration
            val theoretical = maxAmp * sin(2.0 * PI * time / period + phi)
            totalError += abs(actual - theoretical)
        }
        
        val avgError = totalError / points.size
        // Scale so that 10% error = 1.0
        return (avgError / maxAmp) * 10.0
    }



    private fun startCooldown() {
        cooldownJob?.cancel()
        cooldownJob = viewModelScope.launch {
            val totalWait = uiState.value.waitDuration
            var remaining = totalWait
            while (remaining > 0) {
                _uiState.update { it.copy(cooldownRemaining = remaining) }
                delay(100)
                remaining -= 0.1
            }
            _uiState.update { it.copy(cooldownRemaining = 0.0) }
        }
    }

    private suspend fun calculateCalibrationIfReady() {
        val state = uiState.value
        if (state.measurementsA.isNotEmpty() && state.measurementsB.isNotEmpty()) {
            val statsA = calculatePeriodStats(state.measurementsA, state.fitResidualExclusion)
            val statsB = calculatePeriodStats(state.measurementsB, state.fitResidualExclusion)
            
            if (statsA.average > 0 && statsB.average > 0) {
                val inertiaA = appPreferences.knownObjectAInertia.first()
                val inertiaB = appPreferences.knownObjectBInertia.first()
                
                val result = MomentOfInertiaCalculator.calibrateWithTwoObjects(statsA.average, inertiaA, statsB.average, inertiaB)
                if (result.springConstant > 0) {
                    appPreferences.saveCalibration(result.springConstant, result.deviceInertia)
                }
            }
        }
    }

    fun deleteMeasurement(measurement: Measurement) {
        viewModelScope.launch {
            dao.deleteMeasurement(measurement)
        }
    }

    fun deleteMeasurements(ids: Set<Int>) {
        viewModelScope.launch {
            dao.deleteMeasurementsByIds(ids.toList())
        }
    }

    fun recalibrate() {
        viewModelScope.launch {
            dao.deleteMeasurementsByType("OBJECT_A")
            dao.deleteMeasurementsByType("OBJECT_B")
        }
    }

    fun reTare() {
        viewModelScope.launch {
            dao.deleteMeasurementsByType("TARE_PB")
            dao.deleteMeasurementsByType("TARE_TW")
        }
    }

    private fun calculateTareIfReady(type: String) {
        viewModelScope.launch {
            val measurements = dao.getMeasurementsByType(type).first()
            if (measurements.isNotEmpty()) {
                val kappa = appPreferences.deviceKappa.first()
                val deviceI = appPreferences.deviceInertia.first()
                if (kappa > 0) {
                    val stats = calculatePeriodStats(measurements, uiState.value.fitResidualExclusion)
                    val moi = MomentOfInertiaCalculator.calculateObjectMOI(stats.average, kappa, deviceI)
                    if (type == "TARE_PB") {
                        appPreferences.savePickleballTare(moi)
                    } else if (type == "TARE_TW") {
                        appPreferences.saveTwistTare(moi)
                    }
                }
            } else {
                // Reset to zero if list is empty
                if (type == "TARE_PB") {
                    appPreferences.savePickleballTare(0.0)
                } else if (type == "TARE_TW") {
                    appPreferences.saveTwistTare(0.0)
                }
            }
        }
    }

    fun setTareMode(mode: String) {
        viewModelScope.launch {
            appPreferences.saveSelectedTareMode(mode)
        }
    }
    
    fun selectMeasurement(measurement: Measurement?) {
        _uiState.update { it.copy(selectedMeasurement = measurement) }
    }

    // --- Estimation Logic ---

    fun setEstimationSearchQuery(query: String) {
        _uiState.update { it.copy(estimationSearchQuery = query) }
    }

    fun selectEstimationGroup(groupId: Int?) {
        if (groupId == null) {
            _uiState.update { it.copy(
                selectedEstimationGroupId = null,
                currentEstimationGroup = null
            ) }
        } else {
            val group = uiState.value.estimationGroups.find { it.id == groupId }
            _uiState.update { it.copy(
                selectedEstimationGroupId = groupId,
                currentEstimationGroup = group
            ) }
            viewModelScope.launch {
                val dbGroup = dao.getEstimationGroupById(groupId).first()
                _uiState.update { it.copy(currentEstimationGroup = dbGroup) }
            }
        }
    }

    fun addEstimationGroup(name: String) {
        viewModelScope.launch {
            val finalName = name.ifBlank { "Estimation ${dao.getEstimationGroupsCount() + 1}" }
            val id = dao.insertEstimationGroup(EstimationGroup(name = finalName))
            selectEstimationGroup(id.toInt())
        }
    }

    fun deleteEstimationGroups(ids: Set<Int>) {
        viewModelScope.launch {
            dao.deleteEstimationGroupsByIds(ids.toList())
        }
    }

    fun renameEstimationGroup(group: EstimationGroup, newName: String) {
        viewModelScope.launch {
            dao.updateEstimationGroup(group.copy(name = newName))
        }
    }

    fun calculateAndSaveEstimation(
        group: EstimationGroup,
        m: Double, mUnit: String,
        l: Double, lUnit: String,
        w: Double, wUnit: String,
        bp: Double, bpUnit: String,
        r: Double, rUnit: String,
        type: String
    ) {
        viewModelScope.launch {
            // Units to standard SI
            val massKg = when (mUnit) {
                "oz" -> m * 0.028349523125
                "lb" -> m * 0.45359237
                else -> m
            }
            val lengthCm = if (lUnit == "in") l * 2.54 else l
            val widthCm = if (wUnit == "in") w * 2.54 else w
            val bpCm = if (bpUnit == "in") bp * 2.54 else bp
            val radiusCm = if (rUnit == "in") r * 2.54 else r
            val lengthInches = if (lUnit == "cm") l / 2.54 else l

            val sw: Double
            val tw: Double

            if (type == "Pickleball Paddle") {
                // Pickleball Paddle Custom Formula
                sw = -259.5087 + (492.0045 * massKg) + (6.2811 * bpCm) + (6.8663 * lengthInches)
                tw = 0.075 * massKg * (widthCm.pow(2))
            } else {
                // Legacy / General Physics Formulas
                val f = if (type == "MOI-5") 5.0 else 10.0
                val d = bpCm - f
                
                val swRadius: Double
                val twRadius: Double
                val sFactor: Double
                val tFactor: Double
                
                if (type == "Racquet") {
                    swRadius = 9.1
                    twRadius = 0.2584
                    sFactor = 0.0
                    tFactor = 0.13
                } else {
                    // MOI-5 / MOI-10 (Pure Physics)
                    swRadius = radiusCm
                    twRadius = radiusCm
                    sFactor = 0.0
                    tFactor = 0.0
                }

                // SW = (((1/12)ML^2) + ((1/4)MR^2) + Md^2) * (1.0 - S)
                sw = (((1.0/12.0) * massKg * (lengthCm.pow(2))) + ((1.0/4.0) * massKg * (swRadius.pow(2))) + (massKg * (d.pow(2)))) * (1.0 - sFactor)
                
                // TW = (((1/12)MW^2) + ((1/4)MR^2)) * (1.0 - T)
                tw = (((1.0/12.0) * massKg * (widthCm.pow(2))) + ((1.0/4.0) * massKg * (twRadius.pow(2)))) * (1.0 - tFactor)
            }

            dao.updateEstimationGroup(group.copy(
                mass = m, massUnit = mUnit,
                length = l, lengthUnit = lUnit,
                width = w, widthUnit = wUnit,
                balancePoint = bp, bpUnit = bpUnit,
                radius = r, radiusUnit = rUnit,
                type = type,
                resultSW = sw, resultTW = tw
            ))
        }
    }

    // --- Data Tools (CSV Export/Import) ---

    suspend fun exportMeasureToCsv(): String {
        val groups = dao.getAllGroups().first()
        val sb = StringBuilder()
        sb.append("Group Name,Type,Period (s),MOI (kg.cm2),Tare Mode,Raw Data,Cycle Periods,Total Duration,Timestamp,Mass,Mass Unit,Length,Length Unit,Width,Width Unit,Group Type,Fit Residual\n")
        
        groups.forEach { group ->
            val measurements = dao.getMeasurementsByGroup(group.id).first()
            measurements.forEach { m ->
                val row = listOf(
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
                    m.fitResidual.toString()
                )
                sb.append(row.joinToString(",") { escapeCsvField(it) } + "\n")
            }
        }
        return sb.toString()
    }

    suspend fun exportEstimateToCsv(): String {
        val groups = dao.getAllEstimationGroups().first()
        val sb = StringBuilder()
        sb.append("Group Name,Mass,Mass Unit,Length,Length Unit,Width,Width Unit,BP,BP Unit,Radius,Radius Unit,Type,SW,TW,Timestamp\n")
        
        groups.forEach { g ->
            val row = listOf(
                g.name, g.mass.toString(), g.massUnit, g.length.toString(), g.lengthUnit,
                g.width.toString(), g.widthUnit, g.balancePoint.toString(), g.bpUnit,
                g.radius.toString(), g.radiusUnit, g.type, g.resultSW.toString(), g.resultTW.toString(),
                g.timestamp.toString()
            )
            sb.append(row.joinToString(",") { escapeCsvField(it) } + "\n")
        }
        return sb.toString()
    }

    private fun escapeCsvField(field: String): String {
        return if (field.contains(",") || field.contains("\"") || field.contains("\n")) {
            "\"" + field.replace("\"", "\"\"") + "\""
        } else {
            field
        }
    }

    suspend fun importMeasureFromCsv(csv: String) {
        val lines = csv.split("\n").filter { it.isNotBlank() }
        if (lines.isEmpty() || !lines[0].startsWith("Group Name,Type,Period (s)")) {
            _importError.emit("The selected file is not a valid Measure database backup.")
            return
        }
        
        lines.drop(1).forEach { line ->
            val parts = splitCsvLine(line)
            if (parts.size >= 9) {
                val groupName = parts[0]
                val type = parts[1]
                val period = parts[2].toDoubleOrNull() ?: 0.0
                val moi = parts[3].toDoubleOrNull() ?: 0.0
                val tareMode = parts[4]
                val rawData = parts[5]
                val cyclePeriods = parts[6]
                val totalDuration = parts[7].toDoubleOrNull() ?: 0.0
                val timestamp = parts[8].toLongOrNull() ?: System.currentTimeMillis()
                
                val mass = if (parts.size > 9) parts[9].toDoubleOrNull() ?: 0.0 else 0.0
                val mUnit = if (parts.size > 10) parts[10] else "oz"
                val length = if (parts.size > 11) parts[11].toDoubleOrNull() ?: 0.0 else 0.0
                val lUnit = if (parts.size > 12) parts[12] else "in"
                val width = if (parts.size > 13) parts[13].toDoubleOrNull() ?: 0.0 else 0.0
                val wUnit = if (parts.size > 14) parts[14] else "in"
                val gType = if (parts.size > 15) parts[15] else "Pickleball Paddle"
                
                // Parts 16, 17, 18 used to be theoretical fields, but are ignored now.
                // Depending on the export format, fitResidual may be at 16 or 19.
                val residual = if (parts.size > 19) {
                    parts[19].toDoubleOrNull() ?: 0.0 
                } else if (parts.size > 16 && parts.size <= 17) {
                    parts[16].toDoubleOrNull() ?: 0.0
                } else 0.0

                // Find or create group
                val existingGroups = dao.getAllGroups().first()
                var group = existingGroups.find { it.name == groupName }
                if (group == null) {
                    val id = dao.insertGroup(MeasurementGroup(
                        name = groupName, 
                        timestamp = timestamp,
                        mass = mass,
                        massUnit = mUnit,
                        length = length,
                        lengthUnit = lUnit,
                        width = width,
                        widthUnit = wUnit,
                        groupType = gType
                    ))
                    group = MeasurementGroup(
                        id = id.toInt(), 
                        name = groupName, 
                        timestamp = timestamp,
                        mass = mass,
                        massUnit = mUnit,
                        length = length,
                        lengthUnit = lUnit,
                        width = width,
                        widthUnit = wUnit,
                        groupType = gType
                    )
                }
                
                dao.insertMeasurement(Measurement(
                    groupId = group.id,
                    type = type,
                    period = period,
                    moi = moi,
                    tareMode = tareMode,
                    rawData = rawData,
                    cyclePeriods = cyclePeriods,
                    totalDuration = totalDuration,
                    fitResidual = residual,
                    timestamp = timestamp
                ))
            }
        }
    }

    suspend fun importEstimateFromCsv(csv: String) {
        val lines = csv.split("\n").filter { it.isNotBlank() }
        if (lines.isEmpty() || !lines[0].startsWith("Group Name,Mass,Mass Unit")) {
            _importError.emit("The selected file is not a valid Estimate database backup.")
            return
        }

        lines.drop(1).forEach { line ->
            val parts = splitCsvLine(line)
            if (parts.size >= 15) {
                dao.insertEstimationGroup(EstimationGroup(
                    name = parts[0],
                    mass = parts[1].toDoubleOrNull() ?: 0.0,
                    massUnit = parts[2],
                    length = parts[3].toDoubleOrNull() ?: 0.0,
                    lengthUnit = parts[4],
                    width = parts[5].toDoubleOrNull() ?: 0.0,
                    widthUnit = parts[6],
                    balancePoint = parts[7].toDoubleOrNull() ?: 0.0,
                    bpUnit = parts[8],
                    radius = parts[9].toDoubleOrNull() ?: 9.1,
                    radiusUnit = parts[10],
                    type = parts[11],
                    resultSW = parts[12].toDoubleOrNull() ?: 0.0,
                    resultTW = parts[13].toDoubleOrNull() ?: 0.0,
                    timestamp = parts[14].toLongOrNull() ?: System.currentTimeMillis()
                ))
            }
        }
    }

    fun setNfcScanning(scanning: Boolean) {
        _uiState.update { it.copy(isNfcScanning = scanning, nfcEnabled = true, nfcStatus = if (scanning) "Ready to Scan..." else null) }
    }

    fun setNfcDisabledError() {
        _uiState.update { it.copy(
            isNfcScanning = false, 
            nfcEnabled = false, 
            nfcStatus = "NFC is disabled. Please enable it in system settings."
        ) }
    }

    fun processNfcMessage(records: List<String>) {
        viewModelScope.launch {
            var updated = false
            records.forEach { record ->
                val clean = record.uppercase(Locale.US).replace(" ", "")
                val value = extractNumber(record) ?: return@forEach
                
                when {
                    clean.startsWith("OBJAT") -> {
                        appPreferences.saveExpectedValue("OBJECT_A", value)
                        updated = true
                    }
                    clean.startsWith("OBJBT") -> {
                        appPreferences.saveExpectedValue("OBJECT_B", value)
                        updated = true
                    }
                    clean.startsWith("OBJA") -> {
                        appPreferences.saveKnownObjectAInertia(value)
                        updated = true
                    }
                    clean.startsWith("OBJB") -> {
                        appPreferences.saveKnownObjectBInertia(value)
                        updated = true
                    }
                    clean.startsWith("PB") -> {
                        appPreferences.saveExpectedValue("TARE_PB", value)
                        updated = true
                    }
                    clean.startsWith("TW") -> {
                        appPreferences.saveExpectedValue("TARE_TW", value)
                        updated = true
                    }
                }
            }
            
            if (updated) {
                _uiState.update { it.copy(isNfcScanning = false, nfcStatus = "NFC Update Successful!") }
                delay(2000)
                _uiState.update { it.copy(nfcStatus = null) }
            } else {
                _uiState.update { it.copy(nfcStatus = "No valid calibration records found.") }
                delay(2000)
                _uiState.update { it.copy(nfcStatus = if (it.isNfcScanning) "Ready to Scan..." else null) }
            }
        }
    }

    private fun extractNumber(text: String): Double? {
        val regex = Regex("[+-]?([0-9]*[.])?[0-9]+")
        return regex.find(text)?.value?.toDoubleOrNull()
    }

    private fun splitCsvLine(line: String): List<String> {
        val result = mutableListOf<String>()
        var current = StringBuilder()
        var inQuotes = false
        
        for (char in line) {
            when (char) {
                '\"' -> inQuotes = !inQuotes
                ',' -> if (!inQuotes) {
                    result.add(current.toString().trim())
                    current = StringBuilder()
                } else current.append(char)
                else -> current.append(char)
            }
        }
        result.add(current.toString().trim())
        return result
    }

    override fun onCleared() {
        sensorManager.unregisterListener(oscillationDetector)
    }
}
