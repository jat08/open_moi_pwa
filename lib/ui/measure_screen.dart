import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/page_typography.dart';
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

  void _showNewGroupDialog(BuildContext context, UiState uiState, MoiNotifier notifier) {
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
                        'Measurements',
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

                SizedBox(
                  height: 48,
                  child: isSelectionMode
                      ? SelectionTopBar(
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
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: TextField(
                                  onChanged: (query) => notifier.setSearchQuery(query),
                                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'Search groups...',
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
                              width: 48,
                              height: 48,
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
                ),

                const SizedBox(height: 8),

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
    final isDark = theme.brightness == Brightness.dark;
    final typo = PageTypography.of(context);

    final swStr = summary.count == 0 || summary.avgSW <= 0
        ? 'No Data'
        : summary.avgSW.toStringAsFixed(resolution);
    final twStr = summary.count == 0 || summary.avgTW <= 0
        ? 'No Data'
        : summary.avgTW.toStringAsFixed(resolution);

    final fullSwStr = 'SW: $swStr';
    final fullTwStr = 'TW: $twStr';

    final dateStr = DateFormat('M/d/yy    •    h:mm a').format(DateTime.fromMillisecondsSinceEpoch(summary.group.timestamp));
    final metaStr = '${summary.count} readings    •    $dateStr';

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
                          text: summary.group.name,
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
                              Text('SW: ', style: TextStyle(fontSize: valueFontSize * 0.88, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                              Expanded(
                                child: Text(
                                  swStr,
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
                              Text('TW: ', style: TextStyle(fontSize: valueFontSize * 0.88, fontWeight: FontWeight.bold, color: theme.colorScheme.secondary)),
                              Expanded(
                                child: Text(
                                  twStr,
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
