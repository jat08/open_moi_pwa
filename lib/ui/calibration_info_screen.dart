import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/moi_provider.dart';
import 'components.dart';

class CalibrationInfoScreen extends ConsumerStatefulWidget {
  final CalibrationTarget target;

  const CalibrationInfoScreen({
    super.key,
    required this.target,
  });

  @override
  ConsumerState<CalibrationInfoScreen> createState() => _CalibrationInfoScreenState();
}

class _CalibrationInfoScreenState extends ConsumerState<CalibrationInfoScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final uiState = ref.read(moiProvider);
    double val = 0.0;
    switch (widget.target) {
      case CalibrationTarget.OBJECT_A:
        val = uiState.expectedPeriodA;
        break;
      case CalibrationTarget.OBJECT_B:
        val = uiState.expectedPeriodB;
        break;
      case CalibrationTarget.TARE_PB:
        val = uiState.expectedMoiPB;
        break;
      case CalibrationTarget.TARE_TW:
        val = uiState.expectedMoiTW;
        break;
      default:
        val = 0.0;
        break;
    }
    _controller = TextEditingController(text: val.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(moiProvider.notifier);
    final theme = Theme.of(context);

    String targetName = '';
    switch (widget.target) {
      case CalibrationTarget.OBJECT_A:
        targetName = 'Object A';
        break;
      case CalibrationTarget.OBJECT_B:
        targetName = 'Object B';
        break;
      case CalibrationTarget.TARE_PB:
        targetName = 'Pickleball Adapter';
        break;
      case CalibrationTarget.TARE_TW:
        targetName = 'Twist Weight Adapter';
        break;
      default:
        break;
    }

    final isPeriod = widget.target == CalibrationTarget.OBJECT_A || widget.target == CalibrationTarget.OBJECT_B;
    final label = isPeriod ? 'Expected Period (s)' : 'Expected MOI (kg·cm²)';

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        notifier.selectEditingExpectedValue(null);
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
                      onPressed: () => notifier.selectEditingExpectedValue(null),
                    ),
                    Expanded(
                      child: DynamicTitleText(
                        text: 'Info: $targetName',
                        maxFontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _controller,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: label,
                    border: const OutlineInputBorder(),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () {
                      final val = double.tryParse(_controller.text);
                      if (val != null) {
                        notifier.updateExpectedValue(widget.target, val);
                      }
                    },
                    child: const Text('Save Expected Value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
