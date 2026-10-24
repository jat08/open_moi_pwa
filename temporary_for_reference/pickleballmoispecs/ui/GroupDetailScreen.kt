package com.example.pickleballmoispecs.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
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
import kotlin.math.pow
import kotlin.math.sqrt

@Composable
fun GroupDetailScreen(viewModel: MOIViewModel, groupId: Int) {
    val uiState by viewModel.uiState.collectAsState()
    val groupSummary = uiState.groups.find { it.group.id == groupId }
    var showRenameDialog by remember { mutableStateOf(value = false) }
    var showTareMenu by remember { mutableStateOf(value = false) }
    
    var selectedIds by remember { mutableStateOf(setOf<Int>()) }
    var isSelectionMode by remember { mutableStateOf(value = false) }

    val tareLabel = when (uiState.selectedTareMode) {
        "PICKLEBALL" -> "PB"
        "TWIST" -> "TW"
        else -> "None"
    }

    BackHandler {
        if (isSelectionMode) {
            selectedIds = emptySet()
            isSelectionMode = false
        } else {
            viewModel.selectGroup(null)
        }
    }

    Column(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 0.dp)) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 0.07.dp),
        ) {
            IconButton(
                onClick = { viewModel.selectGroup(null) },
                modifier = Modifier.offset(x = (-12).dp)
            ) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
            DynamicTitleText(
                text = groupSummary?.group?.name ?: "Group Details",
                maxFontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier
                    .weight(1f)
                    .padding(end = 12.dp)
                    .clickable { showRenameDialog = true }
            )
        }

        val measurements = uiState.selectedGroupMeasurements
        val swMeasurements = measurements.filter { it.moi >= 40 }
        val twMeasurements = measurements.filter { it.moi < 40 }

        // BP Calculation Logic
        var stdDevBP: Double? = null
        val calculatedBP = if ((groupSummary != null) && (groupSummary.group.mass > 0) && (groupSummary.group.length > 0)) {
            val sw = uiState.currentSWAverage
            val swStdDev = uiState.currentSWStdDev
            val m = groupSummary.group.mass
            val mKg = when (groupSummary.group.massUnit) {
                "oz" -> m * 0.028349523125
                "lb" -> m * 0.45359237
                else -> m
            }
            val l = groupSummary.group.length
            
            if (groupSummary.group.groupType == "Pickleball Paddle") {
                val lInches = if (groupSummary.group.lengthUnit == "cm") l / 2.54 else l
                val bp = (sw - (492.0045 * mKg) - (6.8663 * lInches) + 259.5087) / 6.2811
                
                // Error Propagation: Combined inherent 1.4% tolerance with SW measurement stdDev using RSS
                val swContribution = swStdDev / 6.2811
                val inherentContribution = (sw * 0.014) / 6.2811
                stdDevBP = sqrt(swContribution.pow(2) + inherentContribution.pow(2))
                
                bp
            } else {
                val lCm = if (groupSummary.group.lengthUnit == "in") l * 2.54 else l
                val tOffset = if (groupSummary.group.groupType == "Racquet" || groupSummary.group.groupType == "MOI-10") 10.0 else 5.0
                val r = 9.1
                
                try {
                    // Formula: SQRT((MOI/m)-((L^2)/12)-((R^2)/4)) + T
                    val insideSqrt = (sw / mKg) - (lCm.pow(2) / 12.0) - (r.pow(2) / 4.0)
                    if (insideSqrt >= 0) {
                        val root = sqrt(insideSqrt)
                        val bp = root + tOffset
                        
                        // Error Propagation: Combined inherent 0.25 tolerance with SW contribution using RSS
                        if (root > 0.01) {
                            val swContribution = swStdDev / (2.0 * mKg * root)
                            stdDevBP = sqrt(swContribution.pow(2) + 0.25.pow(2))
                        } else {
                            stdDevBP = 0.25
                        }
                        
                        bp
                    } else null
                } catch (_: Exception) {
                    null
                }
            }
        } else null

        SummaryHeaderLarge(
            avgSW = uiState.currentSWAverage, 
            stdDevSW = uiState.currentSWStdDev,
            avgTW = uiState.currentTWAverage,
            stdDevTW = uiState.currentTWStdDev,
            avgPeriodSW = uiState.currentSWPeriodAverage,
            stdDevPeriodSW = uiState.currentSWPeriodStdDev,
            avgPeriodTW = uiState.currentTWPeriodAverage,
            stdDevPeriodTW = uiState.currentTWPeriodStdDev,
            moiResolution = uiState.moiUnitsResolution,
            periodResolution = uiState.periodUnitsResolution,
            calculatedBP = calculatedBP,
            stdDevBP = stdDevBP
        )
        
        Spacer(modifier = Modifier.height(1.dp))

        // Centered Tare Selection & Info Bubble
        Box(modifier = Modifier.fillMaxWidth().height(40.dp)) {
            Box(modifier = Modifier.fillMaxWidth().fillMaxHeight(), contentAlignment = Alignment.Center) {
                Button(
                    onClick = { showTareMenu = true },
                    modifier = Modifier.height(40.dp)
                ) {
                    Text("Tare: $tareLabel")
                }
            }
            
            Surface(
                onClick = { viewModel.selectEditingAttributesGroup(groupId) },
                modifier = Modifier.align(Alignment.CenterEnd).size(40.dp),
                shape = androidx.compose.foundation.shape.CircleShape,
                color = MaterialTheme.colorScheme.primary,
                contentColor = MaterialTheme.colorScheme.onPrimary
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = "i", 
                        fontWeight = FontWeight.Bold, 
                        fontSize = 28.sp, 
                        fontStyle = FontStyle.Italic,
                        fontFamily = FontFamily(Typeface.create("georgia", Typeface.BOLD_ITALIC)),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.offset(y = (-2).dp) // Center the serif 'i'
                    )
                }
            }

            DropdownMenu(
                expanded = showTareMenu, 
                onDismissRequest = { showTareMenu = false },
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            ) {
                val menuPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
                
                DropdownMenuItem(
                    text = { Text("None", fontSize = 16.sp, fontWeight = FontWeight.Normal) }, 
                    onClick = { 
                        viewModel.setTareMode("NONE")
                        selectedIds = emptySet()
                        showTareMenu = false 
                    },
                    contentPadding = menuPadding
                )
                
                val pbEnabled = uiState.pickleballTareOffset > 0
                DropdownMenuItem(
                    text = { Text(if (pbEnabled) "Pickleball Adapter" else "PB-Tare Adapter First", fontSize = 16.sp, fontWeight = FontWeight.Normal) }, 
                    onClick = { 
                        viewModel.setTareMode("PICKLEBALL")
                        selectedIds = emptySet()
                        showTareMenu = false 
                    },
                    enabled = pbEnabled,
                    contentPadding = menuPadding
                )
                
                val twEnabled = uiState.twistTareOffset > 0
                DropdownMenuItem(
                    text = { Text(if (twEnabled) "Twist Weight Adapter" else "TW-Tare Adapter First", fontSize = 16.sp, fontWeight = FontWeight.Normal) }, 
                    onClick = { 
                        viewModel.setTareMode("TWIST")
                        selectedIds = emptySet()
                        showTareMenu = false 
                    },
                    enabled = twEnabled,
                    contentPadding = menuPadding
                )
            }
        }

        Spacer(modifier = Modifier.height(14.dp))
        
        if (isSelectionMode) {
            val allIds = measurements.asSequence().map { it.id }.toSet()
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
                }
            )
        } else {
            MeasurementControlButton(
                state = uiState.detectorState,
                progress = uiState.progress,
                isCalibrated = uiState.isCalibrated,
                cooldownRemaining = uiState.cooldownRemaining,
                preparationRemaining = uiState.preparationRemaining,
                onStart = { viewModel.startMeasurement() }
            )
        }
        
        Spacer(modifier = Modifier.height(0.5.dp))

        LazyColumn(modifier = Modifier.fillMaxSize()) {
            if (swMeasurements.isNotEmpty()) {
                item { SectionHeader("Swing Weight (SW)") }
                items(swMeasurements.asSequence().withIndex().toList(), key = { it.value.id }) { (index, m) ->
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
                        averageVal = uiState.currentSWAverage,
                        index = swMeasurements.size - index,
                        fitThreshold = uiState.fitResidualExclusion,
                        margin = uiState.swMargin,
                        trimLast = uiState.trimLastCycle
                    )
                }
            }
            
            if (twMeasurements.isNotEmpty()) {
                item { SectionHeader("Twist Weight (TW)") }
                items(twMeasurements.withIndex().toList(), key = { it.value.id }) { (index, m) ->
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
                        averageVal = uiState.currentTWAverage,
                        index = twMeasurements.size - index,
                        fitThreshold = uiState.fitResidualExclusion,
                        margin = uiState.twMargin,
                        trimLast = uiState.trimLastCycle
                    )
                }
            }
        }
    }

    if (showRenameDialog && groupSummary != null) {
        RenameDialog(
            currentName = groupSummary.group.name,
            onConfirm = { viewModel.renameGroup(groupSummary.group, it); showRenameDialog = false },
            onDismiss = { showRenameDialog = false }
        )
    }
}
