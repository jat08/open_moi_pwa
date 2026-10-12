import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';
import '../providers/moi_provider.dart';
import 'components.dart';

class EstimateScreen extends ConsumerStatefulWidget {
  const EstimateScreen({super.key});

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  Set<int> selectedIds = {};
  bool isSelectionMode = false;

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(moiProvider);
    final notifier = ref.read(moiProvider.notifier);
    final theme = Theme.of(context);

    return PopScope(
      canPop: !isSelectionMode,
      onPopInvoked: (didPop) {
        if (isSelectionMode) {
          setState(() {
            selectedIds.clear();
            isSelectionMode = false;
          });
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    'Estimations',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),

                // Search & Sort Bar
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: TextField(
                          onChanged: (query) => notifier.setEstimationSearchQuery(query),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Search estimations...',
                            hintStyle: TextStyle(color: theme.colorScheme.outline, fontSize: 15),
                            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: 22),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.swap_vert, size: 36, color: theme.colorScheme.primary),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => SortDialog(
                            currentType: uiState.sortType,
                            currentDirection: uiState.sortDirection,
                            onApply: (type, dir) => notifier.setSortOrder(type, dir),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                if (isSelectionMode) ...[
                  const SizedBox(height: 8),
                  SelectionTopBar(
                    count: selectedIds.length,
                    isAllSelected: selectedIds.length >= uiState.estimationGroups.length && uiState.estimationGroups.isNotEmpty,
                    onToggleAll: () {
                      setState(() {
                        if (selectedIds.length >= uiState.estimationGroups.length) {
                          selectedIds.clear();
                        } else {
                          selectedIds = uiState.estimationGroups.map((g) => g.id!).toSet();
                        }
                      });
                    },
                    onClear: () {
                      setState(() {
                        selectedIds.clear();
                        isSelectionMode = false;
                      });
                    },
                    onDelete: () {
                      notifier.deleteEstimationGroups(selectedIds);
                      setState(() {
                        selectedIds.clear();
                        isSelectionMode = false;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 6),

                Expanded(
                  child: uiState.estimationGroups.isEmpty
                      ? const Center(child: Text('No estimation groups found.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: uiState.estimationGroups.length,
                          itemBuilder: (context, index) {
                            final group = uiState.estimationGroups[index];
                            final isSelected = selectedIds.contains(group.id);

                            return EstimationGroupCard(
                              group: group,
                              resolution: uiState.moiUnitsResolution,
                              selected: isSelected,
                              onClick: () {
                                if (isSelectionMode) {
                                  setState(() {
                                    if (isSelected) {
                                      selectedIds.remove(group.id);
                                    } else {
                                      selectedIds.add(group.id!);
                                    }
                                  });
                                } else {
                                  notifier.selectEstimationGroup(group.id);
                                }
                              },
                              onLongClick: () {
                                if (!isSelectionMode) {
                                  setState(() {
                                    selectedIds = {group.id!};
                                    isSelectionMode = true;
                                  });
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: theme.colorScheme.primary,
          child: Icon(Icons.add, color: theme.colorScheme.onPrimary, size: 28),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) {
                final controller = TextEditingController(text: 'Estimation ${uiState.estimationGroups.length + 1}');
                return AlertDialog(
                  title: const Text('New Estimation Group'),
                  content: TextField(
                    controller: controller,
                    maxLength: 40,
                    decoration: const InputDecoration(labelText: 'Group Name'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        notifier.addEstimationGroup(controller.text);
                        setState(() {
                          selectedIds.clear();
                          isSelectionMode = false;
                        });
                      },
                      child: const Text('Create'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class EstimationGroupCard extends StatelessWidget {
  final EstimationGroup group;
  final int resolution;
  final bool selected;
  final VoidCallback onClick;
  final VoidCallback onLongClick;

  const EstimationGroupCard({
    super.key,
    required this.group,
    required this.resolution,
    this.selected = false,
    required this.onClick,
    required this.onLongClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swStdDev = group.type == 'Pickleball Paddle' ? group.resultSW * 0.014 : 0.0;
    final twStdDev = group.type == 'Pickleball Paddle' ? group.resultTW * 0.039 : 0.0;

    final swText = swStdDev > 0
        ? '${group.resultSW.toStringAsFixed(resolution)} ± ${swStdDev.toStringAsFixed(resolution)} kg·cm²'
        : '${group.resultSW.toStringAsFixed(resolution)} kg·cm²';

    final twText = twStdDev > 0
        ? '${group.resultTW.toStringAsFixed(resolution)} ± ${twStdDev.toStringAsFixed(resolution)} kg·cm²'
        : '${group.resultTW.toStringAsFixed(resolution)} kg·cm²';

    final timeStr = DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(group.timestamp));
    final dateStr = DateFormat('M/d/yy').format(DateTime.fromMillisecondsSinceEpoch(group.timestamp));

    return Card(
      elevation: 0,
      color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: selected ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 1.0),
      child: InkWell(
        onTap: onClick,
        onLongPress: onLongClick,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DynamicTitleText(
                text: group.name,
                maxFontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'SW: ',
                              style: TextStyle(fontSize: 13, color: theme.colorScheme.outline, height: 1.1),
                            ),
                            TextSpan(
                              text: swText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'TW: ',
                              style: TextStyle(fontSize: 13, color: theme.colorScheme.outline, height: 1.1),
                            ),
                            TextSpan(
                              text: twText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(fontSize: 10.5, color: theme.colorScheme.outline, height: 1.1),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 10.5, color: theme.colorScheme.outline, height: 1.1),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
