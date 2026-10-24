package com.example.pickleballmoispecs.ui

import android.content.Intent
import android.provider.Settings
import androidx.compose.foundation.clickable
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pickleballmoispecs.data.Measurement
import com.example.pickleballmoispecs.logic.MomentOfInertiaCalculator
import kotlinx.coroutines.launch
import java.util.*
import kotlin.math.sqrt

@Composable
fun CalibrationScreen(viewModel: MOIViewModel) {
    val uiState by viewModel.uiState.collectAsState()
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    if (uiState.editingExpectedValueTarget != null) {
        CalibrationInfoScreen(viewModel, uiState.editingExpectedValueTarget!!)
    } else if (uiState.selectedMeasurement != null) {
        MeasurementDetailScreen(viewModel, uiState.selectedMeasurement!!)
    } else if (uiState.selectedCalibrationTarget != null) {
        CalibrationDetailScreen(viewModel, uiState.selectedCalibrationTarget!!)
    } else {
        var knownA by remember { mutableStateOf(if (uiState.knownObjectAInertia == 0.0) "" else uiState.knownObjectAInertia.toString().removeSuffix(".0")) }
        var knownB by remember { mutableStateOf(if (uiState.knownObjectBInertia == 0.0) "" else uiState.knownObjectBInertia.toString().removeSuffix(".0")) }
        
        var lastSavedA by remember { mutableDoubleStateOf(uiState.knownObjectAInertia) }
        var lastSavedB by remember { mutableDoubleStateOf(uiState.knownObjectBInertia) }
        
        var showRecalibrateConfirm by remember { mutableStateOf(value = false) }
        var showReTareConfirm by remember { mutableStateOf(value = false) }

        LaunchedEffect(uiState.knownObjectAInertia) {
            if (uiState.knownObjectAInertia != lastSavedA) {
                lastSavedA = uiState.knownObjectAInertia
                knownA = if (uiState.knownObjectAInertia == 0.0) "" else uiState.knownObjectAInertia.toString().removeSuffix(".0")
            }
        }

        LaunchedEffect(uiState.knownObjectBInertia) {
            if (uiState.knownObjectBInertia != lastSavedB) {
                lastSavedB = uiState.knownObjectBInertia
                knownB = if (uiState.knownObjectBInertia == 0.0) "" else uiState.knownObjectBInertia.toString().removeSuffix(".0")
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
                text = "Device Calibration", 
                fontSize = 28.sp, 
                fontWeight = FontWeight.Bold,
                modifier = Modifier.fillMaxWidth().padding(top = 12.dp, bottom = 1.8.dp),
            )
            
            Spacer(modifier = Modifier.height(8.dp))

            SectionTitle("Calibration Objects")
            
            CalibrationObjectCard(
                title = "Object A",
                measurements = uiState.measurementsA,
                fitThreshold = uiState.fitResidualExclusion,
                trimLast = uiState.trimLastCycle,
                periodResolution = uiState.periodUnitsResolution
            ) { viewModel.selectCalibrationTarget(MOIViewModel.CalibrationTarget.OBJECT_A) }

            Spacer(modifier = Modifier.height(2.dp))

            CalibrationObjectCard(
                title = "Object B",
                measurements = uiState.measurementsB,
                fitThreshold = uiState.fitResidualExclusion,
                trimLast = uiState.trimLastCycle,
                periodResolution = uiState.periodUnitsResolution
            ) { viewModel.selectCalibrationTarget(MOIViewModel.CalibrationTarget.OBJECT_B) }

            if (uiState.measurementsA.isNotEmpty() || uiState.measurementsB.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedButton(
                    onClick = { showRecalibrateConfirm = true },
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red),
                    border = ButtonDefaults.outlinedButtonBorder(enabled = true).copy(brush = SolidColor(Color.Red)),
                ) {
                    Text("Recalibrate", fontWeight = FontWeight.Bold)
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            SectionTitle("Calibration Objects MOI")
            SettingRowField("Object A (kg·cm²)", knownA) { 
                knownA = it 
                it.toDoubleOrNull()?.let { d -> 
                    lastSavedA = d
                    scope.launch { viewModel.appPreferences.saveKnownObjectAInertia(d) } 
                }
            }
            SettingRowField("Object B (kg·cm²)", knownB) { 
                knownB = it 
                it.toDoubleOrNull()?.let { d -> 
                    lastSavedB = d
                    scope.launch { viewModel.appPreferences.saveKnownObjectBInertia(d) } 
                }
            }

            Spacer(modifier = Modifier.height(8.dp))
            OutlinedButton(
                onClick = { viewModel.setNfcScanning(true) },
                modifier = Modifier.fillMaxWidth().height(48.dp),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = MaterialTheme.colorScheme.primary),
                border = ButtonDefaults.outlinedButtonBorder(enabled = true).copy(brush = SolidColor(MaterialTheme.colorScheme.primary)),
            ) {
                Text("Read NFC", fontWeight = FontWeight.Bold)
            }
            
            Spacer(modifier = Modifier.height(16.dp))

            SectionTitle("Derived Device Parameters")
            val displayKappa = if (uiState.isCalibrated) {
                String.format(Locale.US, "%.4f", uiState.deviceKappa / MomentOfInertiaCalculator.KAPPA_CONVERSION)
            } else "0.0000"
            
            val displayI = if (uiState.isCalibrated) {
                String.format(Locale.US, "%.4f", uiState.deviceInertia)
            } else "0.0"

            val clipboardManager = androidx.compose.ui.platform.LocalClipboardManager.current
            
            ReadOnlySettingField("Spring Constant (kg·cm/rad)", displayKappa, onLongClick = {
                if (uiState.isCalibrated) {
                    val numeric = (uiState.deviceKappa / MomentOfInertiaCalculator.KAPPA_CONVERSION).toString()
                    clipboardManager.setText(androidx.compose.ui.text.AnnotatedString(numeric))
                    android.widget.Toast.makeText(context, "Copied Spring Constant: $numeric", android.widget.Toast.LENGTH_SHORT).show()
                }
            })
            ReadOnlySettingField("Device Inertia (kg·cm²)", displayI, onLongClick = {
                if (uiState.isCalibrated) {
                    val numeric = uiState.deviceInertia.toString()
                    clipboardManager.setText(androidx.compose.ui.text.AnnotatedString(numeric))
                    android.widget.Toast.makeText(context, "Copied Device Inertia: $numeric", android.widget.Toast.LENGTH_SHORT).show()
                }
            })

            Spacer(modifier = Modifier.height(16.dp))
            
            SectionTitle("Tare Adapters")
            CalibrationObjectCard(
                title = "Pickleball Adapter",
                measurements = uiState.measurementsTarePB,
                fitThreshold = uiState.fitResidualExclusion,
                trimLast = uiState.trimLastCycle,
                periodResolution = uiState.periodUnitsResolution
            ) { viewModel.selectCalibrationTarget(MOIViewModel.CalibrationTarget.TARE_PB) }
            
            Spacer(modifier = Modifier.height(2.0.dp))
            
            CalibrationObjectCard(
                title = "Twist Weight Adapter",
                measurements = uiState.measurementsTareTW,
                fitThreshold = uiState.fitResidualExclusion,
                trimLast = uiState.trimLastCycle,
                periodResolution = uiState.periodUnitsResolution
            ) { viewModel.selectCalibrationTarget(MOIViewModel.CalibrationTarget.TARE_TW) }

            if (uiState.measurementsTarePB.isNotEmpty() || uiState.measurementsTareTW.isNotEmpty()) {
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedButton(
                    onClick = { showReTareConfirm = true },
                    modifier = Modifier.fillMaxWidth().height(48.dp),
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.Red),
                    border = ButtonDefaults.outlinedButtonBorder(enabled = true).copy(brush = SolidColor(Color.Red)),
                ) {
                    Text("Re-Tare", fontWeight = FontWeight.Bold)
                }
            }


            Spacer(modifier = Modifier.height(32.dp))
        }

        if (uiState.isNfcScanning || uiState.nfcStatus != null) {
            AlertDialog(
                onDismissRequest = { viewModel.setNfcScanning(false) },
                title = { Text("NFC Calibration") },
                text = {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(uiState.nfcStatus ?: "Ready to Scan...")
                        if (uiState.isNfcScanning) {
                            Spacer(modifier = Modifier.height(24.dp))
                            CircularProgressIndicator(
                                color = MaterialTheme.colorScheme.primary,
                                modifier = Modifier.size(48.dp)
                            )
                        }
                    }
                },
                confirmButton = {
                    if (!uiState.nfcEnabled) {
                        Button(onClick = {
                            val intent = Intent(Settings.ACTION_NFC_SETTINGS)
                            context.startActivity(intent)
                        }) {
                            Text("Settings")
                        }
                    }
                },
                dismissButton = {
                    TextButton(onClick = { viewModel.setNfcScanning(false) }) {
                        Text(if (!uiState.nfcEnabled) "Cancel" else "Close")
                    }
                }
            )
        }

        if (showRecalibrateConfirm) {
            DeleteConfirmationDialog(
                title = "Recalibrate?",
                text = "This will delete all measurements for both Object A and Object B. Are you sure?",
                onConfirm = { viewModel.recalibrate(); showRecalibrateConfirm = false },
                onDismiss = { showRecalibrateConfirm = false }
            )
        }

        if (showReTareConfirm) {
            DeleteConfirmationDialog(
                title = "Re-Tare?",
                text = "This will delete all measurements for both Tare adapters. Are you sure?",
                onConfirm = { viewModel.reTare(); showReTareConfirm = false },
                onDismiss = { showReTareConfirm = false }
            )
        }
    }
}

@Composable
fun CalibrationObjectCard(
    title: String,
    measurements: List<Measurement>,
    fitThreshold: Double,
    trimLast: Boolean = true,
    periodResolution: Int = 4,
    onClick: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable { onClick() },
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 2.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(text = title, fontWeight = FontWeight.Bold, fontSize = 18.sp)
                Row(verticalAlignment = Alignment.CenterVertically) {
                    val filtered = measurements.filter { it.fitResidual < fitThreshold }
                    
                    val mPeriods = filtered.map { m ->
                        val cycles = m.cyclePeriods.split(",").filter { it.isNotEmpty() }.map { it.toDouble() }
                        if (trimLast && cycles.size > 1) cycles.dropLast(1).average() else if (cycles.isNotEmpty()) cycles.average() else m.period
                    }

                    val avgPeriod = if (mPeriods.isNotEmpty()) mPeriods.average() else 0.0

                    val stdDev = if (mPeriods.size > 1) {
                        val variance = mPeriods.asSequence().map { (it - avgPeriod).let { d -> d * d } }.average()
                        sqrt(variance)
                    } else 0.0
                    
                    val pFormat = "%.${periodResolution}f"
                    
                    val periodText = String.format(Locale.US, "Period: $pFormat ± ${pFormat}s", avgPeriod, stdDev)

                    Text(text = periodText, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary, maxLines = 1, softWrap = false)
                    Spacer(modifier = Modifier.width(16.dp))
                    Text(text = "Readings: ${measurements.size}", fontSize = 14.sp, color = MaterialTheme.colorScheme.outline)
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingRowField(label: String, value: String, onValueChange: (String) -> Unit) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
        modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp)
    ) {
        Text(label, modifier = Modifier.weight(1f), fontSize = 16.sp)
        
        val interactionSource = remember { MutableInteractionSource() }
        val colors = OutlinedTextFieldDefaults.colors(
            focusedTextColor = MaterialTheme.colorScheme.primary,
            unfocusedTextColor = MaterialTheme.colorScheme.primary,
            disabledTextColor = MaterialTheme.colorScheme.primary,
            cursorColor = MaterialTheme.colorScheme.primary
        )
        val textStyle = LocalTextStyle.current.copy(
            color = MaterialTheme.colorScheme.onSurface,
            fontSize = 18.sp, 
            textAlign = TextAlign.End
        )
        
        BasicTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier.width(200.dp).height(48.dp),
            singleLine = true,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            textStyle = textStyle,
            interactionSource = interactionSource
        ) { innerTextField ->
            OutlinedTextFieldDefaults.DecorationBox(
                value = value,
                innerTextField = innerTextField,
                enabled = true,
                singleLine = true,
                visualTransformation = VisualTransformation.None,
                interactionSource = interactionSource,
                colors = colors,
                container = {
                    OutlinedTextFieldDefaults.Container(
                        enabled = true,
                        isError = false,
                        interactionSource = interactionSource,
                        colors = colors,
                        shape = OutlinedTextFieldDefaults.shape
                    )
                },
                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 0.dp)
            )
        }
    }
}
