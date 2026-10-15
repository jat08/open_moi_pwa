import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../providers/moi_provider.dart';
import 'components.dart';

class EstimateDetailScreen extends ConsumerStatefulWidget {
  final EstimationGroup group;

  const EstimateDetailScreen({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<EstimateDetailScreen> createState() => _EstimateDetailScreenState();
}

class _EstimateDetailScreenState extends ConsumerState<EstimateDetailScreen> {
  late String m;
  late String mUnit;
  late String l;
  late String lUnit;
  late String w;
  late String wUnit;
  late String bp;
  late String bpUnit;
  late String r;
  late String rUnit;
  late String type;

  @override
  void initState() {
    super.initState();
    final g = widget.group;
    m = g.mass > 0 ? g.mass.toString() : '';
    mUnit = g.massUnit;
    l = g.length > 0 ? g.length.toString() : '';
    lUnit = g.lengthUnit;
    w = g.width > 0 ? g.width.toString() : '';
    wUnit = g.widthUnit;
    bp = g.balancePoint > 0 ? g.balancePoint.toString() : '';
    bpUnit = g.bpUnit;
    r = g.radius > 0 ? g.radius.toString() : '';
    rUnit = g.radiusUnit;
    type = g.type;
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(moiProvider);
    final notifier = ref.read(moiProvider.notifier);
    final theme = Theme.of(context);
    final group = widget.group;

    final swStdDev = group.type == 'Pickleball Paddle' ? group.resultSW * 0.014 : 0.0;
    final twStdDev = group.type == 'Pickleball Paddle' ? group.resultTW * 0.039 : 0.0;

    final isRadiusLocked = type == 'Pickleball Paddle' || type == 'Racquet';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        notifier.selectEstimationGroup(null);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface, size: 28),
                      onPressed: () => notifier.selectEstimationGroup(null),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => RenameDialog(
                              currentName: group.name,
                              onConfirm: (newName) => notifier.renameEstimationGroup(group, newName),
                            ),
                          );
                        },
                        child: DynamicTitleText(
                          text: group.name,
                          maxFontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                SingleSummaryHeader(
                  label: 'SW',
                  avg: group.resultSW,
                  stdDev: swStdDev,
                  moiResolution: uiState.moiUnitsResolution,
                  label2: 'TW',
                  avg2: group.resultTW,
                  stdDev2: twStdDev,
                  showTolerance: swStdDev > 0 || twStdDev > 0,
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Paddle / Racquet Geometry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(height: 6),

                        Card(
                          color: theme.colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              children: [
                                EstimationInputField(
                                  label: 'Weight',
                                  value: m,
                                  unit: mUnit,
                                  units: const ['oz', 'lb', 'kg'],
                                  onValueChange: (v) => setState(() => m = v),
                                  onUnitChange: (u) => setState(() => mUnit = u),
                                ),
                                Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                                EstimationInputField(
                                  label: 'Length',
                                  value: l,
                                  unit: lUnit,
                                  units: const ['in', 'cm'],
                                  onValueChange: (v) => setState(() => l = v),
                                  onUnitChange: (u) => setState(() => lUnit = u),
                                ),
                                Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                                EstimationInputField(
                                  label: 'Width',
                                  value: w,
                                  unit: wUnit,
                                  units: const ['in', 'cm'],
                                  onValueChange: (v) => setState(() => w = v),
                                  onUnitChange: (u) => setState(() => wUnit = u),
                                ),
                                Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                                EstimationInputField(
                                  label: 'Balance Point',
                                  value: bp,
                                  unit: bpUnit,
                                  units: const ['in', 'cm'],
                                  onValueChange: (v) => setState(() => bp = v),
                                  onUnitChange: (u) => setState(() => bpUnit = u),
                                ),
                                Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                                EstimationInputField(
                                  label: 'Radius',
                                  value: r,
                                  unit: rUnit,
                                  units: const ['in', 'cm'],
                                  onValueChange: (v) => setState(() => r = v),
                                  onUnitChange: (u) => setState(() => rUnit = u),
                                  locked: isRadiusLocked,
                                ),
                                Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                                TypeSelector(
                                  label: 'Type',
                                  current: type,
                                  options: const ['MOI-5', 'MOI-10', 'Pickleball Paddle', 'Racquet'],
                                  onSelect: (t) => setState(() => type = t),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final mVal = double.tryParse(m) ?? 0.0;
                              final lVal = double.tryParse(l) ?? 0.0;
                              final wVal = double.tryParse(w) ?? 0.0;
                              final bpVal = double.tryParse(bp) ?? 0.0;
                              final rVal = double.tryParse(r) ?? 0.0;

                              notifier.calculateAndSaveEstimation(
                                group,
                                mVal,
                                mUnit,
                                lVal,
                                lUnit,
                                wVal,
                                wUnit,
                                bpVal,
                                bpUnit,
                                rVal,
                                rUnit,
                                type,
                              );
                            },
                            child: const Text('Calculate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
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
