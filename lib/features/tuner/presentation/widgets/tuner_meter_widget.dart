import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/note.dart';
import '../../domain/entities/tuner_reading.dart';

/// The texts of [TunerMeterWidget].
final class TunerMeterTexts {
  /// Shown instead of the action while nothing clear sounds.
  final String idleText;

  /// Shown when the pitch is in tune.
  final String inTuneText;

  /// Shown when the pitch is too low.
  final String tuneUpText;

  /// Shown when the pitch is too high.
  final String tuneDownText;

  /// Formats the heard frequency (`110.0 Hz`).
  final String Function(String value) hertzText;

  /// Formats the distance in cents (`-12 cents`).
  final String Function(String value) centsText;

  /// Creates the texts.
  const TunerMeterTexts({
    required this.idleText,
    required this.inTuneText,
    required this.tuneUpText,
    required this.tuneDownText,
    required this.hertzText,
    required this.centsText,
  });
}

/// The note to tune to, a scale from -50 to +50 cents with a needle, and what to do.
///
/// Dumb: shows [reading], or the idle text of [texts] while nothing clear sounds.
final class TunerMeterWidget extends StatelessWidget {
  static const double _noteFontSize = 72;
  static const double _scaleCents = 50;
  static const double _scaleHeight = 56;
  static const double _needleWidth = 4;
  static const double _tickHeight = 16;
  static const double _centerTickHeight = 32;
  static const double _tickWidth = 1;
  static const int _ticks = 10;
  static const double _halfAlpha = 0.5;
  static const Duration _move = Duration(milliseconds: 120);
  static const String _noNote = '–';
  static const String _separator = ' · ';
  static const String _emptyLine = ' ';
  static const int _hertzDigits = 1;

  /// The reading, `null` while nothing clear sounds.
  final TunerReading? reading;

  /// The texts.
  final TunerMeterTexts texts;

  /// Creates a [TunerMeterWidget].
  const TunerMeterWidget({required this.reading, required this.texts, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TunerReading? current = reading;
    final Color needleColor = current == null
        ? colors.outlineVariant
        : current.isInTune
        ? AppTheme.accentGreen
        : colors.primary;
    final double position = current == null ? 0 : (current.cents / _scaleCents).clamp(-1.0, 1.0);
    final Note? target = current?.target;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text.rich(
          TextSpan(
            text: target?.name ?? _noNote,
            children: <InlineSpan>[
              if (target != null)
                TextSpan(
                  text: '${target.octave}',
                  style: theme.textTheme.headlineSmall?.copyWith(color: needleColor),
                ),
            ],
          ),
          style: theme.textTheme.displayLarge?.copyWith(
            fontSize: _noteFontSize,
            fontWeight: FontWeight.w600,
            color: needleColor,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        SizedBox(
          height: _scaleHeight,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double half = constraints.maxWidth / 2;
              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  for (int i = 0; i <= _ticks; i++)
                    Positioned(
                      left: constraints.maxWidth * i / _ticks - _tickWidth / 2,
                      child: Container(
                        width: _tickWidth,
                        height: i == _ticks ~/ 2 ? _centerTickHeight : _tickHeight,
                        color: colors.outline.withValues(alpha: i == _ticks ~/ 2 ? 1 : _halfAlpha),
                      ),
                    ),
                  AnimatedPositioned(
                    duration: _move,
                    left: half + position * half - _needleWidth / 2,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: _needleWidth,
                      decoration: BoxDecoration(color: needleColor, borderRadius: BorderRadius.circular(_needleWidth)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          current == null
              ? texts.idleText
              : current.isInTune
              ? texts.inTuneText
              : current.cents < 0
              ? texts.tuneUpText
              : texts.tuneDownText,
          style: theme.textTheme.titleLarge?.copyWith(color: needleColor),
        ),
        const SizedBox(height: AppTheme.spacingTiny),
        Text(
          current == null
              ? _emptyLine
              : '${texts.hertzText(current.hertz.toStringAsFixed(_hertzDigits))}$_separator'
                    '${texts.centsText(current.cents.round().toString())}',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}
