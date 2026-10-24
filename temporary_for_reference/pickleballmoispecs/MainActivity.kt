package com.example.pickleballmoispecs

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent

import android.nfc.NdefMessage
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.tech.Ndef
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Functions
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.example.pickleballmoispecs.ui.*
import com.example.pickleballmoispecs.ui.theme.OpenMOITheme
import androidx.activity.viewModels

class MainActivity : ComponentActivity() {
    private val viewModel: MOIViewModel by viewModels()
    private var nfcAdapter: NfcAdapter? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        
        // Observe scanning state to enable/disable foreground dispatch
        lifecycleScope.launch {
            viewModel.uiState
                .map { it.isNfcScanning }
                .distinctUntilChanged()
                .collect { scanning ->
                    if (scanning) {
                        if (nfcAdapter?.isEnabled == true) {
                            enableNfcForegroundDispatch()
                        } else {
                            viewModel.setNfcDisabledError()
                        }
                    } else {
                        nfcAdapter?.disableForegroundDispatch(this@MainActivity)
                    }
                }
        }

        enableEdgeToEdge()
        setContent {
            val uiState by viewModel.uiState.collectAsState()
            val context = LocalContext.current
            var showExitDialog by remember { mutableStateOf(value = false) }

            LaunchedEffect(uiState.keepScreenOn) {
                if (uiState.keepScreenOn) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
            }
            
            OpenMOITheme(themeMode = uiState.themeMode) {
                val navController = rememberNavController()

                val showBottomBar = (uiState.selectedGroupId == null) && 
                                   (uiState.selectedCalibrationTarget == null) &&
                                   (uiState.selectedEstimationGroupId == null) &&
                                   (uiState.selectedMeasurement == null) &&
                                   (uiState.editingAttributesGroupId == null)
                
                BackHandler(enabled = showBottomBar) {
                    showExitDialog = true
                }

                if (showExitDialog) {
                    AlertDialog(
                        onDismissRequest = { showExitDialog = false },
                        title = { Text("Exit App?") },
                        text = { Text("Are you sure you want to exit the application?") },
                        confirmButton = {
                            Button(onClick = { (context as? Activity)?.finish() }) {
                                Text("Yes")
                            }
                        },
                        dismissButton = {
                            TextButton(onClick = { showExitDialog = false }) {
                                Text("No")
                            }
                        }
                    )
                }
                
                Scaffold(
                    bottomBar = {
                        if (showBottomBar) {
                            NavigationBar(
                                modifier = Modifier.height(112.dp),
                                containerColor = MaterialTheme.colorScheme.surfaceVariant,
                                contentColor = MaterialTheme.colorScheme.onSurfaceVariant,
                            ) {
                                val navBackStackEntry by navController.currentBackStackEntryAsState()
                                val currentDestination = navBackStackEntry?.destination
                                
                                NavigationBarItem(
                                    icon = { 
                                        Icon(
                                            Icons.Default.Timer, 
                                            contentDescription = null,
                                            modifier = Modifier.size(32.dp)
                                        ) 
                                    },
                                    label = { Text("Measure") },
                                    selected = currentDestination?.hierarchy?.any { it.route == "measure" } == true,
                                    colors = NavigationBarItemDefaults.colors(
                                        selectedIconColor = MaterialTheme.colorScheme.primary,
                                        selectedTextColor = MaterialTheme.colorScheme.primary,
                                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                                        unselectedIconColor = MaterialTheme.colorScheme.outline,
                                        unselectedTextColor = MaterialTheme.colorScheme.outline
                                    ),
                                    onClick = {
                                        navController.navigate("measure") {
                                            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                            launchSingleTop = true
                                            restoreState = true
                                        }
                                    }
                                )
                                NavigationBarItem(
                                    icon = { 
                                        Icon(
                                            Icons.Default.Functions, 
                                            contentDescription = null,
                                            modifier = Modifier.size(32.dp)
                                        ) 
                                    },
                                    label = { Text("Estimate") },
                                    selected = currentDestination?.hierarchy?.any { it.route == "estimate" } == true,
                                    colors = NavigationBarItemDefaults.colors(
                                        selectedIconColor = MaterialTheme.colorScheme.primary,
                                        selectedTextColor = MaterialTheme.colorScheme.primary,
                                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                                        unselectedIconColor = MaterialTheme.colorScheme.outline,
                                        unselectedTextColor = MaterialTheme.colorScheme.outline
                                    ),
                                    onClick = {
                                        navController.navigate("estimate") {
                                            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                            launchSingleTop = true
                                            restoreState = true
                                        }
                                    }
                                )
                                NavigationBarItem(
                                    icon = { 
                                        Icon(
                                            Icons.Default.Tune,
                                            contentDescription = null,
                                            modifier = Modifier.size(32.dp)
                                        ) 
                                    },
                                    label = { Text("Calibrate") },
                                    selected = currentDestination?.hierarchy?.any { it.route == "calibrate" } == true,
                                    colors = NavigationBarItemDefaults.colors(
                                        selectedIconColor = MaterialTheme.colorScheme.primary,
                                        selectedTextColor = MaterialTheme.colorScheme.primary,
                                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                                        unselectedIconColor = MaterialTheme.colorScheme.outline,
                                        unselectedTextColor = MaterialTheme.colorScheme.outline
                                    ),
                                    onClick = {
                                        navController.navigate("calibrate") {
                                            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                            launchSingleTop = true
                                            restoreState = true
                                        }
                                    }
                                )
                                NavigationBarItem(
                                    icon = { 
                                        Icon(
                                            Icons.Default.Settings, 
                                            contentDescription = null,
                                            modifier = Modifier.size(32.dp)
                                        ) 
                                    },
                                    label = { Text("Settings") },
                                    selected = currentDestination?.hierarchy?.any { it.route == "settings" } == true,
                                    colors = NavigationBarItemDefaults.colors(
                                        selectedIconColor = MaterialTheme.colorScheme.primary,
                                        selectedTextColor = MaterialTheme.colorScheme.primary,
                                        indicatorColor = MaterialTheme.colorScheme.primaryContainer,
                                        unselectedIconColor = MaterialTheme.colorScheme.outline,
                                        unselectedTextColor = MaterialTheme.colorScheme.outline
                                    ),
                                    onClick = {
                                        navController.navigate("settings") {
                                            popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                            launchSingleTop = true
                                            restoreState = true
                                        }
                                    }
                                )
                            }
                        }
                    }
                ) { innerPadding ->
                    NavHost(navController, startDestination = "measure", Modifier.padding(innerPadding)) {
                        composable("measure") { MeasureScreen(viewModel) }
                        composable("calibrate") { CalibrationScreen(viewModel) }
                        composable("estimate") { EstimateScreen(viewModel) }
                        composable("settings") { SettingsScreen(viewModel) }
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = intent.action
        if (NfcAdapter.ACTION_NDEF_DISCOVERED == action ||
            NfcAdapter.ACTION_TECH_DISCOVERED == action ||
            NfcAdapter.ACTION_TAG_DISCOVERED == action) {
            
            val records = mutableListOf<String>()
            
            // 1. Try to get NDEF messages from Intent Extras
            val rawMsgs = intent.getParcelableArrayExtra(NfcAdapter.EXTRA_NDEF_MESSAGES)
            if (rawMsgs != null) {
                val messages = rawMsgs.map { it as NdefMessage }
                for (message in messages) {
                    for (record in message.records) {
                        parseTextRecord(record)?.let { records.add(it) }
                    }
                }
            } else {
                // 2. Fallback: Try to read NDEF data directly from the Tag object
                val tag: Tag? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(NfcAdapter.EXTRA_TAG, Tag::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra(NfcAdapter.EXTRA_TAG)
                }
                
                tag?.let { t ->
                    val ndef = Ndef.get(t)
                    try {
                        ndef?.connect()
                        ndef?.ndefMessage?.records?.forEach { record ->
                            parseTextRecord(record)?.let { records.add(it) }
                        }
                    } catch (_: Exception) {
                    } finally {
                        try { ndef?.close() } catch (_: Exception) {}
                    }
                }
            }

            if (records.isNotEmpty()) {
                viewModel.processNfcMessage(records)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        val uiState = viewModel.uiState.value
        if (uiState.isNfcScanning) {
            enableNfcForegroundDispatch()
        }
        
        // Auto-dismiss disabled dialog if enabled now
        if (!uiState.nfcEnabled && nfcAdapter?.isEnabled == true) {
            viewModel.setNfcScanning(false)
        }
    }

    override fun onPause() {
        super.onPause()
        nfcAdapter?.disableForegroundDispatch(this)
    }

    private fun enableNfcForegroundDispatch() {
        nfcAdapter?.let { adapter ->
            val intent = Intent(this, javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(this, 0, intent, flags)
            adapter.enableForegroundDispatch(this, pendingIntent, null, null)
        }
    }

    private fun parseTextRecord(record: android.nfc.NdefRecord): String? {
        val payload = record.payload
        if (payload.isEmpty()) return null
        
        // Standard NDEF Text record handling
        val textEncoding = if ((payload[0].toInt() and 128) == 0) "UTF-8" else "UTF-16"
        val languageCodeLength = payload[0].toInt() and 63
        return try {
            String(
                payload,
                languageCodeLength + 1,
                payload.size - languageCodeLength - 1,
                charset(textEncoding)
            )
        } catch (_: Exception) {
            // Fallback for simple payloads
            String(payload)
        }
    }
}
