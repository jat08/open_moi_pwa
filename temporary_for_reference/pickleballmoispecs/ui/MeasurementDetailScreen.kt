package com.example.pickleballmoispecs.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.drawText
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.combinedClickable
import com.example.pickleballmoispecs.data.Measurement
import kotlinx.coroutines.flow.first
import androidx.compose.ui.graphics.luminance
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs

@Composable
fun MeasurementDetailScreen(viewModel: MOIViewModel, measurement: Measurement) {
    val uiState by viewModel.uiState.collectAsState()
    var refMoiA by remember { mutableDoubleStateOf(0.0) }
    var refMoiB by remember { mutableDoubleStateOf(0.0) }

    val cycles = remember(measurement.cyclePeriods) {
        measurement.cyclePeriods.split(",").asSequence().filter { it.isNotEmpty() }.map { it.toDouble() }.toList()
    }

    LaunchedEffect(Unit) {
        refMoiA = viewModel.appPreferences.knownObjectAInertia.first()
        refMoiB = viewModel.appPreferences.knownObjectBInertia.first()
    }

    BackHandler {
        viewModel.selectMeasurement(null)
    }

    Column(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 0.dp)) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 16.dp),
        ) {
            IconButton(
                onClick = { viewModel.selectMeasurement(null) },
                modifier = Modifier.offset(x = (-12).dp),
            ) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
            Text(
                text = "Measurement Data",
                fontSize = 28.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f),
            )
        }

        Column(modifier = Modifier.verticalScroll(rememberScrollState())) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            ) {
                Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 2.dp)) {
                    Row(modifier = Modifier.fillMaxWidth()) {
                        val displayType = when (measurement.type) {
                            "OBJECT_A", "OBJECT_B" -> "Calibration Object"
                            "TARE_PB", "TARE_TW" -> "Tare Adapter"
                            else -> "Paddle/Racquet"
                        }
                        
                        val swTwLabel = if (measurement.type == "PADDLE") {
                            if (measurement.moi >= 40) " (SW)" else " (TW)"
                        } else ""

                        InfoBit("Type", displayType + swTwLabel, modifier = Modifier.weight(1.4f))
                        InfoBit("Tare", measurement.tareMode, modifier = Modifier.weight(0.6f))
                    }
                    
                    Spacer(modifier = Modifier.height(1.dp))
                    
                    val trimLast = uiState.trimLastCycle
                    
                    val avgMeasured = if (cycles.isNotEmpty()) {
                        val candidates = if ((trimLast) && (cycles.size > 1)) cycles.dropLast(1) else cycles
                        candidates.average()
                    } else measurement.period

                    Row(modifier = Modifier.fillMaxWidth()) {
                        val moiFormat = "%.${uiState.moiUnitsResolution}f"
                        val pFormat = "%.${uiState.periodUnitsResolution}f"
                        
                        val finalMoiValue = when (measurement.type) {
                            "OBJECT_A" -> refMoiA
                            "OBJECT_B" -> refMoiB
                            else -> measurement.moi
                        }
                        
                        val finalMoiText = when (measurement.type) {
                            "OBJECT_A" -> String.format(Locale.US, "%.2f", refMoiA)
                            "OBJECT_B" -> String.format(Locale.US, "%.2f", refMoiB)
                            else -> String.format(Locale.US, moiFormat, finalMoiValue)
                        }
                        
                        val periodText = String.format(Locale.US, "${pFormat}s", avgMeasured)

                        val clipboardManager = androidx.compose.ui.platform.LocalClipboardManager.current
                        val context = androidx.compose.ui.platform.LocalContext.current

                        InfoBit(
                            label = "MOI", 
                            value = finalMoiText, 
                            modifier = Modifier.weight(1.4f),
                            onLongClick = {
                                val numeric = String.format(Locale.US, moiFormat, finalMoiValue)
                                clipboardManager.setText(androidx.compose.ui.text.AnnotatedString(numeric))
                                android.widget.Toast.makeText(context, "Copied MOI: $numeric", android.widget.Toast.LENGTH_SHORT).show()
                            }
                        )
                        InfoBit(
                            label = "Period", 
                            value = periodText, 
                            modifier = Modifier.weight(0.6f),
                            onLongClick = {
                                val numeric = String.format(Locale.US, pFormat, avgMeasured)
                                clipboardManager.setText(androidx.compose.ui.text.AnnotatedString(numeric))
                                android.widget.Toast.makeText(context, "Copied Period: $numeric", android.widget.Toast.LENGTH_SHORT).show()
                            }
                        )
                    }

                    Spacer(modifier = Modifier.height(1.dp))

                    Row(modifier = Modifier.fillMaxWidth()) {
                        InfoBit("Time", SimpleDateFormat("h:mm a", Locale.US).format(Date(measurement.timestamp)), modifier = Modifier.weight(1.4f))
                        InfoBit("Date", SimpleDateFormat("M/d/yy", Locale.US).format(Date(measurement.timestamp)), modifier = Modifier.weight(0.6f))
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            Text("Oscillation Graph", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.height(8.dp))

            OscillationGraph(measurement)

            Spacer(modifier = Modifier.height(24.dp))

            Text("Cycle Analysis", fontWeight = FontWeight.Bold, fontSize = 18.sp, color = MaterialTheme.colorScheme.primary)
            Spacer(modifier = Modifier.height(8.dp))
            
            if (cycles.isNotEmpty()) {
                val trimLast = uiState.trimLastCycle
                val refIndex = uiState.cycleReference
                
                // Determine reference value for deviation check
                val activeCycles = cycles
                
                val refValue = if ((refIndex > 0) && (refIndex <= activeCycles.size)) {
                    activeCycles[refIndex - 1]
                } else {
                    val filteredForRef = if ((trimLast) && (activeCycles.size > 1)) activeCycles.dropLast(1) else activeCycles
                    filteredForRef.average()
                }
                
                // Determine margin for highlighting based on measurement type/MOI
                val isTW = ((measurement.type == "TARE_PB") || (measurement.type == "TARE_TW")) || 
                           ((measurement.type == "PADDLE") && (measurement.moi < 40))
                val margin = if (isTW) uiState.twMargin else uiState.swMargin
                
                val isDark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
                val warningYellow = if (isDark) Color(0xFF332D00) else Color(0xFFFFF9C4)
                val noteColor = if (isDark) Color.LightGray else Color(0xFF616161)

                cycles.forEachIndexed { index, period ->
                    val isRef = refIndex == (index + 1)
                    val isTrimmed = trimLast && index == (cycles.size - 1)
                    
                    val diff = abs(period - refValue) / refValue
                    val isExcluded = (!isTrimmed) && (diff > margin)
                    
                    Row(
                        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("Cycle #${index + 1}", color = if (isTrimmed) Color.Red else if (isExcluded) noteColor else Color.Gray)
                            if (isRef) {
                                Surface(
                                    color = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                                    shape = MaterialTheme.shapes.small,
                                    modifier = Modifier.padding(start = 8.dp),
                                ) {
                                    Text("REFERENCE", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary, modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp))
                                }
                            }
                            if (isTrimmed) {
                                Surface(
                                    color = Color.Red.copy(alpha = 0.1f),
                                    shape = MaterialTheme.shapes.small,
                                    modifier = Modifier.padding(start = 8.dp),
                                ) {
                                    Text("TRIMMED", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = Color.Red, modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp))
                                }
                            } else if (isExcluded) {
                                Surface(
                                    color = warningYellow,
                                    shape = MaterialTheme.shapes.small,
                                    modifier = Modifier.padding(start = 8.dp),
                                ) {
                                    Text("DEVIATION", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = noteColor, modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp))
                                }
                            }
                        }
                        
                        val pFormat = "%.${uiState.periodUnitsResolution}f"
                        val periodText = String.format(Locale.US, "${pFormat}s", period)

                        Text(
                            text = periodText,
                            fontWeight = FontWeight.Bold,
                            color = if (isTrimmed) Color.Red else if (isExcluded) noteColor else Color.Unspecified,
                        )
                    }
                    HorizontalDivider(thickness = 0.5.dp, color = Color.LightGray)
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun InfoBit(
    label: String, 
    value: String, 
    modifier: Modifier = Modifier,
    valueStyle: TextStyle = TextStyle(fontSize = 18.sp, fontWeight = FontWeight.Bold),
    onLongClick: (() -> Unit)? = null
) {
    Column(
        modifier = modifier.then(
            if (onLongClick != null) Modifier.combinedClickable(
                onClick = {},
                onLongClick = onLongClick
            ) else Modifier
        )
    ) {
        Text(label, fontSize = 12.sp, color = Color.Gray)
        Text(value, style = valueStyle)
    }
}

@Composable
fun OscillationGraph(measurement: Measurement) {
    val rawData = measurement.rawData.split(",").asSequence().filter { it.isNotEmpty() }.map { it.toFloat() }.toList()
    if (rawData.isEmpty() || measurement.totalDuration <= 0) {
        Box(Modifier.fillMaxWidth().height(200.dp), contentAlignment = Alignment.Center) {
            Text("No graph data available", color = Color.Gray)
        }
        return
    }

    val maxAmp = rawData.maxOfOrNull { abs(it) } ?: 1f
    val textMeasurer = rememberTextMeasurer()
    val secondaryColor = MaterialTheme.colorScheme.secondary

    
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceVariant, MaterialTheme.shapes.medium)
            .padding(top = 16.dp, start = 8.dp, end = 8.dp, bottom = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(modifier = Modifier.fillMaxWidth().height(200.dp)) {
            Canvas(modifier = Modifier.fillMaxSize()) {
                val width = size.width
                val height = size.height
                val centerY = height / 2f
                
                val totalSeconds = measurement.totalDuration
                val pixelsPerSecond = width / totalSeconds
                
                var t = 0.0
                while (t <= totalSeconds + 0.001) {
                    val xMark = (t * pixelsPerSecond).toFloat()
                    val isFullSecond = abs(t % 1.0) < 0.01
                    val isHalfSecond = abs(t % 0.5) < 0.01
                    
                    // Vertical Grid Line
                    if (isFullSecond) {
                        drawLine(
                            color = Color.Gray.copy(alpha = 0.7f),
                            start = Offset(xMark, 0f),
                            end = Offset(xMark, height),
                            strokeWidth = 2.dp.toPx(), // Solid and thicker
                        )
                        
                        // Time Label (Full seconds only)
                        val timeLabel = String.format(Locale.US, "%ds", t.toInt())
                        val textLayoutResult = textMeasurer.measure(
                            text = timeLabel,
                            style = TextStyle(fontSize = 11.sp, color = Color.DarkGray, fontWeight = FontWeight.Bold),
                        )
                        drawText(
                            textLayoutResult = textLayoutResult,
                            topLeft = Offset(xMark - textLayoutResult.size.width / 2f, height + 8.dp.toPx()),
                        )
                    } else if (isHalfSecond) {
                        // Dashed line for 0.5s
                        drawLine(
                            color = Color.LightGray.copy(alpha = 0.5f),
                            start = Offset(xMark, 0f),
                            end = Offset(xMark, height),
                            strokeWidth = 1.dp.toPx(),
                            pathEffect = PathEffect.dashPathEffect(floatArrayOf(30f, 30f), 0f),
                        )
                    } else {
                        // Dashed line for 0.25s and 0.75s
                        drawLine(
                            color = Color.LightGray.copy(alpha = 0.5f),
                            start = Offset(xMark, 0f),
                            end = Offset(xMark, height),
                            strokeWidth = 1.dp.toPx(),
                            pathEffect = PathEffect.dashPathEffect(floatArrayOf(10f, 10f), 0f),
                        )
                    }
                    
                    t += 0.25
                }
                
                // Draw Center Axis
                drawLine(Color.LightGray, Offset(0f, centerY), Offset(width, centerY), strokeWidth = 1.5.dp.toPx())
                
                val step = width / (rawData.size - 1)

                // Draw Theoretical Sine Wave (Dashed Overlay)
                val theoreticalPath = Path()
                val period = measurement.period
                val pointCount = rawData.size
                if (period > 0) {
                    val initialPhase = if (rawData.size > 1 && rawData[1] < rawData[0]) kotlin.math.PI else 0.0
                    for (i in 0 until pointCount) {
                        val time = (i.toDouble() / (pointCount - 1)) * totalSeconds
                        val amp = maxAmp * kotlin.math.sin(2.0 * kotlin.math.PI * time / period + initialPhase)
                        val x = i * step
                        val y = centerY - (amp.toFloat() / maxAmp) * (height / 2.2f)
                        if (i == 0) theoreticalPath.moveTo(x, y) else theoreticalPath.lineTo(x, y)
                    }
                    drawPath(
                        path = theoreticalPath,
                        color = secondaryColor.copy(alpha = 0.7f),
                        style = Stroke(
                            width = 1.5.dp.toPx(),
                            pathEffect = PathEffect.dashPathEffect(floatArrayOf(10f, 10f), 0f)
                        )
                    )
                }

                // Draw Waveform Path (Actual Measurement)
                val path = Path()
                
                rawData.forEachIndexed { i, amp ->
                    val x = i * step
                    val y = centerY - (amp / maxAmp) * (height / 2.2f)
                    if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
                }
                
                drawPath(path, Color(0xFF34A4EB), style = Stroke(width = 2.dp.toPx()))
            }
        }

        Spacer(modifier = Modifier.height(24.dp)) // Space for time labels

        // Graph Legend (Horizontal)
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            LegendItem("Physical Measurement", Color(0xFF34A4EB), isDashed = false)
            Spacer(modifier = Modifier.width(24.dp))
            LegendItem("Theoretical Fit", secondaryColor, isDashed = true)
        }
    }
}

@Composable
fun LegendItem(label: String, color: Color, isDashed: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Canvas(modifier = Modifier.size(20.dp, 2.dp)) {
            drawLine(
                color = color,
                start = Offset(0f, size.height / 2),
                end = Offset(size.width, size.height / 2),
                strokeWidth = 2.dp.toPx(),
                pathEffect = if (isDashed) PathEffect.dashPathEffect(floatArrayOf(5f, 5f), 0f) else null
            )
        }
        Spacer(modifier = Modifier.width(8.dp))
        Text(text = label, fontSize = 10.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}
