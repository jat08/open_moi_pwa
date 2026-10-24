package com.example.pickleballmoispecs.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.graphics.Typeface
import java.util.*
import kotlin.math.sqrt

@Composable
fun CalibrationDetailScreen(viewModel: MOIViewModel, target: MOIViewModel.CalibrationTarget) {
    val uiState by viewModel.uiState.collectAsState()
    
    var selectedIds by remember { mutableStateOf(setOf<Int>()) }
    var isSelectionMode by remember { mutableStateOf(value = false) }

    val measurements = when (target) {
        MOIViewModel.CalibrationTarget.OBJECT_A -> uiState.measurementsA
        MOIViewModel.CalibrationTarget.OBJECT_B -> uiState.measurementsB
        MOIViewModel.CalibrationTarget.TARE_PB -> uiState.measurementsTarePB
        MOIViewModel.CalibrationTarget.TARE_TW -> uiState.measurementsTareTW
        else -> emptyList()
    }
    
    val title = when (target) {
        MOIViewModel.CalibrationTarget.OBJECT_A -> "Object A Calibration"
        MOIViewModel.CalibrationTarget.OBJECT_B -> "Object B Calibration"
        MOIViewModel.CalibrationTarget.TARE_PB -> "Pickleball Adapter Tare"
        MOIViewModel.CalibrationTarget.TARE_TW -> "Twist Weight Adapter Tare"
        else -> "Details"
    }

    BackHandler {
        if (isSelectionMode) {
            selectedIds = emptySet()
            isSelectionMode = false
        } else {
            viewModel.selectCalibrationTarget(null)
        }
    }

    Column(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 0.dp)) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 16.dp),
        ) {
            IconButton(
                onClick = { viewModel.selectCalibrationTarget(null) },
                modifier = Modifier.offset(x = (-12).dp)
            ) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
            Text(
                text = title,
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f)
            )
            
            FilledIconButton(
                onClick = { viewModel.selectEditingExpectedValue(target) },
                modifier = Modifier.size(40.dp),
                shape = androidx.compose.foundation.shape.CircleShape,
                colors = IconButtonDefaults.filledIconButtonColors(
                    containerColor = MaterialTheme.colorScheme.primary,
                    contentColor = MaterialTheme.colorScheme.onPrimary
                )
            ) {
                Text(
                    text = "i", 
                    fontWeight = FontWeight.Bold, 
                    fontSize = 28.sp, 
                    fontStyle = FontStyle.Italic,
                    fontFamily = FontFamily(Typeface.create("georgia", Typeface.BOLD_ITALIC)),
                    textAlign = TextAlign.Center,
                    modifier = Modifier.offset(y = (-1).dp)
                )
            }
        }

        // Summary Header focused on PERIOD (and MOI for Tares)
        val isTare = (target == MOIViewModel.CalibrationTarget.TARE_PB) || (target == MOIViewModel.CalibrationTarget.TARE_TW)
        
        val moiStats = if (isTare) {
            val threshold = uiState.fitResidualExclusion
            val moiValues = measurements.asSequence().filter { it.fitResidual < threshold }.map { it.moi }.toList()
            if (moiValues.isEmpty()) MOIViewModel.Stats(0.0, 0.0)
            else {
                val avg = moiValues.average()
                val variance = moiValues.map { (it - avg).let { d -> d * d } }.average()
                MOIViewModel.Stats(avg, sqrt(variance))
            }
        } else null

        val pFormat = "%.${uiState.periodUnitsResolution}f"
        val expectedNote = when (target) {
            MOIViewModel.CalibrationTarget.OBJECT_A -> "Expected Period: ${String.format(Locale.US, pFormat, uiState.expectedPeriodA)}s"
            MOIViewModel.CalibrationTarget.OBJECT_B -> "Expected Period: ${String.format(Locale.US, pFormat, uiState.expectedPeriodB)}s"
            MOIViewModel.CalibrationTarget.TARE_PB -> "Expected MOI: ${String.format(Locale.US, "%.4f", uiState.expectedMoiPB)} kg·cm²"
            MOIViewModel.CalibrationTarget.TARE_TW -> "Expected MOI: ${String.format(Locale.US, "%.4f", uiState.expectedMoiTW)} kg·cm²"
            else -> null
        }

        SingleSummaryHeader(
            label = "Period",
            avg = uiState.currentCalibrationPeriodAverage,
            stdDev = uiState.currentCalibrationPeriodStdDev,
            moiResolution = uiState.moiUnitsResolution,
            periodResolution = uiState.periodUnitsResolution,
            isPeriod = true,
            label2 = if (isTare) "MOI" else null,
            avg2 = moiStats?.average ?: 0.0,
            stdDev2 = moiStats?.stdDev ?: 0.0,
            expectedNote = expectedNote
        )
        
        Spacer(modifier = Modifier.height(18.dp))
        
        if (isSelectionMode) {
            val allIds = measurements.map { it.id }.toSet()
            val isAllSelected = selectedIds.size >= allIds.size && allIds.isNotEmpty()
            SelectionTopBar(
                count = selectedIds.size,
                isAllSelected = isAllSelected,
                onToggleAll = {
                    selectedIds = if (isAllSelected) emptySet() else allIds
                },
                onClear = { 
                    selectedIds = emptySet()
                    isSelectionMode = false
                },
                onDelete = {
                    viewModel.deleteMeasurements(selectedIds)
                    selectedIds = emptySet()
                    isSelectionMode = false
                },
            )
        } else {
            // Consolidated Control Button
            MeasurementControlButton(
                state = uiState.detectorState,
                progress = uiState.progress,
                cooldownRemaining = uiState.cooldownRemaining,
                preparationRemaining = uiState.preparationRemaining,
                onStart = { viewModel.startMeasurement() }
            )
        }
        
        Spacer(modifier = Modifier.height(1.6.dp))

        LazyColumn(modifier = Modifier.fillMaxSize()) {
            item { SectionHeader("Measurements (Seconds)") }
            items(measurements.withIndex().toList(), key = { it.value.id }) { (index, m) ->
                val isSelected = selectedIds.contains(m.id)
                MeasurementItem(
                    measurement = m, 
                    selected = isSelected,
                    onClick = {
                        if (isSelectionMode) {
                            selectedIds = if (isSelected) selectedIds - m.id else selectedIds + m.id
                        } else {
                            viewModel.selectMeasurement(m)
                        }
                    },
                    onLongClick = {
                        if (!isSelectionMode) {
                            selectedIds = setOf(m.id)
                            isSelectionMode = true
                        }
                    },
                    onDelete = { 
                        viewModel.deleteMeasurement(m)
                        selectedIds = emptySet()
                        isSelectionMode = false
                    }, 
                    resolution = uiState.moiUnitsResolution, 
                    periodResolution = uiState.periodUnitsResolution,
                    averageVal = uiState.currentCalibrationPeriodAverage,
                    index = measurements.size - index,
                    showType = false,
                    isPeriod = true,
                    fitThreshold = uiState.fitResidualExclusion,
                    margin = if (target == MOIViewModel.CalibrationTarget.TARE_PB || target == MOIViewModel.CalibrationTarget.TARE_TW) uiState.twMargin else uiState.swMargin,
                    trimLast = uiState.trimLastCycle,

                )
            }
        }
    }
}
