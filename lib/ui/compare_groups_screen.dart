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
      return bpInches;
    } else {
      final lCm = g.lengthUnit == 'in' ? g.length * 2.54 : g.length;
      final tOffset = (g.groupType == 'Racquet' || g.groupType == 'MOI-10') ? 10.0 : 5.0;
      const r = 9.1;

      final insideSqrt = (sw / massKg) - (pow(lCm, 2) / 12.0) - (pow(r, 2) / 4.0);
      if (insideSqrt >= 0) {
        final rootCm = sqrt(insideSqrt) + tOffset;
        return rootCm / 2.54;
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
    String g1Type = 'Pickleball Paddle';
    String g2Type = 'Pickleball Paddle';

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
    String g1BPUnit = 'in';
    double? g2BP;
    String g2BPUnit = 'in';

    if (isMeasure) {
      final s1 = widget.groups[0] as GroupSummary;
      final s2 = widget.groups[1] as GroupSummary;

      g1Name = s1.group.name;
      g2Name = s2.group.name;
      g1Type = s1.group.groupType;
      g2Type = s2.group.groupType;

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
      g1BPUnit = 'in';
      g2BP = _calculateBpForGroup(s2.group, g2SW);
      g2BPUnit = 'in';
    } else {
      final e1 = widget.groups[0] as EstimationGroup;
      final e2 = widget.groups[1] as EstimationGroup;

      g1Name = e1.name;
      g2Name = e2.name;
      g1Type = e1.type;
      g2Type = e2.type;

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

    final c1Mass = _convertMass(g1Mass, g1MassUnit, _massDisplayUnit);
    final c2Mass = _convertMass(g2Mass, g2MassUnit, _massDisplayUnit);

    final c1Length = _convertDistance(g1Length, g1LengthUnit, _lengthDisplayUnit);
    final c2Length = _convertDistance(g2Length, g2LengthUnit, _lengthDisplayUnit);

    final c1Width = _convertDistance(g1Width, g1WidthUnit, _widthDisplayUnit);
    final c2Width = _convertDistance(g2Width, g2WidthUnit, _widthDisplayUnit);

    final c1BP = g1BP != null ? _convertDistance(g1BP, g1BPUnit, _bpDisplayUnit) : null;
    final c2BP = g2BP != null ? _convertDistance(g2BP, g2BPUnit, _bpDisplayUnit) : null;

    Widget buildStaticUnitBadge() {
      return Container(
        width: 62,
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'kg·cm²',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      );
    }

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
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface, size: 26),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        notifier.closeComparison();
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Group Comparison',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Expanded(
                  child: SingleChildScrollView(
                    child: Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Column(
                          children: [
                            // Header Row with Group Names
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    g1Name,
                                    textAlign: TextAlign.left,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    g2Name,
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),
                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withValues(alpha: 0.2)),

                            // Swing Weight Row
                            _CompareRow(
                              title: 'Swing Weight',
                              unitBadge: buildStaticUnitBadge(),
                              val1: g1SW > 0 ? g1SW.toStringAsFixed(res) : 'N/A',
                              val2: g2SW > 0 ? g2SW.toStringAsFixed(res) : 'N/A',
                              num1: g1SW > 0 ? g1SW : null,
                              num2: g2SW > 0 ? g2SW : null,
                              decimals: res,
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withValues(alpha: 0.2)),

                            // Twist Weight Row
                            _CompareRow(
                              title: 'Twist Weight',
                              unitBadge: buildStaticUnitBadge(),
                              val1: g1TW > 0 ? g1TW.toStringAsFixed(res) : 'N/A',
                              val2: g2TW > 0 ? g2TW.toStringAsFixed(res) : 'N/A',
                              num1: g1TW > 0 ? g1TW : null,
                              num2: g2TW > 0 ? g2TW : null,
                              decimals: res,
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withValues(alpha: 0.2)),

                            // Weight Row (removed 'g')
                            _CompareRow(
                              title: 'Weight',
                              unitBadge: UnitPicklist(
                                current: _massDisplayUnit,
                                units: const ['oz', 'lb', 'kg'],
                                onSelect: (u) => setState(() => _massDisplayUnit = u),
                                width: 62,
                              ),
                              val1: c1Mass > 0 ? c1Mass.toStringAsFixed(2) : 'N/A',
                              val2: c2Mass > 0 ? c2Mass.toStringAsFixed(2) : 'N/A',
                              num1: c1Mass > 0 ? c1Mass : null,
                              num2: c2Mass > 0 ? c2Mass : null,
                              decimals: 2,
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withValues(alpha: 0.2)),

                            // Length Row
                            _CompareRow(
                              title: 'Length',
                              unitBadge: UnitPicklist(
                                current: _lengthDisplayUnit,
                                units: const ['in', 'cm'],
                                onSelect: (u) => setState(() => _lengthDisplayUnit = u),
                                width: 62,
                              ),
                              val1: c1Length > 0 ? c1Length.toStringAsFixed(_lengthDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              val2: c2Length > 0 ? c2Length.toStringAsFixed(_lengthDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              num1: c1Length > 0 ? c1Length : null,
                              num2: c2Length > 0 ? c2Length : null,
                              decimals: _lengthDisplayUnit == 'cm' ? 1 : 2,
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withValues(alpha: 0.2)),

                            // Width Row
                            _CompareRow(
                              title: 'Width',
                              unitBadge: UnitPicklist(
                                current: _widthDisplayUnit,
                                units: const ['in', 'cm'],
                                onSelect: (u) => setState(() => _widthDisplayUnit = u),
                                width: 62,
                              ),
                              val1: c1Width > 0 ? c1Width.toStringAsFixed(_widthDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              val2: c2Width > 0 ? c2Width.toStringAsFixed(_widthDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              num1: c1Width > 0 ? c1Width : null,
                              num2: c2Width > 0 ? c2Width : null,
                              decimals: _widthDisplayUnit == 'cm' ? 1 : 2,
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withValues(alpha: 0.2)),

                            // Balance Point Row
                            _CompareRow(
                              title: 'Balance Point',
                              unitBadge: UnitPicklist(
                                current: _bpDisplayUnit,
                                units: const ['in', 'cm'],
                                onSelect: (u) => setState(() => _bpDisplayUnit = u),
                                width: 62,
                              ),
                              val1: c1BP != null && c1BP > 0 ? c1BP.toStringAsFixed(_bpDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              val2: c2BP != null && c2BP > 0 ? c2BP.toStringAsFixed(_bpDisplayUnit == 'cm' ? 1 : 2) : 'N/A',
                              num1: c1BP != null && c1BP > 0 ? c1BP : null,
                              num2: c2BP != null && c2BP > 0 ? c2BP : null,
                              decimals: _bpDisplayUnit == 'cm' ? 1 : 2,
                            ),

                            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline.withValues(alpha: 0.2)),

                            // Type Row
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                children: [
                                  Text(
                                    'Type',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        g1Type,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        g2Type,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

class _CompareRow extends StatelessWidget {
  final String title;
  final Widget unitBadge;
  final String val1;
  final String val2;
  final double? num1;
  final double? num2;
  final int decimals;

  const _CompareRow({
    required this.title,
    required this.unitBadge,
    required this.val1,
    required this.val2,
    this.num1,
    this.num2,
    this.decimals = 2,
  });

  Widget _buildDeltaBadge(double diff) {
    final isPositive = diff > 0;
    final isZero = diff.abs() < 1e-6;

    final bgColor = isZero
        ? const Color(0xFFF0F4F8)
        : (isPositive ? const Color(0xFFE8F8EE) : const Color(0xFFFFF3E0));
    final textColor = isZero
        ? const Color(0xFF70787D)
        : (isPositive ? const Color(0xFF287D41) : const Color(0xFFD97706));

    final signStr = isZero ? '' : (isPositive ? '+' : '-');
    final formattedVal = diff.abs().toStringAsFixed(decimals);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Δ: $signStr$formattedVal',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? leftDelta;
    Widget? rightDelta;

    if (num1 != null && num2 != null) {
      final diffLeft = num1! - num2!;
      final diffRight = num2! - num1!;

      leftDelta = _buildDeltaBadge(diffLeft);
      rightDelta = _buildDeltaBadge(diffRight);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 1),
              unitBadge,
            ],
          ),

          const SizedBox(height: 3),

          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      val1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (leftDelta != null) ...[
                      const SizedBox(width: 4),
                      leftDelta,
                    ],
                  ],
                ),
              ),

              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (rightDelta != null) ...[
                      rightDelta,
                      const SizedBox(width: 4),
                    ],
                    Text(
                      val2,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
