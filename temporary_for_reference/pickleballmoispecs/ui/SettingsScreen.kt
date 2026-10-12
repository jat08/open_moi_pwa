package com.example.pickleballmoispecs.ui


import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.documentfile.provider.DocumentFile
import com.example.pickleballmoispecs.data.ThemeMode
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun SettingsScreen(viewModel: MOIViewModel) {
    val uiState by viewModel.uiState.collectAsState()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    val durationRange = remember { (1..100).map { it / 10.0 } }
    val waitRange = remember { (1..10).map { it.toDouble() } }
    val cyclesRange = remember { (4..10).map { it.toDouble() } }
    val skipRange = remember { (0..4).map { it.toDouble() } }
    val prepRange = remember { (0..10).map { it.toDouble() } }
    val marginRange = remember { (1..50).map { it / 1000.0 } } // 0.001 to 0.05 in 0.001 steps (0.1% to 5.0%)
    val fitExclusionRange = remember { (10..100 step 5).map { it / 10.0 } } // 1.0 to 10.0 in 0.5 steps

    var showExportDialog by remember { mutableStateOf(value = false) }
    var showImportDialog by remember { mutableStateOf(value = false) }
    var pendingExportType by remember { mutableStateOf("") } // "MEASURE", "ESTIMATE", "BOTH"
    var pendingImportType by remember { mutableStateOf("") } // "MEASURE", "ESTIMATE"
    var errorMessage by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(Unit) {
        viewModel.importError.collect { msg ->
            errorMessage = msg
        }
    }

    fun getExportFilename(base: String): String {
        val stamp = SimpleDateFormat("MM-dd-yy_HH-mm-ss", Locale.US).format(Date())
        return "${base}_$stamp.csv"
    }

    // Single file export
    val exportFileLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("text/csv")) { uri ->
        uri?.let {
            scope.launch {
                val csvContent = if (pendingExportType == "MEASURE" || pendingExportType == "BOTH_STEP_1") {
                    viewModel.exportMeasureToCsv()
                } else {
                    viewModel.exportEstimateToCsv()
                }
                
                context.contentResolver.openOutputStream(it)?.use { out ->
                    out.write(csvContent.toByteArray())
                }

                // If this was the first part of a "Both" export, launch the second part
                if (pendingExportType == "BOTH_STEP_1") {
                    pendingExportType = "BOTH_STEP_2"
                }
            }
        }
    }

    // Effect to trigger the second prompt for "Both"
    LaunchedEffect(pendingExportType) {
        if (pendingExportType == "BOTH_STEP_2") {
            exportFileLauncher.launch(getExportFilename("Estimations"))
            pendingExportType = "" // Reset
        }
    }

    val importLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        uri?.let {
            scope.launch {
                val csvContent = context.contentResolver.openInputStream(it)?.bufferedReader()?.use { reader -> reader.readText() }
                csvContent?.let { content ->
                    if (pendingImportType == "MEASURE") viewModel.importMeasureFromCsv(content) else viewModel.importEstimateFromCsv(content)
                }
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp, vertical = 0.dp)
            .verticalScroll(rememberScrollState()),
        horizontalAlignment = Alignment.Start,
    ) {
        Text(
            text = "Settings", 
            fontSize = 28.sp, 
            fontWeight = FontWeight.Bold, 
            modifier = Modifier.fillMaxWidth().padding(top = 7.dp, bottom = 1.1.dp)
        )
        
        Spacer(modifier = Modifier.height(1.6.dp))

        SectionTitle("Theme & Display", bottomPadding = 0.5.dp)
        
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
            Text("Theme Mode", fontSize = 16.sp, fontWeight = FontWeight.Normal)
            ThemeModeSelector(uiState.themeMode) { scope.launch { viewModel.appPreferences.saveThemeMode(it) } }
        }

        Spacer(modifier = Modifier.height(1.1.dp))

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
            Text("MOI Units Resolution", fontSize = 16.sp, fontWeight = FontWeight.Normal)
            ResolutionSelector(uiState.moiUnitsResolution) { scope.launch { viewModel.appPreferences.saveMoiUnitsResolution(it) } }
        }

        Spacer(modifier = Modifier.height(1.1.dp))

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
            Text("Period Units Resolution", fontSize = 16.sp, fontWeight = FontWeight.Normal)
            PeriodResolutionSelector(uiState.periodUnitsResolution) { scope.launch { viewModel.appPreferences.savePeriodUnitsResolution(it) } }
        }

        Spacer(modifier = Modifier.height(1.1.dp))

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
            Text("Keep Screen On", fontSize = 16.sp, fontWeight = FontWeight.Normal)
            KeepScreenOnSelector(uiState.keepScreenOn) { scope.launch { viewModel.appPreferences.saveKeepScreenOn(it) } }
        }

        Spacer(modifier = Modifier.height(1.6.dp))
        
        SectionTitle("Measurement Control", bottomPadding = 0.5.dp)
        
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth().padding(vertical = 0.5.dp)) {
            Text("Measuring Duration (seconds)", modifier = Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Normal)
            NumberWheelPicker(
                value = uiState.measuringDuration,
                range = durationRange,
                onValueChange = { scope.launch { viewModel.appPreferences.saveMeasuringDuration(it) } }
            )
        }
        
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth().padding(vertical = 0.5.dp)) {
            Text("Wait between Measurements (seconds)", modifier = Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Normal)
            NumberWheelPicker(
                value = uiState.waitDuration,
                range = waitRange,
                format = "%.0f",
                onValueChange = { scope.launch { viewModel.appPreferences.saveWaitDuration(it) } }
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth().padding(vertical = 0.5.dp)) {
            Text("Cycles to Measure", modifier = Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Normal)
            NumberWheelPicker(
                value = uiState.cyclesToMeasure.toDouble(),
                range = cyclesRange,
                format = "%.0f",
                onValueChange = { scope.launch { viewModel.appPreferences.saveCyclesToMeasure(it.toInt()) } }
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth().padding(vertical = 0.5.dp)) {
            Text("Trim Last Cycle", modifier = Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Normal)
            TrimLastCycleSelector(uiState.trimLastCycle) { scope.launch { viewModel.appPreferences.saveTrimLastCycle(it) } }
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth().padding(vertical = 0.5.dp)) {
            Text("Skip First Cycles", modifier = Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Normal)
            NumberWheelPicker(
                value = uiState.skipFirstCycles.toDouble(),
                range = skipRange,
                format = "%.0f",
                onValueChange = { scope.launch { viewModel.appPreferences.saveSkipFirstCycles(it.toInt()) } }
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth().padding(vertical = 0.5.dp)) {
            Text("Cycle Reference", modifier = Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Normal)
            NumberWheelPicker(
                value = uiState.cycleReference.toDouble(),
                range = (0..uiState.cyclesToMeasure).map { it.toDouble() },
                format = "%.0f",
                onValueChange = { scope.launch { viewModel.appPreferences.saveCycleReference(it.toInt()) } }
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth().padding(vertical = 0.5.dp)) {
            Text("Preparation Time (seconds)", modifier = Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Normal)
            NumberWheelPicker(
                value = uiState.preparationTime.toDouble(),
                range = prepRange,
                format = "%.0f",
                onValueChange = { scope.launch { viewModel.appPreferences.savePreparationTime(it.toInt()) } }
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth().padding(vertical = 0.5.dp)) {
            Text("Low Margin", modifier = Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Normal)
            NumberWheelPicker(
                value = uiState.swMargin,
                range = marginRange,
                format = "%.1f%%",
                multiplyBy = 100.0,
                onValueChange = { scope.launch { viewModel.appPreferences.saveSWMargin(it) } }
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth().padding(vertical = 0.5.dp)) {
            Text("High Margin", modifier = Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Normal)
            NumberWheelPicker(
                value = uiState.twMargin,
                range = marginRange,
                format = "%.1f%%",
                multiplyBy = 100.0,
                onValueChange = { scope.launch { viewModel.appPreferences.saveTWMargin(it) } }
            )
        }

        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth().padding(vertical = 0.5.dp)) {
            Text("Fit Residual Exclusion", modifier = Modifier.weight(1f), fontSize = 16.sp, fontWeight = FontWeight.Normal)
            NumberWheelPicker(
                value = uiState.fitResidualExclusion,
                range = fitExclusionRange,
                format = "%.1f",
                onValueChange = { scope.launch { viewModel.appPreferences.saveFitResidualExclusion(it) } }
            )
        }

        Spacer(modifier = Modifier.height(1.6.dp))
        
        SectionTitle("Data Management", bottomPadding = 0.5.dp)
        
        Button(
            onClick = { showExportDialog = true },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Export Database")
        }
        
        Spacer(modifier = Modifier.height(0.5.dp))
        
        Button(
            onClick = { showImportDialog = true },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Import Database")
        }

        Spacer(modifier = Modifier.height(2.1.dp))
    }

    if (showExportDialog) {
        AlertDialog(
            onDismissRequest = { showExportDialog = false },
            title = { Text("Export CSV") },
            text = { Text("Select which database to export.") },
            confirmButton = {
                Column {
                    TextButton(onClick = { 
                        pendingExportType = "MEASURE"
                        exportFileLauncher.launch(getExportFilename("Measurements"))
                        showExportDialog = false 
                    }) { Text("Measure Database") }
                    
                    TextButton(onClick = { 
                        pendingExportType = "ESTIMATE"
                        exportFileLauncher.launch(getExportFilename("Estimations"))
                        showExportDialog = false 
                    }) { Text("Estimate Database") }
                    
                    TextButton(onClick = { 
                        pendingExportType = "BOTH_STEP_1"
                        exportFileLauncher.launch(getExportFilename("Measurements"))
                        showExportDialog = false 
                    }) { Text("Both (Save Sequentially)") }
                }
            },
            dismissButton = {
                TextButton(onClick = { showExportDialog = false }) { Text("Cancel") }
            }
        )
    }

    if (showImportDialog) {
        AlertDialog(
            onDismissRequest = { showImportDialog = false },
            title = { Text("Import CSV") },
            text = { Text("Select which database to import. Data will be appended.") },
            confirmButton = {
                Column {
                    TextButton(onClick = { pendingImportType = "MEASURE"; importLauncher.launch(arrayOf("text/*")); showImportDialog = false }) { Text("Measure Database") }
                    TextButton(onClick = { pendingImportType = "ESTIMATE"; importLauncher.launch(arrayOf("text/*")); showImportDialog = false }) { Text("Estimate Database") }
                }
            },
            dismissButton = {
                TextButton(onClick = { showImportDialog = false }) { Text("Cancel") }
            }
        )
    }

    errorMessage?.let { msg ->
        AlertDialog(
            onDismissRequest = { errorMessage = null },
            title = { Text("Import Error") },
            text = { Text(msg) },
            confirmButton = {
                Button(onClick = { errorMessage = null }) { Text("OK") }
            }
        )
    }
}

@Composable
fun KeepScreenOnSelector(current: Boolean, onSelect: (Boolean) -> Unit) {
    var expanded by remember { mutableStateOf(value = false) }
    Box {
        TextButton(onClick = { expanded = true }) {
            Text(if (current) "Yes" else "No", fontSize = 16.sp, fontWeight = FontWeight.Normal)
        }
        DropdownMenu(
            expanded = expanded, 
            onDismissRequest = { expanded = false },
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ) {
            val itemPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
            DropdownMenuItem(
                text = { Text("Yes", fontSize = 16.sp, fontWeight = FontWeight.Normal) },
                onClick = { onSelect(true); expanded = false },
                contentPadding = itemPadding
            )
            DropdownMenuItem(
                text = { Text("No", fontSize = 16.sp, fontWeight = FontWeight.Normal) },
                onClick = { onSelect(false); expanded = false },
                contentPadding = itemPadding
            )
        }
    }
}

@Composable
fun TrimLastCycleSelector(current: Boolean, onSelect: (Boolean) -> Unit) {
    var expanded by remember { mutableStateOf(value = false) }
    Box {
        TextButton(onClick = { expanded = true }) {
            Text(if (current) "Yes" else "No", fontSize = 16.sp, fontWeight = FontWeight.Normal)
        }
        DropdownMenu(
            expanded = expanded, 
            onDismissRequest = { expanded = false },
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ) {
            val itemPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
            DropdownMenuItem(
                text = { Text("Yes", fontSize = 16.sp, fontWeight = FontWeight.Normal) },
                onClick = { onSelect(true); expanded = false },
                contentPadding = itemPadding
            )
            DropdownMenuItem(
                text = { Text("No", fontSize = 16.sp, fontWeight = FontWeight.Normal) },
                onClick = { onSelect(false); expanded = false },
                contentPadding = itemPadding
            )
        }
    }
}

@Composable
fun ThemeModeSelector(current: ThemeMode, onSelect: (ThemeMode) -> Unit) {
    var expanded by remember { mutableStateOf(value = false) }
    Box {
        TextButton(onClick = { expanded = true }) {
            Text(current.name, fontSize = 16.sp, fontWeight = FontWeight.Normal)
        }
        DropdownMenu(
            expanded = expanded, 
            onDismissRequest = { expanded = false },
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ) {
            val itemPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
            ThemeMode.entries.forEach { mode ->
                DropdownMenuItem(
                    text = { Text(mode.name, fontSize = 16.sp, fontWeight = FontWeight.Normal) },
                    onClick = { onSelect(mode); expanded = false },
                    contentPadding = itemPadding
                )
            }
        }
    }
}



@Composable
fun PeriodResolutionSelector(current: Int, onSelect: (Int) -> Unit) {
    var expanded by remember { mutableStateOf(value = false) }
    val labels = mapOf(1 to "0.0", 2 to "0.00", 3 to "0.000", 4 to "0.0000", 5 to "0.00000", 6 to "0.000000")
    Box {
        TextButton(onClick = { expanded = true }) {
            Text(labels[current] ?: "0.0000", fontSize = 16.sp, fontWeight = FontWeight.Normal)
        }
        DropdownMenu(
            expanded = expanded, 
            onDismissRequest = { expanded = false },
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ) {
            val itemPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
            listOf(1, 2, 3, 4, 5, 6).forEach { res ->
                DropdownMenuItem(
                    text = { Text(labels[res] ?: "", fontSize = 16.sp, fontWeight = FontWeight.Normal) },
                    onClick = { onSelect(res); expanded = false },
                    contentPadding = itemPadding
                )
            }
        }
    }
}

@Composable
fun ResolutionSelector(current: Int, onSelect: (Int) -> Unit) {
    var expanded by remember { mutableStateOf(value = false) }
    val labels = mapOf(0 to "0", 1 to "0.0", 2 to "0.00", 3 to "0.000", 4 to "0.0000")
    Box {
        TextButton(onClick = { expanded = true }) {
            Text(labels[current] ?: "0.0", fontSize = 16.sp, fontWeight = FontWeight.Normal)
        }
        DropdownMenu(
            expanded = expanded, 
            onDismissRequest = { expanded = false },
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ) {
            val itemPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
            listOf(0, 1, 2, 3, 4).forEach { res ->
                DropdownMenuItem(
                    text = { Text(labels[res] ?: "", fontSize = 16.sp, fontWeight = FontWeight.Normal) },
                    onClick = { onSelect(res); expanded = false },
                    contentPadding = itemPadding
                )
            }
        }
    }
}
