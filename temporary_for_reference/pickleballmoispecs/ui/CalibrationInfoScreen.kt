package com.example.pickleballmoispecs.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun CalibrationInfoScreen(viewModel: MOIViewModel, target: MOIViewModel.CalibrationTarget) {
    val uiState by viewModel.uiState.collectAsState()
    
    val targetName = when (target) {
        MOIViewModel.CalibrationTarget.OBJECT_A -> "Object A"
        MOIViewModel.CalibrationTarget.OBJECT_B -> "Object B"
        MOIViewModel.CalibrationTarget.TARE_PB -> "Pickleball Adapter"
        MOIViewModel.CalibrationTarget.TARE_TW -> "Twist Weight Adapter"
        else -> ""
    }

    val isPeriod = (target == MOIViewModel.CalibrationTarget.OBJECT_A) || (target == MOIViewModel.CalibrationTarget.OBJECT_B)
    val label = if (isPeriod) "Expected Period (s)" else "Expected MOI (kg·cm²)"
    
    val initialValue = when (target) {
        MOIViewModel.CalibrationTarget.OBJECT_A -> uiState.expectedPeriodA
        MOIViewModel.CalibrationTarget.OBJECT_B -> uiState.expectedPeriodB
        MOIViewModel.CalibrationTarget.TARE_PB -> uiState.expectedMoiPB
        MOIViewModel.CalibrationTarget.TARE_TW -> uiState.expectedMoiTW
        else -> 0.0
    }

    var valueStr by remember(target) { mutableStateOf(initialValue.toString()) }

    BackHandler {
        viewModel.selectEditingExpectedValue(null)
    }

    Column(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 0.dp).imePadding()) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.fillMaxWidth().padding(top = 4.dp, bottom = 16.dp),
        ) {
            IconButton(
                onClick = { viewModel.selectEditingExpectedValue(null) },
                modifier = Modifier.offset(x = (-12).dp)
            ) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
            }
            DynamicTitleText(
                text = "Info: $targetName",
                maxFontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                modifier = Modifier.weight(1f)
            )
        }

        Column(modifier = Modifier.weight(1f).verticalScroll(rememberScrollState())) {
            OutlinedTextField(
                value = valueStr,
                onValueChange = { valueStr = it },
                label = { Text(label) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    valueStr.toDoubleOrNull()?.let {
                        viewModel.updateExpectedValue(target, it)
                    }
                },
                modifier = Modifier.fillMaxWidth().height(56.dp)
            ) {
                Text("Save Expected Value", fontWeight = FontWeight.Bold, fontSize = 18.sp)
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}
