import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models.dart';
import '../providers/moi_provider.dart';
import 'components.dart';

class CompareGroupsScreen extends ConsumerStatefulWidget {
  final List<dynamic> groups;

  const CompareGroupsScreen({
    super.key,
    required this.groups,
  });

  @override
  ConsumerState<CompareGroupsScreen> createState() => _CompareGroupsScreenState();
}

class _CompareGroupsScreenState extends ConsumerState<CompareGroupsScreen> {
  String _massDisplayUnit = 'oz';
  String _lengthDisplayUnit = 'in';
  String _widthDisplayUnit = 'in';
  String _bpDisplayUnit = 'in';

  // --- Conversion Helpers ---
  double _convertMass(double val, String fromUnit, String toUnit) {
    if (val <= 0) return 0.0;
    // Convert to oz first
    double oz;
    switch (fromUnit.toLowerCase()) {
      case 'g':
        oz = val / 28.349523125;
        break;
      case 'lb':
        oz = val * 16.0;
        break;
      case 'kg':
        oz = val * 35.27396195;
        break;
      case 'oz':
      default:
        oz = val;
    }

    // Convert oz to toUnit
    switch (toUnit.toLowerCase()) {
      case 'g':
        return oz * 28.349523125;
      case 'lb':
        return oz / 16.0;
      case 'kg':
        return oz / 35.27396195;
      case 'oz':
      default:
        return oz;
    }
  }

  double _convertDistance(double val, String fromUnit, String toUnit) {
    if (val <= 0) return 0.0;
    // Convert to inches first
    double inches = fromUnit.toLowerCase() == 'cm' ? val / 2.54 : val;
    return toUnit.toLowerCase() == 'cm' ? inches * 2.54 : inches;
  }

  double? _calculateBpForGroup(MeasurementGroup g, double sw) {
    if (g.mass <= 0 || g.length <= 0) return null;
    double massKg = g.mass;
    if (g.massUnit == 'oz') massKg = g.mass * 0.028349523125;
    if (g.massUnit == 'lb') massKg = g.mass * 0.45359237;

    if (g.groupType == 'Pickleball Paddle') {
      final lInches = g.lengthUnit == 'cm' ? g.length / 2.54 : g.length;
      final bpInches = (sw - (492.0045 * massKg) - (6.8663 * lInches) + 259.5087) / 6.2811;
      return bpInches * 2.54; // Return in cm
    } else {
      final lCm = g.lengthUnit == 'in' ? g.length * 2.54 : g.length;
      final tOffset = (g.groupType == 'Racquet' || g.groupType == 'MOI-10') ? 10.0 : 5.0;
      const r = 9.1;

      final insideSqrt = (sw / massKg) - (pow(lCm, 2) / 12.0) - (pow(r, 2) / 4.0);
      if (insideSqrt >= 0) {
        return sqrt(insideSqrt) + tOffset; // In cm
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uiState = ref.watch(moiProvider);
    final notifier = ref.read(moiProvider.notifier);

    final res = uiState.moiUnitsResolution;

    final isMeasure = widget.groups.first is GroupSummary;

    String g1Name = '';
    String g2Name = '';
    double g1SW = 0.0;
    double g2SW = 0.0;
    double g1TW = 0.0;
    double g2TW = 0.0;

    double g1Mass = 0.0;
    String g1MassUnit = 'oz';
    double g2Mass = 0.0;
    String g2MassUnit = 'oz';

    double g1Length = 0.0;
    String g1LengthUnit = 'in';
    double g2Length = 0.0;
    String g2LengthUnit = 'in';

    double g1Width = 0.0;
    String g1WidthUnit = 'in';
    double g2Width = 0.0;
    String g2WidthUnit = 'in';

    double? g1BP;
    String g1BPUnit = 'cm';
    double? g2BP;
    String g2BPUnit = 'cm';

    if (isMeasure) {
      final s1 = widget.groups[0] as GroupSummary;
      final s2 = widget.groups[1] as GroupSummary;

      g1Name = s1.group.name;
      g2Name = s2.group.name;
      g1SW = s1.avgSW;
      g2SW = s2.avgSW;
      g1TW = s1.avgTW;
      g2TW = s2.avgTW;

      g1Mass = s1.group.mass;
      g1MassUnit = s1.group.massUnit;
      g2Mass = s2.group.mass;
      g2MassUnit = s2.group.massUnit;

      g1Length = s1.group.length;
      g1LengthUnit = s1.group.lengthUnit;
      g2Length = s2.group.length;
      g2LengthUnit = s2.group.lengthUnit;

      g1Width = s1.group.width;
      g1WidthUnit = s1.group.widthUnit;
      g2Width = s2.group.width;
      g2WidthUnit = s2.group.widthUnit;

      g1BP = _calculateBpForGroup(s1.group, g1SW);
      g1BPUnit = 'cm';
      g2BP = _calculateBpForGroup(s2.group, g2SW);
      g2BPUnit = 'cm';
    } else {
      final e1 = widget.groups[0] as EstimationGroup;
      final e2 = widget.groups[1] as EstimationGroup;

      g1Name = e1.name;
      g2Name = e2.name;
      g1SW = e1.resultSW;
      g2SW = e2.resultSW;
      g1TW = e1.resultTW;
      g2TW = e2.resultTW;

      g1Mass = e1.mass;
      g1MassUnit = e1.massUnit;
      g2Mass = e2.mass;
      g2MassUnit = e2.massUnit;

      g1Length = e1.length;
      g1LengthUnit = e1.lengthUnit;
      g2Length = e2.length;
      g2LengthUnit = e2.lengthUnit;

      g1Width = e1.width;
      g1WidthUnit = e1.widthUnit;
      g2Width = e2.width;
      g2WidthUnit = e2.widthUnit;

      g1BP = e1.balancePoint;
      g1BPUnit = e1.bpUnit;
      g2BP = e2.balancePoint;
      g2BPUnit = e2.bpUnit;
    }

    // Convert values to selected display units
    final c1Mass = _convertMass(g1Mass, g1MassUnit, _massDisplayUnit);
    final c2Mass = _convertMass(g2Mass, g2MassUnit, _massDisplayUnit);

    final c1Length = _convertDistance(g1Length, g1LengthUnit, _lengthDisplayUnit);
    final c2Length = _convertDistance(g2Length, g2LengthUnit, _lengthDisplayUnit);

    final c1Width = _convertDistance(g1Width, g1WidthUnit, _widthDisplayUnit);
    final c2Width = _convertDistance(g2Width, g2WidthUnit, _widthDisplayUnit);

    final c1BP = g1BP != null ? _convertDistance(g1BP, g1BPUnit, _bpDisplayUnit) : null;
    final c2BP = g2BP != null ? _convertDistance(g2BP, g2BPUnit, _bpDisplayUnit) : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        notifier.closeComparison();
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
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        notifier.closeComparison();
                      },
                    ),
                    Expanded(
                      child: DynamicTitleText(
                        text: 'Group Comparison',
                        maxFontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Group Headers Side-by-Side
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          g1Name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          g2Name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Expanded(
                  child: SingleChildScrollView(
                    child: Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(
                          children: [
                            // SW Row
                            _CompareDataRow(
                              title: 'SW (kg·cm²)',
                              val1: g1SW > 0 ? g1SW.toStringAsFixed(res) : 'N/A',
                              val2: g2SW > 0 ? g2SW.toStringAsFixed(res) : 'N/A',
                              delta: (g1SW > 0 && g2SW > 0)
                                  ? '${(g1SW - g2SW) > 0 ? "+" : ""}${(g1SW - g2SW).toStringAsFixed(res)}'
                                  : null,
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.25)),

                            // TW Row
                            _CompareDataRow(
                              title: 'TW (kg·cm²)',
                              val1: g1TW > 0 ? g1TW.toStringAsFixed(res) : 'N/A',
                              val2: g2TW > 0 ? g2TW.toStringAsFixed(res) : 'N/A',
                              delta: (g1TW > 0 && g2TW > 0)
                                  ? '${(g1TW - g2TW) > 0 ? "+" : ""}${(g1TW - g2TW).toStringAsFixed(res)}'
                                  : null,
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.25)),

                            // Weight / Mass Row with Unit Picklist
                            _CompareDataRowWithUnit(
                              title: 'Weight',
                              currentUnit: _massDisplayUnit,
                              units: const ['oz', 'g', 'lb', 'kg'],
                              val1: c1Mass > 0 ? c1Mass.toStringAsFixed(_massDisplayUnit == 'g' ? 1 : 2) : 'N/A',
                              val2: c2Mass > 0 ? c2Mass.toStringAsFixed(_massDisplayUnit == 'g' ? 1 : 2) : 'N/A',
                              delta: (c1Mass > 0 && c2Mass > 0)
                                  ? '${(c1Mass - c2Mass) > 0 ? "+" : ""}${(c1Mass - c2Mass).toStringAsFixed(_massDisplayUnit == 'g' ? 1 : 2)}'
                                  : null,
                              onUnitSelect: (u) => setState(() => _massDisplayUnit = u),
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.25)),

                            // Length Row with Unit Picklist
                            _CompareDataRowWithUnit(
                              title: 'Length',
                              currentUnit: _lengthDisplayUnit,
                              units: const ['in', 'cm'],
                              val1: c1Length > 0 ? c1Length.toStringAsFixed(_lengthDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              val2: c2Length > 0 ? c2Length.toStringAsFixed(_lengthDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              delta: (c1Length > 0 && c2Length > 0)
                                  ? '${(c1Length - c2Length) > 0 ? "+" : ""}${(c1Length - c2Length).toStringAsFixed(_lengthDisplayUnit == 'cm' ? 1 : 2)}'
                                  : null,
                              onUnitSelect: (u) => setState(() => _lengthDisplayUnit = u),
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.25)),

                            // Width Row with Unit Picklist
                            _CompareDataRowWithUnit(
                              title: 'Width',
                              currentUnit: _widthDisplayUnit,
                              units: const ['in', 'cm'],
                              val1: c1Width > 0 ? c1Width.toStringAsFixed(_widthDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              val2: c2Width > 0 ? c2Width.toStringAsFixed(_widthDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              delta: (c1Width > 0 && c2Width > 0)
                                  ? '${(c1Width - c2Width) > 0 ? "+" : ""}${(c1Width - c2Width).toStringAsFixed(_widthDisplayUnit == 'cm' ? 1 : 2)}'
                                  : null,
                              onUnitSelect: (u) => setState(() => _widthDisplayUnit = u),
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withOpacity(0.25)),

                            // BP Row with Unit Picklist
                            _CompareDataRowWithUnit(
                              title: 'BP',
                              currentUnit: _bpDisplayUnit,
                              units: const ['in', 'cm'],
                              val1: c1BP != null && c1BP > 0 ? c1BP.toStringAsFixed(_bpDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              val2: c2BP != null && c2BP > 0 ? c2BP.toStringAsFixed(_bpDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              delta: (c1BP != null && c2BP != null && c1BP > 0 && c2BP > 0)
                                  ? '${(c1BP - c2BP) > 0 ? "+" : ""}${(c1BP - c2BP).toStringAsFixed(_bpDisplayUnit == 'cm' ? 1 : 2)}'
                                  : null,
                              onUnitSelect: (u) => setState(() => _bpDisplayUnit = u),
                            ),
                          ],
                        ),
                      ),
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

class _CompareDataRow extends StatelessWidget {
  final String title;
  final String val1;
  final String val2;
  final String? delta;

  const _CompareDataRow({
    required this.title,
    required this.val1,
    required this.val2,
    this.delta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
              if (delta != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Δ $delta',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  val1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ),
              Container(width: 1, height: 20, color: theme.colorScheme.outline.withOpacity(0.25)),
              Expanded(
                child: Text(
                  val2,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompareDataRowWithUnit extends StatelessWidget {
  final String title;
  final String currentUnit;
  final List<String> units;
  final String val1;
  final String val2;
  final String? delta;
  final ValueChanged<String> onUnitSelect;

  const _CompareDataRowWithUnit({
    required this.title,
    required this.currentUnit,
    required this.units,
    required this.val1,
    required this.val2,
    this.delta,
    required this.onUnitSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$title ($currentUnit)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  UnitPicklist(
                    current: currentUnit,
                    units: units,
                    onSelect: onUnitSelect,
                    width: 62,
                  ),
                ],
              ),
              if (delta != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Δ $delta $currentUnit',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  val1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ),
              Container(width: 1, height: 20, color: theme.colorScheme.outline.withOpacity(0.25)),
              Expanded(
                child: Text(
                  val2,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
