package com.example.pickleballmoispecs.ui

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SwapVert
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
import com.example.pickleballmoispecs.data.EstimationGroup
import java.text.SimpleDateFormat
import java.util.*

@Composable
fun EstimateScreen(viewModel: MOIViewModel) {
    val uiState by viewModel.uiState.collectAsState()
    var showAddDialog by remember { mutableStateOf(value = false) }
    var showSortDialog by remember { mutableStateOf(value = false) }
    var groupToRename by remember { mutableStateOf<EstimationGroup?>(null) }
    
    var selectedIds by remember { mutableStateOf(setOf<Int>()) }
    var isSelectionMode by remember { mutableStateOf(false) }

    BackHandler(isSelectionMode) {
        selectedIds = emptySet()
        isSelectionMode = false
    }

    if ((uiState.selectedEstimationGroupId != null) && (uiState.currentEstimationGroup != null)) {
        EstimateDetailScreen(viewModel, uiState.currentEstimationGroup!!)
    } else {
        Box(modifier = Modifier.fillMaxSize()) {
            Column(modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp, vertical = 0.dp)) {
                Text(
                    text = "Estimations", 
                    fontSize = 28.sp, 
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.fillMaxWidth().padding(top = 12.dp, bottom = 16.dp),
                )

                // Search & Sort Bar
                Row(verticalAlignment = Alignment.CenterVertically) {
                    OutlinedTextField(
                        value = uiState.estimationSearchQuery,
                        onValueChange = { viewModel.setEstimationSearchQuery(it) },
                        modifier = Modifier.weight(1f),
                        placeholder = { Text("Search estimations...") },
                        leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = MaterialTheme.colorScheme.primary) },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedBorderColor = MaterialTheme.colorScheme.primary,
                            focusedBorderColor = MaterialTheme.colorScheme.primary
                        )
                    )
                    
                    IconButton(
                        onClick = { showSortDialog = true },
                        modifier = Modifier.size(56.dp)
                    ) {
                        Icon(
                            Icons.Default.SwapVert, 
                            contentDescription = "Sort",
                            modifier = Modifier.size(38.dp),
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }

                if (isSelectionMode) {
                    Spacer(modifier = Modifier.height(16.dp))
                    val allIds = uiState.estimationGroups.asSequence().map { it.id }.toSet()
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
                            viewModel.deleteEstimationGroups(selectedIds)
                            selectedIds = emptySet()
                            isSelectionMode = false
                        }
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                if (uiState.estimationGroups.isEmpty()) {
                    Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Text("No estimation groups found.", color = Color.Gray)
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.weight(1f),
                        verticalArrangement = Arrangement.spacedBy(2.6.dp),
                        contentPadding = PaddingValues(bottom = 100.dp)
                    ) {
                        items(uiState.estimationGroups, key = { it.id }) { group ->
                            val isSelected = selectedIds.contains(group.id)
                            EstimationGroupItem(
                                group = group,
                                resolution = uiState.moiUnitsResolution,
                                selected = isSelected,
                                onClick = {
                                    if (isSelectionMode) {
                                        selectedIds = if (isSelected) selectedIds - group.id else selectedIds + group.id
                                    } else {
                                        viewModel.selectEstimationGroup(group.id)
                                    }
                                },
                                onLongClick = {
                                    if (!isSelectionMode) {
                                        selectedIds = setOf(group.id)
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
                elevation = FloatingActionButtonDefaults.elevation(0.dp, 0.dp, 0.dp, 0.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Group")
            }
        }
    }

    if (showAddDialog) {
        AddEstimationGroupDialog(
            defaultName = "Estimation ${uiState.estimationGroups.size + 1}",
            onDismiss = { showAddDialog = false }, 
            onConfirm = { 
                viewModel.addEstimationGroup(it)
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
        RenameEstimationDialog(
            currentName = groupToRename!!.name,
            onConfirm = { viewModel.renameEstimationGroup(groupToRename!!, it); groupToRename = null },
            onDismiss = { groupToRename = null }
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun EstimationGroupItem(
    group: EstimationGroup,
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
                .padding(horizontal = 16.dp, vertical = 4.dp)
                .fillMaxWidth()
        ) {
            DynamicTitleText(
                text = group.name, 
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
                    val swStdDev = if (group.type == "Pickleball Paddle") group.resultSW * 0.014 else 0.0
                    val twStdDev = if (group.type == "Pickleball Paddle") group.resultTW * 0.039 else 0.0
                    
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("SW: ", fontSize = 14.sp, color = Color.Gray)
                        val swText = if (swStdDev > 0) "$format ± $format kg·cm²".format(Locale.US, group.resultSW, swStdDev) else "$format kg·cm²".format(Locale.US, group.resultSW)
                        Text(swText, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary, maxLines = 1, softWrap = false)
                    }
                    Spacer(modifier = Modifier.height(2.dp))
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text("TW: ", fontSize = 14.sp, color = Color.Gray)
                        val twText = if (twStdDev > 0) "$format ± $format kg·cm²".format(Locale.US, group.resultTW, twStdDev) else "$format kg·cm²".format(Locale.US, group.resultTW)
                        Text(twText, fontSize = 16.sp, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.secondary, maxLines = 1, softWrap = false)
                    }
                }
                
                Column(horizontalAlignment = Alignment.End) {
                    val stampStyle = TextStyle(fontSize = 11.sp, color = Color.Gray)
                    Text(
                        text = SimpleDateFormat("h:mm a", Locale.US).format(Date(group.timestamp)),
                        style = stampStyle
                    )
                    Text(
                        text = SimpleDateFormat("M/d/yy", Locale.US).format(Date(group.timestamp)),
                        style = stampStyle
                    )
                }
            }
        }
    }
}

@Composable
fun AddEstimationGroupDialog(defaultName: String, onDismiss: () -> Unit, onConfirm: (String) -> Unit) {
    var name by remember { mutableStateOf(defaultName) }
    val maxChars = 40
    
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("New Estimation Group") },
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

@Composable
fun RenameEstimationDialog(currentName: String, onConfirm: (String) -> Unit, onDismiss: () -> Unit) {
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
