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

  void _showNewGroupBottomSheet(BuildContext context, UiState uiState, MoiNotifier notifier) {
    HapticFeedback.lightImpact();
    final controller = TextEditingController(text: 'Group ${uiState.groups.length + 1}');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const OneUiDragHandle(),
                const SizedBox(height: 4),
                const Text('New Measurement Group', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  maxLength: 40,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Group Name'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          ),
                          onPressed: () async {
                            final text = controller.text.trim();
                            if (text.isNotEmpty) {
                              HapticFeedback.lightImpact();
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.of(ctx).pop();
                              try {
                                await notifier.addGroup(text);
                                if (mounted) {
                                  setState(() {
                                    selectedIds.clear();
                                    isSelectionMode = false;
                                  });
                                }
                              } catch (e) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Error creating group: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
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
          final shouldExit = await showModalBottomSheet<bool>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) {
              final isDark = theme.brightness == Brightness.dark;
              final sheetBg = isDark ? const Color(0xFF242C35) : const Color(0xFFEFF6FF);
              return Container(
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const OneUiDragHandle(),
                      const SizedBox(height: 4),
                      const Text('Exit OpenMOI?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text('Are you sure you want to exit the app?', style: TextStyle(fontSize: 15)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                ),
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('No'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Yes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        floatingActionButton: !isSelectionMode
            ? FloatingActionButton.extended(
                elevation: 3,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                icon: const Icon(Icons.add, size: 22),
                label: const Text('New Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () => _showNewGroupBottomSheet(context, uiState, notifier),
              )
            : null,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
                  title: Text(
                    'Measurements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: isSelectionMode
                      ? SelectionTopBar(
                          count: selectedIds.length,
                          isAllSelected: selectedIds.length >= uiState.groups.length && uiState.groups.isNotEmpty,
                          isPartialSelected: selectedIds.isNotEmpty && selectedIds.length < uiState.groups.length,
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
                                height: kMultipurposeBarHeight,
                                child: TextField(
                                  onChanged: (query) => notifier.setSearchQuery(query),
                                  style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'Search groups...',
                                    hintStyle: TextStyle(color: theme.colorScheme.outline, fontSize: 15),
                                    prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary, size: 22),
                                    filled: true,
                                    fillColor: theme.colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(kMultipurposeBarRadius),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(kMultipurposeBarRadius),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(kMultipurposeBarRadius),
                                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: kMultipurposeBarHeight,
                              height: kMultipurposeBarHeight,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(kMultipurposeBarRadius),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: Icon(Icons.swap_vert, size: 24, color: theme.colorScheme.primary),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    backgroundColor: Colors.transparent,
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
              ),

              if (uiState.groups.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text('No groups found.', style: TextStyle(color: Colors.grey, fontSize: 15)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final summary = uiState.groups[index];
                        final isSelected = selectedIds.contains(summary.group.id);

                        return Dismissible(
                          key: ValueKey<int>(summary.group.id!),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 3.5),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const [
                                Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                SizedBox(width: 6),
                                Icon(Icons.delete, color: Colors.white, size: 22),
                              ],
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            HapticFeedback.mediumImpact();
                            bool confirmed = false;
                            await showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) => DeleteConfirmationDialog(
                                title: 'Delete Group?',
                                text: 'Are you sure you want to delete "${summary.group.name}" and all its measurements?',
                                onConfirm: () => confirmed = true,
                              ),
                            );
                            return confirmed;
                          },
                          onDismissed: (direction) {
                            notifier.deleteGroups({summary.group.id!});
                          },
                          child: GroupItemCard(
                            summary: summary,
                            resolution: uiState.moiUnitsResolution,
                            selected: isSelected,
                            onClick: () {
                              if (isSelectionMode) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (isSelected) {
                                    selectedIds.remove(summary.group.id);
                                  } else {
                                    selectedIds.add(summary.group.id!);
                                  }
                                });
                              } else {
                                HapticFeedback.lightImpact();
                                notifier.selectGroup(summary.group.id);
                              }
                            },
                            onLongClick: () {
                              HapticFeedback.mediumImpact();
                              if (!isSelectionMode) {
                                setState(() {
                                  selectedIds = {summary.group.id!};
                                  isSelectionMode = true;
                                });
                              }
                            },
                          ),
                        );
                      },
                      childCount: uiState.groups.length,
                    ),
                  ),
                ),
            ],
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
          color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: selected ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
          ),
          margin: const EdgeInsets.symmetric(vertical: 3.5),
          child: InkWell(
            onTap: onClick,
            onLongPress: onLongClick,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: swBg,
                            borderRadius: BorderRadius.circular(14),
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
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: twBg,
                            borderRadius: BorderRadius.circular(14),
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
                  const SizedBox(height: 5),
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
