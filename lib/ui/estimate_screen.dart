import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/page_typography.dart';
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

  void _showNewGroupDialog(BuildContext context, UiState uiState, MoiNotifier notifier) {
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
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(moiProvider);
    final notifier = ref.read(moiProvider.notifier);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (isSelectionMode) {
          setState(() {
            selectedIds.clear();
            isSelectionMode = false;
          });
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Exit OpenMOI?'),
              content: const Text('Are you sure you want to exit the app?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('No'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
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
                  child: Row(
                    children: [
                      Text(
                        'Estimations',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                          icon: const Icon(Icons.add, size: 22),
                          label: const Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          onPressed: () => _showNewGroupDialog(context, uiState, notifier),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isSelectionMode)
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
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: TextField(
                            onChanged: (query) => notifier.setEstimationSearchQuery(query),
                            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Search estimations...',
                              hintStyle: TextStyle(color: theme.colorScheme.outline, fontSize: 15),
                              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: 22),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceVariant,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.swap_vert, size: 24, color: theme.colorScheme.primary),
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
                      ),
                    ],
                  ),

                const SizedBox(height: 8),

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
    final isDark = theme.brightness == Brightness.dark;
    final typo = PageTypography.of(context);

    final swText = group.resultSW <= 0
        ? 'No Data'
        : group.resultSW.toStringAsFixed(resolution);

    final twText = group.resultTW <= 0
        ? 'No Data'
        : group.resultTW.toStringAsFixed(resolution);

    final fullSwStr = 'EST. SW: $swText';
    final fullTwStr = 'EST. TW: $twText';

    final dateStr = DateFormat('M/d/yy    •    h:mm a').format(DateTime.fromMillisecondsSinceEpoch(group.timestamp));
    final metaStr = '${group.type}    •    $dateStr';

    final swBg = isDark ? const Color(0xFF172836) : const Color(0xFFE8F4FD);
    final twBg = isDark ? const Color(0xFF0F2E2B) : const Color(0xFFE0F2F1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = (constraints.maxWidth - 28) / 2.0;
        final valueFontSize = typo.computeUnifiedSize(
          texts: [fullSwStr, fullTwStr],
          maxFontSize: 18.0,
          maxWidth: halfWidth,
          fontWeight: FontWeight.bold,
        );

        return Card(
          elevation: 0,
          color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: selected ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
          ),
          margin: const EdgeInsets.symmetric(vertical: 2.5),
          child: InkWell(
            onTap: onClick,
            onLongPress: onLongClick,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DynamicTitleText(
                          text: group.name,
                          maxFontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 24,
                        color: theme.colorScheme.outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: swBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text('EST. SW: ', style: TextStyle(fontSize: valueFontSize * 0.88, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                              Expanded(
                                child: Text(
                                  swText,
                                  style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: twBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Text('EST. TW: ', style: TextStyle(fontSize: valueFontSize * 0.88, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                              Expanded(
                                child: Text(
                                  twText,
                                  style: TextStyle(fontSize: valueFontSize, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  metaStr,
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.outline, height: 1.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}
