import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';

import '../../domain/entities/microphone.dart';
import 'recording_tile_widget.dart';

/// Lets the user choose the sound input of the takes; pops the chosen [Microphone]
/// ([systemMicrophone] for the input the system uses), or `null` when cancelled.
final class MicrophonePickerDialogWidget extends StatelessWidget {
  /// Stands for the input chosen in the system settings.
  static const Microphone systemMicrophone = Microphone(id: '', label: '');

  /// The inputs of the device.
  final List<Microphone> microphones;

  /// The chosen input, or `null` for the system one.
  final String? selectedId;

  /// The texts.
  final RecordingsTexts texts;

  /// Creates a new [MicrophonePickerDialogWidget].
  const MicrophonePickerDialogWidget({
    super.key,
    required this.microphones,
    required this.selectedId,
    required this.texts,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String selected = selectedId ?? systemMicrophone.id;
    return SimpleDialog(
      title: Text(texts.microphoneTitle),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
          child: Text(
            texts.microphoneHint,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        for (final Microphone microphone in <Microphone>[systemMicrophone, ...microphones])
          ListTile(
            leading: Icon(microphone.id == selected ? Icons.radio_button_checked : Icons.radio_button_unchecked),
            title: Text(microphone.id == systemMicrophone.id ? texts.systemMicrophoneLabel : microphone.label),
            onTap: () => _onChosen(context, microphone),
          ),
      ],
    );
  }

  void _onChosen(BuildContext context, Microphone microphone) {
    Navigator.of(context).pop(microphone);
  }
}
