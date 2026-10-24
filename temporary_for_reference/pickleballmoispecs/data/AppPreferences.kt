package com.example.pickleballmoispecs.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.doublePreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

enum class ThemeMode { LIGHT, DARK, SYSTEM }

class AppPreferences(private val context: Context) {

    companion object {
        val DEVICE_KAPPA = doublePreferencesKey("device_kappa")
        val DEVICE_INERTIA = doublePreferencesKey("device_inertia")
        val KNOWN_OBJECT_A_INERTIA = doublePreferencesKey("known_object_a_inertia_v3")
        val KNOWN_OBJECT_B_INERTIA = doublePreferencesKey("known_object_b_inertia_v3")
        val THEME_MODE = stringPreferencesKey("theme_mode")
        val MOI_UNITS_RESOLUTION = intPreferencesKey("units_resolution")
        val PERIOD_UNITS_RESOLUTION = intPreferencesKey("period_units_resolution")
        val PICKLEBALL_TARE = doublePreferencesKey("pickleball_tare")
        val TWIST_TARE = doublePreferencesKey("twist_tare")
        val SELECTED_TARE_MODE = stringPreferencesKey("selected_tare_mode")
        val MEASURING_DURATION = doublePreferencesKey("measuring_duration")
        val WAIT_DURATION = doublePreferencesKey("wait_duration")
        val CYCLES_TO_MEASURE = intPreferencesKey("cycles_to_measure")
        val SW_MARGIN = doublePreferencesKey("sw_margin")
        val TW_MARGIN = doublePreferencesKey("tw_margin")
        val FIT_RESIDUAL_EXCLUSION = doublePreferencesKey("fit_residual_exclusion")
        val KEEP_SCREEN_ON = booleanPreferencesKey("keep_screen_on")
        val PREPARATION_TIME = intPreferencesKey("preparation_time")
        val SORT_TYPE = stringPreferencesKey("sort_type")
        val SORT_DIRECTION = stringPreferencesKey("sort_direction")
        
        val TRIM_LAST_CYCLE = booleanPreferencesKey("trim_last_cycle")
        val SKIP_FIRST_CYCLES = intPreferencesKey("skip_first_cycles")
    
        val CYCLE_REFERENCE = intPreferencesKey("cycle_reference")
        
        val EXPECTED_PERIOD_A = doublePreferencesKey("expected_period_a")
        val EXPECTED_PERIOD_B = doublePreferencesKey("expected_period_b")
        val EXPECTED_MOI_PB = doublePreferencesKey("expected_moi_pb")
        val EXPECTED_MOI_TW = doublePreferencesKey("expected_moi_tw")
        
        const val DEFAULT_KNOWN_A_INERTIA = 13.2135
        const val DEFAULT_KNOWN_B_INERTIA = 177.1500

        const val DEFAULT_EXPECTED_PERIOD_A = 0.6947
        const val DEFAULT_EXPECTED_PERIOD_B = 0.2607
        const val DEFAULT_EXPECTED_MOI_PB = 1.16
        const val DEFAULT_EXPECTED_MOI_TW = 2.16
    }

    val deviceKappa: Flow<Double> = context.dataStore.data.map { it[DEVICE_KAPPA] ?: 0.0 }
    val deviceInertia: Flow<Double> = context.dataStore.data.map { it[DEVICE_INERTIA] ?: 0.0 }
    val knownObjectAInertia: Flow<Double> = context.dataStore.data.map { it[KNOWN_OBJECT_A_INERTIA] ?: DEFAULT_KNOWN_A_INERTIA }
    val knownObjectBInertia: Flow<Double> = context.dataStore.data.map { it[KNOWN_OBJECT_B_INERTIA] ?: DEFAULT_KNOWN_B_INERTIA }
    
    val expectedPeriodA: Flow<Double> = context.dataStore.data.map { it[EXPECTED_PERIOD_A] ?: DEFAULT_EXPECTED_PERIOD_A }
    val expectedPeriodB: Flow<Double> = context.dataStore.data.map { it[EXPECTED_PERIOD_B] ?: DEFAULT_EXPECTED_PERIOD_B }
    val expectedMoiPB: Flow<Double> = context.dataStore.data.map { it[EXPECTED_MOI_PB] ?: DEFAULT_EXPECTED_MOI_PB }
    val expectedMoiTW: Flow<Double> = context.dataStore.data.map { it[EXPECTED_MOI_TW] ?: DEFAULT_EXPECTED_MOI_TW }

    val themeMode: Flow<ThemeMode> = context.dataStore.data.map { 
        val name = it[THEME_MODE] ?: ThemeMode.SYSTEM.name
        ThemeMode.valueOf(name)
    }
    
    val moiUnitsResolution: Flow<Int> = context.dataStore.data.map { it[MOI_UNITS_RESOLUTION] ?: 1 }
    val periodUnitsResolution: Flow<Int> = context.dataStore.data.map { it[PERIOD_UNITS_RESOLUTION] ?: 4 }
    
    val pickleballTare: Flow<Double> = context.dataStore.data.map { it[PICKLEBALL_TARE] ?: 0.0 }
    val twistTare: Flow<Double> = context.dataStore.data.map { it[TWIST_TARE] ?: 0.0 }
    val selectedTareMode: Flow<String> = context.dataStore.data.map { it[SELECTED_TARE_MODE] ?: "NONE" }
    
    val measuringDuration: Flow<Double> = context.dataStore.data.map { it[MEASURING_DURATION] ?: 8.0 }
    val waitDuration: Flow<Double> = context.dataStore.data.map { it[WAIT_DURATION] ?: 6.0 }
    val cyclesToMeasure: Flow<Int> = context.dataStore.data.map { it[CYCLES_TO_MEASURE] ?: 5 }
    val swMargin: Flow<Double> = context.dataStore.data.map { it[SW_MARGIN] ?: 0.003 }
    val twMargin: Flow<Double> = context.dataStore.data.map { it[TW_MARGIN] ?: 0.01 }
    val fitResidualExclusion: Flow<Double> = context.dataStore.data.map { it[FIT_RESIDUAL_EXCLUSION] ?: 1.0 }
    val keepScreenOn: Flow<Boolean> = context.dataStore.data.map { it[KEEP_SCREEN_ON] ?: true }
    val preparationTime: Flow<Int> = context.dataStore.data.map { it[PREPARATION_TIME] ?: 2 }
    
    val sortType: Flow<String> = context.dataStore.data.map { it[SORT_TYPE] ?: "DATE" }
    val sortDirection: Flow<String> = context.dataStore.data.map { it[SORT_DIRECTION] ?: "ASCENDING" }

    val trimLastCycle: Flow<Boolean> = context.dataStore.data.map { it[TRIM_LAST_CYCLE] ?: true }
    val skipFirstCycles: Flow<Int> = context.dataStore.data.map { it[SKIP_FIRST_CYCLES] ?: 0 }

    val cycleReference: Flow<Int> = context.dataStore.data.map { it[CYCLE_REFERENCE] ?: 0 }

    suspend fun saveCalibration(kappa: Double, deviceInertia: Double) {
        context.dataStore.edit { preferences ->
            preferences[DEVICE_KAPPA] = kappa
            preferences[DEVICE_INERTIA] = deviceInertia
        }
    }

    suspend fun saveKnownObjectAInertia(inertia: Double) {
        context.dataStore.edit { it[KNOWN_OBJECT_A_INERTIA] = inertia }
    }

    suspend fun saveKnownObjectBInertia(inertia: Double) {
        context.dataStore.edit { it[KNOWN_OBJECT_B_INERTIA] = inertia }
    }

    suspend fun saveThemeMode(mode: ThemeMode) {
        context.dataStore.edit { it[THEME_MODE] = mode.name }
    }
    
    suspend fun saveMoiUnitsResolution(res: Int) {
        context.dataStore.edit { it[MOI_UNITS_RESOLUTION] = res }
    }
    
    suspend fun savePeriodUnitsResolution(res: Int) {
        context.dataStore.edit { it[PERIOD_UNITS_RESOLUTION] = res }
    }
    
    suspend fun savePickleballTare(moi: Double) {
        context.dataStore.edit { it[PICKLEBALL_TARE] = moi }
    }
    
    suspend fun saveTwistTare(moi: Double) {
        context.dataStore.edit { it[TWIST_TARE] = moi }
    }
    
    suspend fun saveSelectedTareMode(mode: String) {
        context.dataStore.edit { it[SELECTED_TARE_MODE] = mode }
    }
    
    suspend fun saveMeasuringDuration(seconds: Double) {
        context.dataStore.edit { it[MEASURING_DURATION] = seconds }
    }
    
    suspend fun saveWaitDuration(seconds: Double) {
        context.dataStore.edit { it[WAIT_DURATION] = seconds }
    }

    suspend fun saveCyclesToMeasure(count: Int) {
        context.dataStore.edit { it[CYCLES_TO_MEASURE] = count }
    }

    suspend fun saveSWMargin(margin: Double) {
        context.dataStore.edit { it[SW_MARGIN] = margin }
    }

    suspend fun saveTWMargin(margin: Double) {
        context.dataStore.edit { it[TW_MARGIN] = margin }
    }

    suspend fun saveFitResidualExclusion(threshold: Double) {
        context.dataStore.edit { it[FIT_RESIDUAL_EXCLUSION] = threshold }
    }

    suspend fun saveKeepScreenOn(keepOn: Boolean) {
        context.dataStore.edit { it[KEEP_SCREEN_ON] = keepOn }
    }

    suspend fun savePreparationTime(seconds: Int) {
        context.dataStore.edit { it[PREPARATION_TIME] = seconds }
    }

    suspend fun saveSortType(type: String) {
        context.dataStore.edit { it[SORT_TYPE] = type }
    }

    suspend fun saveSortDirection(direction: String) {
        context.dataStore.edit { it[SORT_DIRECTION] = direction }
    }

    suspend fun saveTrimLastCycle(trim: Boolean) {
        context.dataStore.edit { it[TRIM_LAST_CYCLE] = trim }
    }

    suspend fun saveSkipFirstCycles(count: Int) {
        context.dataStore.edit { it[SKIP_FIRST_CYCLES] = count }
    }



    suspend fun saveCycleReference(index: Int) {
        context.dataStore.edit { it[CYCLE_REFERENCE] = index }
    }

    suspend fun saveExpectedValue(target: String, value: Double) {
        context.dataStore.edit { preferences ->
            when (target) {
                "OBJECT_A" -> preferences[EXPECTED_PERIOD_A] = value
                "OBJECT_B" -> preferences[EXPECTED_PERIOD_B] = value
                "TARE_PB" -> preferences[EXPECTED_MOI_PB] = value
                "TARE_TW" -> preferences[EXPECTED_MOI_TW] = value
            }
        }
    }
}
