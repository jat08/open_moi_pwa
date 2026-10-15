import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PageTypography {
  final double scale;

  PageTypography._(this.scale);

  factory PageTypography.of(BuildContext context, {double baselineWidth = 390.0}) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final textScale = mediaQuery.textScaler.scale(1.0);

    // Calculate a page-level unified scale factor based on screen width and system text scaling.
    double widthFactor = (width / baselineWidth).clamp(0.78, 1.15);
    double zoomCompensation = textScale > 1.0 ? (1.0 / (1.0 + (textScale - 1.0) * 0.4)) : 1.0;
    double unifiedScale = (widthFactor * zoomCompensation).clamp(0.75, 1.15);

    return PageTypography._(unifiedScale);
  }

  double pageTitleSize([double base = 24.0]) => (base * scale).clamp(16.0, base);
  double sectionHeaderSize([double base = 18.0]) => (base * scale).clamp(14.0, base);
  double cardTitleSize([double base = 17.0]) => (base * scale).clamp(12.0, base);
  double fieldLabelSize([double base = 14.0]) => (base * scale).clamp(10.0, base);
  double valueLargeSize([double base = 36.0]) => (base * scale).clamp(18.0, base);
  double valueMediumSize([double base = 18.0]) => (base * scale).clamp(12.0, base);
  double valueSmallSize([double base = 14.0]) => (base * scale).clamp(10.0, base);
  double subtextSize([double base = 12.0]) => (base * scale).clamp(9.0, base);

  /// Computes a unified minimum font size across a list of sibling text values
  /// given available max width constraints.
  double computeUnifiedSize({
    required List<String> texts,
    required double maxFontSize,
    required double maxWidth,
    required FontWeight fontWeight,
  }) {
    double targetBase = maxFontSize * scale;
    double minSize = targetBase < maxFontSize ? targetBase : maxFontSize;
    if (minSize < 10.0) minSize = 10.0;

    for (final text in texts) {
      if (text.isEmpty) continue;
      double currentSize = minSize;
      final style = TextStyle(fontSize: currentSize, fontWeight: fontWeight);

      TextPainter painter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: ui.TextDirection.ltr,
      )..layout();

      while (painter.width > maxWidth && currentSize > 10.0) {
        currentSize -= 0.5;
        painter = TextPainter(
          text: TextSpan(text: text, style: TextStyle(fontSize: currentSize, fontWeight: fontWeight)),
          maxLines: 1,
          textDirection: ui.TextDirection.ltr,
        )..layout();
      }

      if (currentSize < minSize) {
        minSize = currentSize;
      }
    }

    return minSize;
  }
}
