import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/instrument.dart';

/// The tuner: the instruments to choose from, then the reading — or, when the microphone could not be opened, the
/// failure with a retry.
///
/// Dumb: the chosen instrument, the failure text, the reading ([reading], its wrapper follows the pitch) and the
/// callbacks come from above.
final class TunerPanelWidget extends StatelessWidget {
  /// The chosen instrument.
  final Instrument instrument;

  /// The name of an instrument as shown on its chip.
  final String Function(Instrument instrument) instrumentLabelOf;

  /// Why the microphone could not be opened, or `null` while it listens.
  final String? failureText;

  /// Label of the retry button.
  final String retryLabel;

  /// The reading of the heard pitch.
  final Widget reading;

  /// Called with the instrument chosen.
  final ValueChanged<Instrument> onInstrumentSelected;

  /// Called by the retry button.
  final VoidCallback onRetryPressed;

  /// Creates a [TunerPanelWidget].
  const TunerPanelWidget({
    super.key,
    required this.instrument,
    required this.instrumentLabelOf,
    required this.failureText,
    required this.retryLabel,
    required this.reading,
    required this.onInstrumentSelected,
    required this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final String? failure = failureText;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppTheme.spacingSmall,
                runSpacing: AppTheme.spacingSmall,
                children: <Widget>[
                  for (final Instrument choice in Instrument.values)
                    ChoiceChip(
                      label: Text(instrumentLabelOf(choice)),
                      selected: choice == instrument,
                      onSelected: (bool selected) => onInstrumentSelected(choice),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingExtraLarge),
              if (failure != null)
                Column(
                  children: <Widget>[
                    Text(failure, textAlign: TextAlign.center),
                    const SizedBox(height: AppTheme.spacingMedium),
                    FilledButton(onPressed: onRetryPressed, child: Text(retryLabel)),
                  ],
                )
              else
                reading,
            ],
          ),
        ),
      ),
    );
  }
}
