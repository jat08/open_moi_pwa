import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../providers/moi_provider.dart';
import 'components.dart';

class GroupAttributesScreen extends ConsumerStatefulWidget {
  final MeasurementGroup group;

  const GroupAttributesScreen({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupAttributesScreen> createState() => _GroupAttributesScreenState();
}

class _GroupAttributesScreenState extends ConsumerState<GroupAttributesScreen> {
  late String m;
  late String mUnit;
  late String l;
  late String lUnit;
  late String w;
  late String wUnit;
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
    type = g.groupType;
  }

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(moiProvider);
    final notifier = ref.read(moiProvider.notifier);
    final theme = Theme.of(context);
    final group = widget.group;

    final res = uiState.moiUnitsResolution;
    final swDisplay = '${uiState.currentSWAverage.toStringAsFixed(res)} kg·cm²';
    final twDisplay = '${uiState.currentTWAverage.toStringAsFixed(res)} kg·cm²';

    double? calculatedBP;
    if (group.mass > 0 && group.length > 0) {
      final sw = uiState.currentSWAverage;
      double massKg = group.mass;
      if (group.massUnit == 'oz') massKg = group.mass * 0.028349523125;
      if (group.massUnit == 'lb') massKg = group.mass * 0.45359237;

      if (group.groupType == 'Pickleball Paddle') {
        final lInches = group.lengthUnit == 'cm' ? group.length / 2.54 : group.length;
        calculatedBP = (sw - (492.0045 * massKg) - (6.8663 * lInches) + 259.5087) / 6.2811;
      } else {
        final lCm = group.lengthUnit == 'in' ? group.length * 2.54 : group.length;
        final tOffset = (group.groupType == 'Racquet' || group.groupType == 'MOI-10') ? 10.0 : 5.0;
        const r = 9.1;

        final insideSqrt = (sw / massKg) - (pow(lCm, 2) / 12.0) - (pow(r, 2) / 4.0);
        if (insideSqrt >= 0) {
          calculatedBP = sqrt(insideSqrt) + tOffset;
        }
      }
    }

    final bpDisplay = calculatedBP != null
        ? '${calculatedBP.toStringAsFixed(res)} cm'
        : 'N/A';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        notifier.selectEditingAttributesGroup(null);
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
                      onPressed: () => notifier.selectEditingAttributesGroup(null),
                    ),
                    Expanded(
                      child: DynamicTitleText(
                        text: 'Info: ${group.name}',
                        maxFontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Measured Results',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 6),

                        Card(
                          color: theme.colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              children: [
                                ReadOnlySettingField(
                                  label: 'Measured SW',
                                  value: swDisplay,
                                  width: 178,
                                  onLongClick: () {
                                    Clipboard.setData(ClipboardData(text: uiState.currentSWAverage.toStringAsFixed(res)));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Copied SW: ${uiState.currentSWAverage.toStringAsFixed(res)}')),
                                    );
                                  },
                                ),
                                Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                                ReadOnlySettingField(
                                  label: 'Measured TW',
                                  value: twDisplay,
                                  width: 178,
                                  onLongClick: () {
                                    Clipboard.setData(ClipboardData(text: uiState.currentTWAverage.toStringAsFixed(res)));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Copied TW: ${uiState.currentTWAverage.toStringAsFixed(res)}')),
                                    );
                                  },
                                ),
                                Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.3)),
                                ReadOnlySettingField(
                                  label: 'Calculated BP',
                                  value: bpDisplay,
                                  width: 178,
                                  onLongClick: calculatedBP != null
                                      ? () {
                                          final bpVal = calculatedBP!;
                                          Clipboard.setData(ClipboardData(text: bpVal.toStringAsFixed(res)));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Copied BP: ${bpVal.toStringAsFixed(res)}')),
                                          );
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Physical Attributes',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(height: 6),

                        Card(
                          color: theme.colorScheme.surfaceVariant,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                                TypeSelector(
                                  label: 'Type',
                                  current: type,
                                  options: const ['Pickleball Paddle', 'Racquet'],
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () {
                              final mVal = double.tryParse(m) ?? 0.0;
                              final lVal = double.tryParse(l) ?? 0.0;
                              final wVal = double.tryParse(w) ?? 0.0;
                              notifier.updateGroupAttributes(
                                group,
                                mVal,
                                mUnit,
                                lVal,
                                lUnit,
                                wVal,
                                wUnit,
                                type,
                              );
                              notifier.selectEditingAttributesGroup(null);
                            },
                            child: const Text('Save Attributes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
