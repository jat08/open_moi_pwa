package com.example.pickleballmoispecs.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.gestures.snapping.rememberSnapFlingBehavior
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color

import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import android.widget.Toast
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.CheckBox
import androidx.compose.material.icons.filled.CheckBoxOutlineBlank
import com.example.pickleballmoispecs.data.Measurement
import com.example.pickleballmoispecs.logic.MomentOfInertiaCalculator
import com.example.pickleballmoispecs.logic.OscillationDetector
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs

@Composable
fun DynamicTitleText(
    text: String,
    maxFontSize: TextUnit,
    modifier: Modifier = Modifier,
    color: Color = Color.Unspecified,
    fontWeight: FontWeight? = null,
    fontStyle: FontStyle? = null,
    fontFamily: FontFamily? = null,
    textAlign: TextAlign? = null,
) {
    val textMeasurer = rememberTextMeasurer()
    BoxWithConstraints(modifier = modifier) {
        // Extreme safety buffer (64px) to prevent cropping with Bold/Italic/Serif fonts
        val availableWidth = (this.constraints.maxWidth.toFloat() - 64f).coerceAtLeast(0f)
        
        val fontSize = remember(text, availableWidth, maxFontSize, fontWeight, fontStyle, fontFamily) {
            if (availableWidth <= 0f) return@remember maxFontSize
            var currentSize = maxFontSize.value
            var fitSize = 8f
            while (currentSize > 8f) {
                val measuredWidth = textMeasurer.measure(
                    text = text,
                    style = TextStyle(
                        fontSize = currentSize.sp,
                        fontWeight = fontWeight,
                        fontStyle = fontStyle,
                        fontFamily = fontFamily
                    ),
                    maxLines = 1,
                    softWrap = false
                ).size.width
                
                if (measuredWidth <= availableWidth) {
                    fitSize = currentSize
                    break
                }
                currentSize -= 0.5f
            }
            fitSize.sp
        }
        
        Text(
            text = text,
            fontSize = fontSize,
            fontWeight = fontWeight,
            fontStyle = fontStyle,
            fontFamily = fontFamily,
            color = color,
            textAlign = textAlign,
            maxLines = 1,
            softWrap = false,
            overflow = TextOverflow.Clip
        )
    }
}

@Composable
fun SelectionTopBar(
    count: Int,
    isAllSelected: Boolean,
    onToggleAll: () -> Unit,
    onClear: () -> Unit,
    onDelete: () -> Unit
) {
    var showConfirm by remember { mutableStateOf(value = false) }

    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp),
        color = MaterialTheme.colorScheme.primaryContainer,
        shape = MaterialTheme.shapes.medium
    ) {
        Row(
            modifier = Modifier
                .padding(horizontal = 8.dp)
                .fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = onClear) {
                    Icon(Icons.Default.Close, contentDescription = "Clear selection")
                }
                
                IconButton(onClick = onToggleAll) {
                    Icon(
                        if (isAllSelected) Icons.Default.CheckBox else Icons.Default.CheckBoxOutlineBlank,
                        contentDescription = if (isAllSelected) "Deselect all" else "Select all",
                        tint = MaterialTheme.colorScheme.primary
                    )
                }

                Spacer(modifier = Modifier.width(4.dp))
                
                Text(
                    text = "$count selected",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                    modifier = Modifier.clickable { onToggleAll() }
                )
            }
            IconButton(
                onClick = { showConfirm = true },
                enabled = count > 0
            ) {
                Icon(
                    Icons.Default.Delete, 
                    contentDescription = "Delete selected",
                    tint = if (count > 0) Color.Red else Color.Gray.copy(alpha = 0.5f)
                )
            }
        }
    }

    if (showConfirm) {
        DeleteConfirmationDialog(
            title = "Delete Items?",
            text = "Are you sure you want to delete $count selected items? This action cannot be undone.",
            onConfirm = { 
                onDelete()
                showConfirm = false 
            },
            onDismiss = { showConfirm = false },
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MeasurementItem(
    measurement: Measurement, 
    onDelete: () -> Unit,
    onClick: () -> Unit = {},
    onLongClick: () -> Unit = {},
    selected: Boolean = false,
    resolution: Int = 1,
    periodResolution: Int = 4,
    averageVal: Double = 0.0,
    index: Int = 0,
    showType: Boolean = true,
    isPeriod: Boolean = false,
    fitThreshold: Double = 1.0,
    margin: Double = 0.07,
    trimLast: Boolean = true,
) {
    var showDeleteConfirm by remember { mutableStateOf(value = false) }

    val mCycles = remember(measurement.cyclePeriods) {
        measurement.cyclePeriods.split(",").asSequence().filter { it.isNotEmpty() }.map { it.toDouble() }.toList()
    }

    val avgMeasured = if (mCycles.isNotEmpty()) {
        val candidates = if (trimLast && mCycles.size > 1) mCycles.dropLast(1) else mCycles
        candidates.average()
    } else measurement.period

    val value = if (isPeriod) {
        avgMeasured
    } else {
        measurement.moi
    }
    
    val isOutlier = if (averageVal > 0) {
        val deviation = abs(value - averageVal) / averageVal
        deviation > margin
    } else false

    val pFormat = "%.${periodResolution}f"
    val format = if (isPeriod) pFormat else when (resolution) {
        0 -> "%.0f"
        2 -> "%.2f"
        3 -> "%.3f"
        4 -> "%.4f"
        else -> "%.1f"
    }
    
    val unit = if (isPeriod) "s" else "kg·cm²"

    val typeMarking = if (measurement.moi >= 40) "SW" else "TW"
    
    val isDark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    
    val errorRed = if (isDark) Color(0xFF3D1B1B) else Color(0xFFFFEBEE)
    val warningYellow = if (isDark) Color(0xFF332D00) else Color(0xFFFFF9C4)
    val noteColor = if (isDark) Color.LightGray else Color(0xFF616161)

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 1.3.dp)
            .combinedClickable(
                onClick = onClick,
                onLongClick = onLongClick
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (selected) {
                MaterialTheme.colorScheme.primaryContainer
            } else if (measurement.fitResidual >= fitThreshold) {
                errorRed
            } else if (isOutlier) {
                warningYellow
            } else {
                MaterialTheme.colorScheme.surfaceVariant
            }
        ),
        border = if (selected) BorderStroke(2.dp, MaterialTheme.colorScheme.primary) else null
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 0.5.dp).fillMaxWidth(), 
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.weight(1f)) {
                Text(
                    text = "#$index",
                    fontSize = 12.sp,
                    color = Color.Gray,
                    modifier = Modifier.width(28.dp)
                )

                if (showType && !isPeriod) {
                    Surface(
                        color = if (measurement.moi >= 40) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.secondary,
                        shape = MaterialTheme.shapes.small
                    ) {
                        Text(
                            text = typeMarking,
                            modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp),
                            color = Color.White,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(modifier = Modifier.width(12.dp))
                }
                
                Column {
                    val periodLabel = if (isPeriod) {
                        String.format(Locale.US, "${pFormat}s", avgMeasured)
                    } else {
                        String.format(Locale.US, "$format $unit", value)
                    }

                    Text(
                        text = periodLabel,
                        fontWeight = FontWeight.Bold,
                        color = if (measurement.fitResidual >= fitThreshold) Color.Red else Color.Unspecified
                    )
                    val detailStyle = TextStyle(fontSize = 11.sp, color = Color.Gray)
                    if (!isPeriod) {
                        val pText = String.format(Locale.US, "Period: ${pFormat}s", avgMeasured)
                        Text(text = pText, style = detailStyle)
                        Text(text = "Tare: ${measurement.tareMode}", style = detailStyle)
                    }
                    Text(text = String.format(Locale.US, "Fit Residual: %.3f", measurement.fitResidual), style = detailStyle.copy(color = if (measurement.fitResidual >= fitThreshold) Color.Red else Color.Gray))
                    
                    if (measurement.fitResidual >= fitThreshold) {
                        Text(
                            text = "Poor Fit Quality",
                            color = Color.Red,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    } else if (isOutlier) {
                        Text(
                            text = "High Deviation",
                            color = noteColor,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
            
            Row(verticalAlignment = Alignment.CenterVertically) {
                Column(horizontalAlignment = Alignment.End) {
                    val stampStyle = TextStyle(fontSize = 11.sp, color = Color.Gray)
                    Text(
                        text = SimpleDateFormat("h:mm a", Locale.US).format(Date(measurement.timestamp)),
                        style = stampStyle
                    )
                    Text(
                        text = SimpleDateFormat("M/d/yy", Locale.US).format(Date(measurement.timestamp)),
                        style = stampStyle
                    )
                }
                IconButton(onClick = { showDeleteConfirm = true }) {
                    Icon(Icons.Default.Delete, contentDescription = "Delete", tint = Color.Gray, modifier = Modifier.size(20.dp))
                }
            }
        }
    }

    if (showDeleteConfirm) {
        DeleteConfirmationDialog(
            title = "Delete Measurement?",
            text = "Are you sure you want to delete this measurement? The list will be renumbered.",
            onConfirm = { onDelete(); showDeleteConfirm = false },
            onDismiss = { showDeleteConfirm = false }
        )
    }
}

@Composable
fun MeasurementControlButton(
    state: OscillationDetector.State,
    progress: Float,
    isCalibrated: Boolean = true, // Default to true for calibration screens
    cooldownRemaining: Double = 0.0,
    preparationRemaining: Int = 0,
    onStart: () -> Unit
) {
    Surface(
        modifier = Modifier
            .fillMaxWidth()
            .height(56.dp),
        shape = MaterialTheme.shapes.medium,
        color = MaterialTheme.colorScheme.surfaceVariant
    ) {
        when {
            !isCalibrated -> {
                Surface(
                    color = MaterialTheme.colorScheme.errorContainer,
                    shape = MaterialTheme.shapes.medium,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            "Calibrate Device First",
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp
                        )
                    }
                }
            }
            state == OscillationDetector.State.WRONG_ORIENTATION -> {
                Surface(
                    color = MaterialTheme.colorScheme.errorContainer,
                    shape = MaterialTheme.shapes.medium,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            "Hold Phone at 45°",
                            color = MaterialTheme.colorScheme.onErrorContainer,
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp
                        )
                    }
                }
            }
            preparationRemaining > 0 -> {
                Surface(
                    color = Color.Gray,
                    shape = MaterialTheme.shapes.medium,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            "Waiting $preparationRemaining Seconds to be Ready",
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp
                        )
                    }
                }
            }
            cooldownRemaining > 0 -> {
                Surface(
                    color = Color.Gray,
                    shape = MaterialTheme.shapes.medium,
                    modifier = Modifier.fillMaxSize()
                ) {
                    Box(contentAlignment = Alignment.Center) {
                        Text(
                            text = String.format(Locale.US, "Waiting %d seconds", cooldownRemaining.toInt()),
                            color = Color.White,
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp
                        )
                    }
                }
            }
            else -> {
                when (state) {
                    OscillationDetector.State.READY -> {
                        Button(
                            onClick = onStart,
                            modifier = Modifier.fillMaxSize(),
                            shape = MaterialTheme.shapes.medium
                        ) {
                            Text("Start Measurement", fontSize = 18.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                    OscillationDetector.State.ARMED -> {
                        Surface(
                            color = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f),
                            shape = MaterialTheme.shapes.medium,
                            modifier = Modifier.fillMaxSize()
                        ) {
                            Box(contentAlignment = Alignment.Center) {
                                Text(
                                    "Ready - Waiting for Oscillations",
                                    color = MaterialTheme.colorScheme.primary,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 18.sp
                                )
                            }
                        }
                    }
                    OscillationDetector.State.SETTLING, OscillationDetector.State.ACTIVE_COUNTING -> {
                        val label = if (state == OscillationDetector.State.SETTLING) "Settling..." else "Measuring..."
                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .clip(MaterialTheme.shapes.medium)
                                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.15f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxHeight()
                                    .fillMaxWidth(fraction = progress.coerceIn(0f, 1f))
                                    .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.35f))
                                    .align(Alignment.CenterStart)
                            )
                            Text(
                                text = "$label ${(progress * 100).toInt()}%",
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold,
                                color = MaterialTheme.colorScheme.primary
                            )
                        }
                    }
                    OscillationDetector.State.WRONG_ORIENTATION -> {} // Handled above
                }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun SummaryHeaderLarge(
    avgSW: Double,
    stdDevSW: Double,
    avgTW: Double,
    stdDevTW: Double,
    avgPeriodSW: Double,
    stdDevPeriodSW: Double,
    avgPeriodTW: Double,
    stdDevPeriodTW: Double,
    moiResolution: Int,
    periodResolution: Int = 4,
    calculatedBP: Double? = null,
    stdDevBP: Double? = null
) {
    val format = when (moiResolution) {
        0 -> "%.0f"
        1 -> "%.1f"
        2 -> "%.2f"
        3 -> "%.3f"
        4 -> "%.4f"
        else -> "%.1f"
    }
    
    val pFormat = "%.${periodResolution}f"
    
    val textMeasurer = rememberTextMeasurer()
    val clipboardManager = LocalClipboardManager.current
    val context = LocalContext.current
    
    BoxWithConstraints(modifier = Modifier.fillMaxWidth()) {
        val availableWidth = (this.constraints.maxWidth.toFloat() - 32f).coerceAtLeast(0f)
        
        val valSW = String.format(Locale.US, "$format ± $format kg·cm²", avgSW, stdDevSW)
        val valTW = String.format(Locale.US, "$format ± $format kg·cm²", avgTW, stdDevTW)
        
        val swString = "SW: $valSW"
        val twString = "TW: $valTW"
        
        val pSWValue = String.format(Locale.US, "$pFormat ± ${pFormat}s", avgPeriodSW, stdDevPeriodSW)
        val pTWValue = String.format(Locale.US, "$pFormat ± ${pFormat}s", avgPeriodTW, stdDevPeriodTW)
        
        val pswString = "Period SW: $pSWValue"
        val ptwString = "Period TW: $pTWValue"

        val bpString = if ((calculatedBP != null) && (calculatedBP > 0)) {
            val bpValStr = String.format(Locale.US, format, calculatedBP)
            val bpTolStr = if ((stdDevBP != null) && (stdDevBP > 0)) String.format(Locale.US, " ± $format", stdDevBP) else ""
            "BP: $bpValStr$bpTolStr cm"
        } else ""

        val fontSize = remember(swString, twString, pswString, ptwString, bpString, availableWidth) {
            if (availableWidth <= 0f) return@remember 32.sp
            var currentSize = 36f
            var fitSize = 8f
            while (currentSize > 8f) {
                val swWidth = textMeasurer.measure(
                    text = swString,
                    style = TextStyle(fontSize = currentSize.sp, fontWeight = FontWeight.Black)
                ).size.width.toFloat()
                val twWidth = textMeasurer.measure(
                    text = twString,
                    style = TextStyle(fontSize = currentSize.sp, fontWeight = FontWeight.Black)
                ).size.width.toFloat()
                
                val bpSize = currentSize * (17f / 22f)
                val periodSize = bpSize * 0.7f
                val pswWidth = textMeasurer.measure(pswString, TextStyle(fontSize = periodSize.sp, fontWeight = FontWeight.Black)).size.width.toFloat()
                val ptwWidth = textMeasurer.measure(ptwString, TextStyle(fontSize = periodSize.sp, fontWeight = FontWeight.Black)).size.width.toFloat()
                val bpWidth = if (bpString.isNotEmpty()) textMeasurer.measure(bpString, TextStyle(fontSize = periodSize.sp, fontWeight = FontWeight.Black)).size.width.toFloat() else 0f

                if ((swWidth <= availableWidth) && (twWidth <= availableWidth) && 
                    (pswWidth <= availableWidth) && (ptwWidth <= availableWidth) && (bpWidth <= availableWidth)) {
                    fitSize = currentSize
                    break
                }
                currentSize -= 0.5f
            }
            fitSize.sp
        }

        val bpFontSize = (fontSize.value * (17f / 22f)).sp
        val periodFontSize = (bpFontSize.value * 0.7f).sp

        Column(verticalArrangement = Arrangement.spacedBy(0.dp)) {
            Text(
                swString, 
                fontSize = fontSize, 
                fontWeight = FontWeight.Black, 
                color = MaterialTheme.colorScheme.primary, 
                maxLines = 1, 
                softWrap = false,
                overflow = TextOverflow.Clip,
                modifier = Modifier.combinedClickable(
                    onClick = {},
                    onLongClick = {
                        val numeric = String.format(Locale.US, format, avgSW)
                        clipboardManager.setText(AnnotatedString(numeric))
                        Toast.makeText(context, "Copied SW: $numeric", Toast.LENGTH_SHORT).show()
                    }
                )
            )
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.combinedClickable(
                    onClick = {},
                    onLongClick = {
                        val numeric = String.format(Locale.US, pFormat, avgPeriodSW)
                        clipboardManager.setText(AnnotatedString(numeric))
                        Toast.makeText(context, "Copied Period: $numeric", Toast.LENGTH_SHORT).show()
                    }
                )
            ) {
                Text("Period SW: ", fontSize = periodFontSize, color = Color.Gray, fontWeight = FontWeight.Bold, maxLines = 1, softWrap = false)
                Text(pSWValue, fontSize = periodFontSize, fontWeight = FontWeight.Black, color = MaterialTheme.colorScheme.primary, maxLines = 1, softWrap = false, overflow = TextOverflow.Clip)
            }
            
            if (calculatedBP != null && calculatedBP > 0) {
                val bpValStr = String.format(Locale.US, format, calculatedBP)
                val bpTolStr = if ((stdDevBP != null) && (stdDevBP > 0)) String.format(Locale.US, " ± $format", stdDevBP) else ""
                val fullBP = "$bpValStr$bpTolStr"
                
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.combinedClickable(
                        onClick = {},
                        onLongClick = {
                            clipboardManager.setText(AnnotatedString(bpValStr))
                            Toast.makeText(context, "Copied BP: $bpValStr", Toast.LENGTH_SHORT).show()
                        }
                    )
                ) {
                    Text("BP: ", fontSize = periodFontSize, color = Color.Gray, fontWeight = FontWeight.Bold, maxLines = 1, softWrap = false)
                    Text("$fullBP cm", fontSize = periodFontSize, fontWeight = FontWeight.Black, color = MaterialTheme.colorScheme.primary, maxLines = 1, softWrap = false, overflow = TextOverflow.Clip)
                }
            }

            HorizontalDivider(
                modifier = Modifier.padding(vertical = 4.dp),
                thickness = 0.5.dp,
                color = Color.LightGray.copy(alpha = 0.5f)
            )
            
            Text(
                twString, 
                fontSize = fontSize, 
                fontWeight = FontWeight.Black, 
                color = MaterialTheme.colorScheme.secondary, 
                maxLines = 1, 
                softWrap = false,
                overflow = TextOverflow.Clip,
                modifier = Modifier.combinedClickable(
                    onClick = {},
                    onLongClick = {
                        val numeric = String.format(Locale.US, format, avgTW)
                        clipboardManager.setText(AnnotatedString(numeric))
                        Toast.makeText(context, "Copied TW: $numeric", Toast.LENGTH_SHORT).show()
                    }
                )
            )
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.combinedClickable(
                    onClick = {},
                    onLongClick = {
                        val numeric = String.format(Locale.US, pFormat, avgPeriodTW)
                        clipboardManager.setText(AnnotatedString(numeric))
                        Toast.makeText(context, "Copied Period: $numeric", Toast.LENGTH_SHORT).show()
                    }
                )
            ) {
                Text("Period TW: ", fontSize = periodFontSize, color = Color.Gray, fontWeight = FontWeight.Bold, maxLines = 1, softWrap = false)
                Text(pTWValue, fontSize = periodFontSize, fontWeight = FontWeight.Black, color = MaterialTheme.colorScheme.secondary, maxLines = 1, softWrap = false, overflow = TextOverflow.Clip)
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun SingleSummaryHeader(
    label: String,
    avg: Double,
    stdDev: Double,
    moiResolution: Int,
    periodResolution: Int = 4,
    isPeriod: Boolean = false,
    label2: String? = null,
    avg2: Double = 0.0,
    stdDev2: Double = 0.0,
    showTolerance: Boolean = true,
    expectedNote: String? = null
) {
    val pFormat = "%.${periodResolution}f"
    val format = if (isPeriod) pFormat else when (moiResolution) {
        0 -> "%.0f"
        1 -> "%.1f"
        2 -> "%.2f"
        3 -> "%.3f"
        4 -> "%.4f"
        else -> "%.1f"
    }
    
    val unit = if (isPeriod) "s" else "kg·cm²"
    val textMeasurer = rememberTextMeasurer()
    val clipboardManager = LocalClipboardManager.current
    val context = LocalContext.current

    BoxWithConstraints(modifier = Modifier.fillMaxWidth()) {
        val availableWidth = (this.constraints.maxWidth.toFloat() - 32f).coerceAtLeast(0f)
        
        val labelClean = label.replace("Avg ", "").replace("Average ", "").replace("Avg", "").trim()
        val label2Clean = label2?.replace("Avg ", "")?.replace("Average ", "")?.replace("Avg", "")?.trim()
        
        val pStr = String.format(Locale.US, format, avg)
        
        val val1Str = if (showTolerance) {
            "$pStr ± " + String.format(Locale.US, "$format $unit", stdDev)
        } else {
            "$pStr $unit"
        }
        
        val line1Str = "$labelClean: $val1Str"
        val line2Str = if (label2Clean != null) {
            if (showTolerance) {
                "$label2Clean: " + String.format(Locale.US, "$format ± $format kg·cm²", avg2, stdDev2)
            } else {
                "$label2Clean: " + String.format(Locale.US, "$format kg·cm²", avg2)
            }
        } else ""

        val fontSize = remember(line1Str, line2Str, availableWidth) {
            if (availableWidth <= 0f) return@remember 32.sp
            var currentSize = 40f
            var fitSize = 10f
            while (currentSize > 10f) {
                val w1 = textMeasurer.measure(line1Str, TextStyle(fontSize = currentSize.sp, fontWeight = FontWeight.Bold)).size.width.toFloat()
                val w2 = if (line2Str.isNotEmpty()) textMeasurer.measure(line2Str, TextStyle(fontSize = currentSize.sp, fontWeight = FontWeight.Bold)).size.width.toFloat() else 0f
                
                if (w1 <= availableWidth && w2 <= availableWidth) {
                    fitSize = currentSize
                    break
                }
                currentSize -= 1f
            }
            fitSize.sp
        }

        Column {
            Text(
                line1Str, 
                fontSize = fontSize, 
                fontWeight = FontWeight.Bold, 
                color = MaterialTheme.colorScheme.primary, 
                maxLines = 1, 
                softWrap = false,
                modifier = Modifier.combinedClickable(
                    onClick = {},
                    onLongClick = {
                        val numeric = String.format(Locale.US, format, avg)
                        clipboardManager.setText(AnnotatedString(numeric))
                        Toast.makeText(context, "Copied $labelClean: $numeric", Toast.LENGTH_SHORT).show()
                    }
                )
            )
            if (line2Str.isNotEmpty()) {
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    line2Str, 
                    fontSize = fontSize, 
                    fontWeight = FontWeight.Bold, 
                    color = MaterialTheme.colorScheme.secondary, 
                    maxLines = 1, 
                    softWrap = false,
                    modifier = Modifier.combinedClickable(
                        onClick = {},
                        onLongClick = {
                            val numeric = String.format(Locale.US, format, avg2)
                            clipboardManager.setText(AnnotatedString(numeric))
                            Toast.makeText(context, "Copied $label2Clean: $numeric", Toast.LENGTH_SHORT).show()
                        }
                    )
                )
            }
            expectedNote?.let {
                Text(
                    text = it,
                    fontSize = 12.sp,
                    fontStyle = FontStyle.Italic,
                    color = Color.Gray,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }
        }
    }
}

@Composable
fun SectionHeader(title: String) {
    Text(
        text = title,
        modifier = Modifier.padding(top = 1.3.dp, bottom = 1.3.dp),
        fontWeight = FontWeight.Black,
        fontSize = 16.sp,
        color = MaterialTheme.colorScheme.primary
    )
}

@Composable
fun SectionTitle(title: String, bottomPadding: Dp = 2.6.dp) {
    Text(text = title, fontSize = 20.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
    Spacer(modifier = Modifier.height(bottomPadding))
}

@Composable
fun DeleteConfirmationDialog(title: String, text: String, onConfirm: () -> Unit, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(text) },
        confirmButton = {
            Button(onClick = onConfirm, colors = ButtonDefaults.buttonColors(containerColor = Color.Red)) {
                Text("Yes", color = Color.White)
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("No")
            }
        }
    )
}

@Composable
fun RenameDialog(currentName: String, onConfirm: (String) -> Unit, onDismiss: () -> Unit) {
    var name by remember { mutableStateOf(currentName) }
    val maxChars = 40
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Rename Group") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { 
                        if (it.length <= maxChars) name = it 
                    },
                    label = { Text("New Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )
                Text(
                    text = "Characters Left: ${maxChars - name.length}",
                    fontSize = 11.sp,
                    color = Color.Gray,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
        },
        confirmButton = {
            Button(onClick = { onConfirm(name); onDismiss() }) { Text("Rename") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

@Composable
fun SortDialog(
    currentType: MOIViewModel.SortType,
    currentDirection: MOIViewModel.SortDirection,
    onApply: (MOIViewModel.SortType, MOIViewModel.SortDirection) -> Unit,
    onDismiss: () -> Unit
) {
    var selectedType by remember { mutableStateOf(currentType) }
    var selectedDirection by remember { mutableStateOf(currentDirection) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Sort", fontWeight = FontWeight.Bold, fontSize = 20.sp) },
        text = {
            Column {
                Text("Type", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                Spacer(modifier = Modifier.height(8.dp))
                SortRadioButton("Name", selectedType == MOIViewModel.SortType.NAME) { selectedType = MOIViewModel.SortType.NAME }
                SortRadioButton("Date", selectedType == MOIViewModel.SortType.DATE) { selectedType = MOIViewModel.SortType.DATE }
                
                HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp))
                
                Text("Direction", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                Spacer(modifier = Modifier.height(8.dp))
                SortRadioButton("Ascending", selectedDirection == MOIViewModel.SortDirection.ASCENDING) { selectedDirection = MOIViewModel.SortDirection.ASCENDING }
                SortRadioButton("Descending", selectedDirection == MOIViewModel.SortDirection.DESCENDING) { selectedDirection = MOIViewModel.SortDirection.DESCENDING }
                
                HorizontalDivider(modifier = Modifier.padding(vertical = 12.dp))
            }
        },
        confirmButton = {
            Button(
                onClick = { onApply(selectedType, selectedDirection); onDismiss() },
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Apply")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}

@Composable
fun SortRadioButton(text: String, selected: Boolean, onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .height(48.dp)
            .selectable(
                selected = selected,
                onClick = onClick,
                role = Role.RadioButton
            )
            .padding(horizontal = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        RadioButton(selected = selected, onClick = null)
        Text(
            text = text,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.padding(start = 16.dp)
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
@Composable
fun ReadOnlySettingField(label: String, value: String, onLongClick: (() -> Unit)? = null) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
        modifier = Modifier
            .fillMaxWidth()
            .then(
                if (onLongClick != null) Modifier.combinedClickable(
                    onClick = {},
                    onLongClick = onLongClick
                ) else Modifier
            )
            .padding(vertical = 2.dp)
    ) {
        Text(label, modifier = Modifier.weight(0.9f), fontSize = 16.sp)
        
        val interactionSource = remember { MutableInteractionSource() }
        val colors = OutlinedTextFieldDefaults.colors(
            disabledTextColor = MaterialTheme.colorScheme.primary,
            disabledBorderColor = Color.Gray,
            disabledLeadingIconColor = Color.Gray
        )
        val textStyle = LocalTextStyle.current.copy(
            color = MaterialTheme.colorScheme.onSurface,
            fontSize = 18.sp, 
            textAlign = TextAlign.End
        )
        
        BasicTextField(
            value = value,
            onValueChange = {},
            modifier = Modifier.width(220.dp).height(48.dp),
            readOnly = true,
            enabled = false,
            textStyle = textStyle,
            singleLine = true,
            interactionSource = interactionSource
        ) { innerTextField ->
            OutlinedTextFieldDefaults.DecorationBox(
                value = value,
                innerTextField = innerTextField,
                enabled = false,
                singleLine = true,
                visualTransformation = VisualTransformation.None,
                interactionSource = interactionSource,
                leadingIcon = { Icon(Icons.Default.Lock, contentDescription = "Locked", tint = Color.Gray) },
                colors = colors,
                container = {
                    OutlinedTextFieldDefaults.Container(
                        enabled = false,
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

@Composable
fun NumberWheelPicker(
    value: Double,
    range: List<Double>,
    onValueChange: (Double) -> Unit,
    format: String = "%.1f",
    multiplyBy: Double = 1.0
) {
    var showDialog by remember { mutableStateOf(value = false) }

    TextButton(
        onClick = { showDialog = true },
        modifier = Modifier.height(48.dp)
    ) {
        Text(
            text = String.format(Locale.US, format, value * multiplyBy),
            fontSize = 16.sp,
            fontWeight = FontWeight.Normal
        )
    }

    if (showDialog) {
        Dialog(onDismissRequest = { showDialog = false }) {
            Surface(
                shape = MaterialTheme.shapes.medium,
                color = MaterialTheme.colorScheme.surface,
                tonalElevation = 8.dp
            ) {
                Column(
                    modifier = Modifier.padding(16.dp).width(200.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text("Select Value", fontWeight = FontWeight.Bold, fontSize = 18.sp)
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    val listState = rememberLazyListState(initialFirstVisibleItemIndex = range.indexOf(value).coerceAtLeast(0))

                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(160.dp)
                            .background(MaterialTheme.colorScheme.surfaceVariant, MaterialTheme.shapes.small),
                        contentAlignment = Alignment.Center
                    ) {
                        LazyColumn(
                            state = listState,
                            flingBehavior = rememberSnapFlingBehavior(lazyListState = listState),
                            modifier = Modifier.fillMaxSize(),
                            contentPadding = PaddingValues(vertical = 60.dp) // Adjusted for 160dp height
                        ) {
                            items(range.size) { index ->
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .height(40.dp)
                                        .clickable { 
                                            onValueChange(range[index])
                                            showDialog = false 
                                        },
                                    contentAlignment = Alignment.Center
                                ) {
                                    val isSelected = remember {
                                        derivedStateOf { listState.firstVisibleItemIndex == index }
                                    }
                                    Text(
                                        text = String.format(Locale.US, format, range[index] * multiplyBy),
                                        fontSize = 22.sp,
                                        fontWeight = if (isSelected.value) FontWeight.Bold else FontWeight.Normal,
                                        color = if (isSelected.value) MaterialTheme.colorScheme.primary else Color.Gray
                                    )
                                }
                            }
                        }
                        
                        Box(
                            modifier = Modifier
                                        .fillMaxWidth()
                                        .height(40.dp)
                                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f))
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Button(
                        onClick = { 
                            val currentIndex = listState.firstVisibleItemIndex
                            if (currentIndex in range.indices) {
                                onValueChange(range[currentIndex])
                            }
                            showDialog = false 
                        },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Confirm")
                    }
                }
            }
        }
    }
}

@Composable
fun EstimationInputField(
    label: String,
    value: String,
    unit: String,
    units: List<String>,
    onValueChange: (String) -> Unit,
    onUnitChange: (String) -> Unit,
    locked: Boolean = false
) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)
    ) {
        Text(label, modifier = Modifier.weight(1f), fontSize = 16.sp)
        OutlinedTextField(
            value = if (locked) "" else value,
            onValueChange = onValueChange,
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.width(120.dp).height(56.dp),
            singleLine = true,
            readOnly = locked,
            enabled = !locked,
            leadingIcon = if (locked) {
                { Icon(Icons.Default.Lock, contentDescription = "Locked", tint = Color.Gray) }
            } else null,
            textStyle = LocalTextStyle.current.copy(fontSize = 16.sp),
            colors = if (locked) {
                OutlinedTextFieldDefaults.colors(
                    disabledBorderColor = Color.Gray,
                    disabledLabelColor = Color.Gray,
                    disabledLeadingIconColor = Color.Gray
                )
            } else {
                OutlinedTextFieldDefaults.colors()
            }
        )
        Spacer(modifier = Modifier.width(8.dp))
        UnitPicklist(unit, units, onUnitChange)
    }
}

@Composable
fun UnitPicklist(current: String, options: List<String>, onSelect: (String) -> Unit) {
    var expanded by remember { mutableStateOf(value = false) }
    Box {
        OutlinedButton(
            onClick = { expanded = true },
            modifier = Modifier.width(80.dp).height(56.dp),
            shape = MaterialTheme.shapes.small
        ) {
            Text(current, fontSize = 14.sp)
        }
        DropdownMenu(
            expanded = expanded, 
            onDismissRequest = { expanded = false },
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        ) {
            options.forEach { option ->
                DropdownMenuItem(
                    text = { Text(option, fontSize = 16.sp, fontWeight = FontWeight.Normal) },
                    onClick = { onSelect(option); expanded = false },
                    contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
                )
            }
        }
    }
}

@Composable
fun TypeSelector(label: String, current: String, options: List<String>, onSelect: (String) -> Unit) {
    var expanded by remember { mutableStateOf(value = false) }
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)
    ) {
        Text(label, modifier = Modifier.weight(1f), fontSize = 16.sp)
        Box {
            OutlinedButton(
                onClick = { expanded = true },
                modifier = Modifier.width(208.dp).height(56.dp), // 120 + 8 + 80
                shape = MaterialTheme.shapes.small
            ) {
                Text(current, fontSize = 14.sp)
            }
            DropdownMenu(
                expanded = expanded, 
                onDismissRequest = { expanded = false },
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            ) {
                options.forEach { option ->
                    DropdownMenuItem(
                        text = { Text(option, fontSize = 16.sp, fontWeight = FontWeight.Normal) },
                        onClick = { onSelect(option); expanded = false },
                        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
                    )
                }
            }
        }
    }
}
