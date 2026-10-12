package com.example.pickleballmoispecs.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle

import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.pickleballmoispecs.data.MeasurementGroup
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun MeasureScreen(viewModel: MOIViewModel) {
    val uiState by viewModel.uiState.collectAsState()
    var showAddDialog by remember { mutableStateOf(value = false) }
    var showSortDialog by remember { mutableStateOf(value = false) }
    var groupToRename by remember { mutableStateOf<MeasurementGroup?>(null) }
    
    var selectedIds by remember { mutableStateOf(setOf<Int>()) }
    var isSelectionMode by remember { mutableStateOf(false) }

    BackHandler(isSelectionMode) {
        selectedIds = emptySet()
        isSelectionMode = false
    }

    if ((uiState.editingAttributesGroupId != null) && (uiState.currentAttributeGroup != null)) {
        GroupAttributesScreen(viewModel, uiState.currentAttributeGroup!!)
    } else if (uiState.selectedMeasurement != null) {
        MeasurementDetailScreen(viewModel, uiState.selectedMeasurement!!)
    } else if (uiState.selectedGroupId != null) {
        GroupDetailScreen(viewModel, uiState.selectedGroupId!!)
    } else {
        Box(modifier = Modifier.fillMaxSize()) {
            Column(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 0.dp)) {
                // Header aligned with top bar feel
                Text(
                    text = "Measurements", 
                    fontSize = 28.sp, 
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.fillMaxWidth().padding(top = 12.dp, bottom = 16.dp),
                )

                // Search & Sort Bar
                Row(verticalAlignment = Alignment.CenterVertically) {
                    OutlinedTextField(
                        value = uiState.searchQuery,
                        onValueChange = { viewModel.setSearchQuery(it) },
                        modifier = Modifier.weight(1f),
                        placeholder = { Text("Search groups...") },
                        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = MaterialTheme.colorScheme.primary) },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedBorderColor = MaterialTheme.colorScheme.primary,
                            focusedBorderColor = MaterialTheme.colorScheme.primary
                        )
                    )
                    
                    IconButton(
                        onClick = { showSortDialog = true },
                        modifier = Modifier.size(56.dp) // Adjusted size
                    ) {
                        Icon(
                            Icons.Default.SwapVert, 
                            contentDescription = "Sort",
                            modifier = Modifier.size(38.dp), // 1/5 smaller than 48dp
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }

                if (isSelectionMode) {
                    Spacer(modifier = Modifier.height(16.dp))
                    val allIds = uiState.groups.asSequence().map { it.group.id }.toSet()
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
                            viewModel.deleteGroups(selectedIds)
                            selectedIds = emptySet()
                            isSelectionMode = false
                        }
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                if (uiState.groups.isEmpty()) {
                    Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text("No groups found.", color = Color.Gray)
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(2.6.dp),
                        contentPadding = PaddingValues(bottom = 100.dp) // More space for moved FAB
                    ) {
                        items(uiState.groups, key = { it.group.id }) { summary ->
                            val isSelected = selectedIds.contains(summary.group.id)
                            GroupItem(
                                summary = summary,
                                resolution = uiState.moiUnitsResolution,
                                selected = isSelected,
                                onClick = {
                                    if (isSelectionMode) {
                                        selectedIds = if (isSelected) {
                                            selectedIds - summary.group.id
                                        } else {
                                            selectedIds + summary.group.id
                                        }
                                    } else {
                                        viewModel.selectGroup(summary.group.id)
                                    }
                                },
                                onLongClick = {
                                    if (!isSelectionMode) {
                                        selectedIds = setOf(summary.group.id)
                                        isSelectionMode = true
                                    }
                                }
                            )
                        }
                    }
                }
            }
            
            FloatingActionButton(
                onClick = { showAddDialog = true },
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .padding(bottom = 32.dp, end = 24.dp), 
                containerColor = MaterialTheme.colorScheme.primary,
                elevation = FloatingActionButtonDefaults.elevation(0.dp, 0.dp, 0.dp, 0.dp) // No shadow
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Group")
            }
        }
    }

    if (showAddDialog) {
        AddGroupDialog(
            defaultName = "Group ${uiState.groups.size + 1}",
            onDismiss = { showAddDialog = false }, 
            onConfirm = { 
                viewModel.addGroup(it)
                selectedIds = emptySet()
            }
        )
    }

    if (showSortDialog) {
        SortDialog(
            currentType = uiState.sortType,
            currentDirection = uiState.sortDirection,
            onApply = { type, dir -> viewModel.setSortOrder(type, dir) },
            onDismiss = { showSortDialog = false }
        )
    }

    if (groupToRename != null) {
        RenameDialog(
            currentName = groupToRename!!.name,
            onConfirm = { viewModel.renameGroup(groupToRename!!, it); groupToRename = null },
            onDismiss = { groupToRename = null }
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun GroupItem(
    summary: MOIViewModel.GroupSummary, 
    resolution: Int,
    selected: Boolean = false,
    onClick: () -> Unit, 
    onLongClick: () -> Unit = {}
) {
    val format = when (resolution) {
        0 -> "%.0f"
        1 -> "%.1f"
        2 -> "%.2f"
        3 -> "%.3f"
        4 -> "%.4f"
        else -> "%.1f"
    }

    Card(
        modifier = Modifier
            .fillMaxWidth()
            .combinedClickable(
                onClick = onClick,
                onLongClick = onLongClick
            ),
        colors = CardDefaults.cardColors(
            containerColor = if (selected) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant
        ),
        border = if (selected) BorderStroke(2.dp, MaterialTheme.colorScheme.primary) else null
    ) {
        Column(
            modifier = Modifier
                .padding(horizontal = 16.dp, vertical = 2.dp)
                .fillMaxWidth()
        ) {
            DynamicTitleText(
                text = summary.group.name, 
                maxFontSize = 20.sp,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.fillMaxWidth()
            )
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Bottom
            ) {
                Column(
                    verticalArrangement = Arrangement.spacedBy((-4).dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("SW: ", fontSize = 14.sp, color = Color.Gray)
                        Text("$format ± $format kg·cm²".format(Locale.US, summary.avgSW, summary.stdDevSW), fontSize = 16.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary, maxLines = 1, softWrap = false)
                    }
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("TW: ", fontSize = 14.sp, color = Color.Gray)
                        Text("$format ± $format kg·cm²".format(Locale.US, summary.avgTW, summary.stdDevTW), fontSize = 16.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.secondary, maxLines = 1, softWrap = false)
                    }
                }

                Column(
                    horizontalAlignment = Alignment.End, 
                    verticalArrangement = Arrangement.spacedBy((-4).dp)
                ) {
                    Text(
                        text = "Readings: ${summary.count}", 
                        fontSize = 12.sp, 
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.outline
                    )
                    val stampStyle = TextStyle(fontSize = 11.sp, color = Color.Gray)
                    Text(
                        text = SimpleDateFormat("h:mm a", Locale.US).format(Date(summary.group.timestamp)),
                        style = stampStyle
                    )
                    Text(
                        text = SimpleDateFormat("M/d/yy", Locale.US).format(Date(summary.group.timestamp)),
                        style = stampStyle
                    )
                }
            }
        }
    }
}

@Composable
fun AddGroupDialog(defaultName: String, onDismiss: () -> Unit, onConfirm: (String) -> Unit) {
    var name by remember { mutableStateOf(defaultName) }
    val maxChars = 40
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("New Measurement Group") },
        text = {
            Column {
                OutlinedTextField(
                    value = name,
                    onValueChange = { 
                        if (it.length <= maxChars) name = it 
                    },
                    label = { Text("Group Name") },
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
            Button(onClick = { onConfirm(name); onDismiss() }) { Text("Create") }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) { Text("Cancel") }
        }
    )
}
