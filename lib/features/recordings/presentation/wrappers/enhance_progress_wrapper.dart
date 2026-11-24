import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../vocal_enhance/domain/entities/enhance_progress.dart';
import '../../../vocal_enhance/presentation/di/vocal_enhance_getters.dart';
import '../di/recordings_getters.dart';

/// How far the enhancement of one take is; a take waiting in the queue shows 0.
///
/// The only wrapper that watches the enhancement progress, so the list and the tiles do not rebuild with it; it gives a plain
/// [LinearProgressIndicator] the fraction.
final class EnhanceProgressWrapper extends WatchingWidget {
  /// The take whose progress is shown.
  final String recordingId;

  /// Creates a new [EnhanceProgressWrapper].
  const EnhanceProgressWrapper({super.key, required this.recordingId});

  @override
  Widget build(BuildContext context) {
    final bool isEnhanced = watchPropertyValue(_isEnhancedOf, target: watchEnhancingRecordingUseCase());
    final double fraction = watchPropertyValue(_fractionOf, target: watchEnhanceProgressUseCase());
    return LinearProgressIndicator(value: isEnhanced ? fraction : 0);
  }

  bool _isEnhancedOf(ValueListenable<String?> enhancingId) => enhancingId.value == recordingId;

  static double _fractionOf(ValueListenable<EnhanceProgress?> progress) => progress.value?.fraction ?? 0;
}
