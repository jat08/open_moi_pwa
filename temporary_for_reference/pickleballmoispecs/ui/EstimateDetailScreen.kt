package com.example.pickleballmoispecs.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.unit.sp
import com.example.pickleballmoispecs.data.EstimationGroup

@Composable
fun EstimateDetailScreen(viewModel: MOIViewModel, group: EstimationGroup) {
    val uiState by viewModel.uiState.collectAsState()
    var showRenameDialog by remember { mutableStateOf(value = false) }
    
    // Use remember(group.id) to ensure state is isolated per group and resets for new groups
    var m by remember(group.id) { mutableStateOf(if (group.mass > 0) group.mass.toString() else "") }
    var mUnit by remember(group.id) { mutableStateOf(group.massUnit) }
    var l by remember(group.id) { mutableStateOf(if (group.length > 0) group.length.toString() else "") }
    var lUnit by remember(group.id) { mutableStateOf(group.lengthUnit) }
    var w by remember(group.id) { mutableStateOf(if (group.width > 0) group.width.toString() else "") }
    var wUnit by remember(group.id) { mutableStateOf(group.widthUnit) }
    var bp by remember(group.id) { mutableStateOf(if (group.balancePoint > 0) group.balancePoint.toString() else "") }
    var bpUnit by remember(group.id) { mutableStateOf(group.bpUnit) }
    var r by remember(group.id) { mutableStateOf(if (group.radius > 0) group.radius.toString() else "") }
    var rUnit by remember(group.id) { mutableStateOf(group.radiusUnit) }
    var type by remember(group.id) { mutableStateOf(group.type) }

    BackHandler {
        viewModel.selectEstimationGroup(null)
    }

    Column(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 0.dp).imePadding()) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 16.dp),
        ) {
            IconButton(
                onClick = { viewModel.selectEstimationGroup(null) },
                modifier = Modifier.offset(x = (-12).dp)
            ) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
            DynamicTitleText(
                text = group.name,
                maxFontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .weight(1f)
                    .padding(end = 12.dp)
                    .clickable { showRenameDialog = true }
            )
        }

        val swStdDev = if (group.type == "Pickleball Paddle") group.resultSW * 0.014 else 0.0
        val twStdDev = if (group.type == "Pickleball Paddle") group.resultTW * 0.039 else 0.0

        // Summary Header (Using dynamic coupled component to prevent wrapping)
        SingleSummaryHeader(
            label = "SW",
            avg = group.resultSW,
            stdDev = swStdDev, 
            moiResolution = uiState.moiUnitsResolution,
            label2 = "TW",
            avg2 = group.resultTW,
            stdDev2 = twStdDev,
            showTolerance = (swStdDev > 0 || twStdDev > 0)
        )

        Spacer(modifier = Modifier.height(24.dp))

        Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            EstimationInputField("Weight", m, mUnit, listOf("oz", "lb", "kg"), { m = it }, { mUnit = it })
            EstimationInputField("Length", l, lUnit, listOf("in", "cm"), { l = it }, { lUnit = it })
            EstimationInputField("Width", w, wUnit, listOf("in", "cm"), { w = it }, { wUnit = it })
            EstimationInputField("Balance Point", bp, bpUnit, listOf("in", "cm"), { bp = it }, { bpUnit = it })
            
            val isRadiusLocked = (type == "Pickleball Paddle") || (type == "Racquet")
            EstimationInputField("Radius", r, rUnit, listOf("in", "cm"), { r = it }, { rUnit = it }, locked = isRadiusLocked)
            
            val typeOptions = listOf(
                "MOI-5", 
                "MOI-10", 
                "Pickleball Paddle", 
                "Racquet"
            )
            TypeSelector("Type", type, typeOptions) { type = it }

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    val mVal = m.toDoubleOrNull() ?: 0.0
                    val lVal = l.toDoubleOrNull() ?: 0.0
                    val wVal = w.toDoubleOrNull() ?: 0.0
                    val bpVal = bp.toDoubleOrNull() ?: 0.0
                    val rVal = r.toDoubleOrNull() ?: 0.0
                    viewModel.calculateAndSaveEstimation(group, mVal, mUnit, lVal, lUnit, wVal, wUnit, bpVal, bpUnit, rVal, rUnit, type)
                },
                modifier = Modifier.fillMaxWidth().height(56.dp)
            ) {
                Text("Calculate", fontWeight = FontWeight.Bold, fontSize = 18.sp)
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }

    if (showRenameDialog) {
        RenameEstimationDialog(
            currentName = group.name,
            onConfirm = { viewModel.renameEstimationGroup(group, it); showRenameDialog = false },
            onDismiss = { showRenameDialog = false }
        )
    }
}
