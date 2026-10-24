package com.example.pickleballmoispecs.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pickleballmoispecs.data.MeasurementGroup
import java.util.*
import kotlin.math.pow
import kotlin.math.sqrt

@Composable
fun GroupAttributesScreen(viewModel: MOIViewModel, group: MeasurementGroup) {
    val uiState by viewModel.uiState.collectAsState()
    
    var m by remember(group.id) { mutableStateOf(if (group.mass > 0) group.mass.toString() else "") }
    var mUnit by remember(group.id) { mutableStateOf(group.massUnit) }
    var l by remember(group.id) { mutableStateOf(if (group.length > 0) group.length.toString() else "") }
    var lUnit by remember(group.id) { mutableStateOf(group.lengthUnit) }
    var w by remember(group.id) { mutableStateOf(if (group.width > 0) group.width.toString() else "") }
    var wUnit by remember(group.id) { mutableStateOf(group.widthUnit) }
    var type by remember(group.id) { mutableStateOf(group.groupType) }

    BackHandler {
        viewModel.selectEditingAttributesGroup(null)
    }

    Column(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 0.dp).imePadding()) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 16.dp),
        ) {
            IconButton(
                onClick = { viewModel.selectEditingAttributesGroup(null) },
                modifier = Modifier.offset(x = (-12).dp)
            ) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
            DynamicTitleText(
                text = "Info: ${group.name}",
                maxFontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier
                    .weight(1f)
                    .padding(end = 12.dp),
            )
        }

        Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            // Measured Results Section (Read-only)
            SectionTitle("Measured Results", bottomPadding = 4.dp)
            
            val format = when (uiState.moiUnitsResolution) {
                0 -> "%.0f"
                1 -> "%.1f"
                2 -> "%.2f"
                3 -> "%.3f"
                4 -> "%.4f"
                else -> "%.1f"
            }

            val swDisplay = "%s kg·cm²".format(Locale.US, String.format(Locale.US, format, uiState.currentSWAverage))
            val twDisplay = "%s kg·cm²".format(Locale.US, String.format(Locale.US, format, uiState.currentTWAverage))

            // BP Calculation Logic replicated from GroupDetailScreen
            val calculatedBP = if ((group.mass > 0) && (group.length > 0)) {
                val sw = uiState.currentSWAverage
                val massKg = when (group.massUnit) {
                    "oz" -> group.mass * 0.028349523125
                    "lb" -> group.mass * 0.45359237
                    else -> group.mass
                }
                
                if (group.groupType == "Pickleball Paddle") {
                    val lInches = if (group.lengthUnit == "cm") group.length / 2.54 else group.length
                    (sw - (492.0045 * massKg) - (6.8663 * lInches) + 259.5087) / 6.2811
                } else {
                    val lengthCm = if (group.lengthUnit == "in") group.length * 2.54 else group.length
                    val tOffset = if (group.groupType == "Racquet" || group.groupType == "MOI-10") 10.0 else 5.0
                    val r = 9.1
                    
                    try {
                        val insideSqrt = (sw / massKg) - (lengthCm.pow(2) / 12.0) - (r.pow(2) / 4.0)
                        if (insideSqrt >= 0) {
                            val root = sqrt(insideSqrt)
                            root + tOffset
                        } else null
                    } catch (_: Exception) { null }
                }
            } else null

            val bpDisplay = if (calculatedBP != null) {
                val bpValStr = String.format(Locale.US, format, calculatedBP)
                "$bpValStr cm"
            } else "N/A"

            val clipboardManager = androidx.compose.ui.platform.LocalClipboardManager.current
            val context = androidx.compose.ui.platform.LocalContext.current

            ReadOnlySettingField("Measured SW", swDisplay, onLongClick = {
                val numeric = String.format(Locale.US, format, uiState.currentSWAverage)
                clipboardManager.setText(androidx.compose.ui.text.AnnotatedString(numeric))
                android.widget.Toast.makeText(context, "Copied SW: $numeric", android.widget.Toast.LENGTH_SHORT).show()
            })
            ReadOnlySettingField("Measured TW", twDisplay, onLongClick = {
                val numeric = String.format(Locale.US, format, uiState.currentTWAverage)
                clipboardManager.setText(androidx.compose.ui.text.AnnotatedString(numeric))
                android.widget.Toast.makeText(context, "Copied TW: $numeric", android.widget.Toast.LENGTH_SHORT).show()
            })
            ReadOnlySettingField("Calculated BP", bpDisplay, onLongClick = {
                if (calculatedBP != null) {
                    val numeric = String.format(Locale.US, format, calculatedBP)
                    clipboardManager.setText(androidx.compose.ui.text.AnnotatedString(numeric))
                    android.widget.Toast.makeText(context, "Copied BP: $numeric", android.widget.Toast.LENGTH_SHORT).show()
                }
            })

            Spacer(modifier = Modifier.height(16.dp))
            
            SectionTitle("Physical Attributes", bottomPadding = 4.dp)
            EstimationInputField("Weight", m, mUnit, listOf("oz", "lb", "kg"), { m = it }, { mUnit = it })
            EstimationInputField("Length", l, lUnit, listOf("in", "cm"), { l = it }, { lUnit = it })
            EstimationInputField("Width", w, wUnit, listOf("in", "cm"), { w = it }, { wUnit = it })
            
            val typeOptions = listOf("Pickleball Paddle", "Racquet")
            TypeSelector("Type", type, typeOptions) { type = it }

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    val mVal = m.toDoubleOrNull() ?: 0.0
                    val lVal = l.toDoubleOrNull() ?: 0.0
                    val wVal = w.toDoubleOrNull() ?: 0.0
                    viewModel.updateGroupAttributes(group, mVal, mUnit, lVal, lUnit, wVal, wUnit, type)
                    viewModel.selectEditingAttributesGroup(null)
                },
                modifier = Modifier.fillMaxWidth().height(56.dp)
            ) {
                Text("Save Attributes", fontWeight = FontWeight.Bold, fontSize = 18.sp)
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}
