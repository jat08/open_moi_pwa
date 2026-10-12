import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';
import '../providers/moi_provider.dart';
import 'components.dart';

class MeasureScreen extends ConsumerStatefulWidget {
  const MeasureScreen({super.key});

  @override
  ConsumerState<MeasureScreen> createState() => _MeasureScreenState();
}

class _MeasureScreenState extends ConsumerState<MeasureScreen> {
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
                    'Measurements',
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
                          onChanged: (query) => notifier.setSearchQuery(query),
                          style: TextStyle(color: theme.colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Search groups...',
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
                    isAllSelected: selectedIds.length >= uiState.groups.length && uiState.groups.isNotEmpty,
                    onToggleAll: () {
                      setState(() {
                        if (selectedIds.length >= uiState.groups.length) {
                          selectedIds.clear();
                        } else {
                          selectedIds = uiState.groups.map((g) => g.group.id!).toSet();
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
                      notifier.deleteGroups(selectedIds);
                      setState(() {
                        selectedIds.clear();
                        isSelectionMode = false;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 6),

                Expanded(
                  child: uiState.groups.isEmpty
                      ? const Center(child: Text('No groups found.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: uiState.groups.length,
                          itemBuilder: (context, index) {
                            final summary = uiState.groups[index];
                            final isSelected = selectedIds.contains(summary.group.id);

                            return GroupItemCard(
                              summary: summary,
                              resolution: uiState.moiUnitsResolution,
                              selected: isSelected,
                              onClick: () {
                                if (isSelectionMode) {
                                  setState(() {
                                    if (isSelected) {
                                      selectedIds.remove(summary.group.id);
                                    } else {
                                      selectedIds.add(summary.group.id!);
                                    }
                                  });
                                } else {
                                  notifier.selectGroup(summary.group.id);
                                }
                              },
                              onLongClick: () {
                                if (!isSelectionMode) {
                                  setState(() {
                                    selectedIds = {summary.group.id!};
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
                final controller = TextEditingController(text: 'Group ${uiState.groups.length + 1}');
                return AlertDialog(
                  title: const Text('New Measurement Group'),
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
                        notifier.addGroup(controller.text);
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

class GroupItemCard extends StatelessWidget {
  final GroupSummary summary;
  final int resolution;
  final bool selected;
  final VoidCallback onClick;
  final VoidCallback onLongClick;

  const GroupItemCard({
    super.key,
    required this.summary,
    required this.resolution,
    this.selected = false,
    required this.onClick,
    required this.onLongClick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swStr = '${summary.avgSW.toStringAsFixed(resolution)} ± ${summary.stdDevSW.toStringAsFixed(resolution)} kg·cm²';
    final twStr = '${summary.avgTW.toStringAsFixed(resolution)} ± ${summary.stdDevTW.toStringAsFixed(resolution)} kg·cm²';

    final timeStr = DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(summary.group.timestamp));
    final dateStr = DateFormat('M/d/yy').format(DateTime.fromMillisecondsSinceEpoch(summary.group.timestamp));

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
                text: summary.group.name,
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
                              text: swStr,
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
                              text: twStr,
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
                        'Readings: ${summary.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.outline,
                          height: 1.0,
                        ),
                      ),
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
