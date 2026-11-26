import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/features/tuner/data/data_sources/pcm_pitch_framer.dart';
import 'package:hitwave.cover/features/tuner/data/data_sources/pitch_data_source.dart';
import 'package:hitwave.cover/features/tuner/data/data_sources/yin_pitch_detector.dart';
import 'package:hitwave.cover/features/tuner/data/repositories/tuner_repository_impl.dart';
import 'package:hitwave.cover/features/tuner/domain/entities/tuner_failure.dart';
import 'package:hitwave.cover/features/tuner/domain/entities/tuner_state.dart';
import 'package:logger/logger.dart';

/// A plucked-string-like tone: the fundamental [hertz] with weaker harmonics.
Float64List tone(double hertz, double sampleRate, int length, {double amplitude = 0.5}) {
  final Float64List samples = Float64List(length);
  for (int i = 0; i < length; i++) {
    final double t = i / sampleRate;
    samples[i] =
        amplitude *
        (math.sin(2 * math.pi * hertz * t) +
            0.5 * math.sin(2 * math.pi * 2 * hertz * t) +
            0.25 * math.sin(2 * math.pi * 3 * hertz * t)) /
        1.75;
  }
  return samples;
}

/// [samples] as 16-bit little-endian PCM.
Uint8List pcm(Float64List samples) {
  final ByteData data = ByteData(samples.length * 2);
  for (int i = 0; i < samples.length; i++) {
    data.setInt16(i * 2, (samples[i] * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

double cents(double heard, double expected) => 1200 * math.log(heard / expected) / math.ln2;

/// Gives the pitches the test adds; records the calls.
final class FakePitchDataSource implements PitchDataSource {
  bool permission = true;
  bool failing = false;
  int stops = 0;
  StreamController<double?> pitches = StreamController<double?>();

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<Stream<double?>> listen() async {
    if (failing) throw Exception('busy');
    pitches = StreamController<double?>();
    return pitches.stream;
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Future<void> dispose() async {}
}

void main() {
  const double rate = 48000;
  const YinPitchDetector detector = YinPitchDetector(sampleRate: rate);

  group('YinPitchDetector', () {
    for (final double hertz in <double>[41.2, 82.41, 110, 196, 261.63, 392, 440, 659.26, 1318.5]) {
      test('finds $hertz Hz within half a cent', () {
        final double? heard = detector.detect(tone(hertz, rate, detector.windowSize));

        expect(heard, isNotNull);
        expect(cents(heard!, hertz).abs(), lessThan(0.5));
      });
    }

    test('silence and noise have no pitch', () {
      final math.Random random = math.Random(1);
      final Float64List noise = Float64List.fromList(
        List<double>.generate(detector.windowSize, (_) => random.nextDouble() - 0.5),
      );

      expect(detector.detect(Float64List(detector.windowSize)), isNull);
      expect(detector.detect(noise), isNull);
    });
  });

  test('a detuned string and a noisy tone are read within a cent', () {
    final math.Random random = math.Random(2);
    final Float64List noisy = tone(146.0, rate, detector.windowSize, amplitude: 0.3);
    for (int i = 0; i < noisy.length; i++) {
      noisy[i] += (random.nextDouble() - 0.5) * 0.03;
    }

    expect(cents(detector.detect(tone(108.5, rate, detector.windowSize))!, 108.5).abs(), lessThan(0.5));
    expect(cents(detector.detect(noisy)!, 146.0).abs(), lessThan(1));
  });

  test('a softly played string over the noise of a room is still heard', () {
    final math.Random random = math.Random(3);
    for (final double hertz in <double>[82.41, 110, 196, 329.63]) {
      final Float64List soft = tone(hertz, rate, detector.windowSize, amplitude: 0.006);
      for (int i = 0; i < soft.length; i++) {
        soft[i] += (random.nextDouble() - 0.5) * 0.003;
      }

      final double? heard = detector.detect(soft);
      expect(heard, isNotNull, reason: '$hertz Hz');
      expect(cents(heard!, hertz).abs(), lessThan(3), reason: '$hertz Hz');
    }
  });

  test('the quiet noise of a room is no pitch', () {
    final math.Random random = math.Random(4);
    final Float64List hiss = Float64List.fromList(
      List<double>.generate(detector.windowSize, (_) => (random.nextDouble() - 0.5) * 0.01),
    );

    expect(detector.detect(hiss), isNull);
  });

  test('the framer turns PCM chunks of any size into pitches, one per hop', () {
    const int hop = 1024;
    final PcmPitchFramer framer = PcmPitchFramer(detector, hopSize: hop);
    final Uint8List bytes = pcm(tone(110, rate, detector.windowSize * 3));
    final List<double?> pitches = <double?>[];
    // Odd chunk sizes split samples between chunks.
    for (int start = 0; start < bytes.length; start += 1001) {
      pitches.addAll(framer.add(Uint8List.sublistView(bytes, start, math.min(start + 1001, bytes.length))));
    }

    expect(pitches, isNotEmpty);
    for (final double? pitch in pitches) {
      expect(cents(pitch!, 110).abs(), lessThan(1));
    }
  });

  test('a chunk that completes several hops gives only its newest pitch', () {
    final PcmPitchFramer framer = PcmPitchFramer(detector, hopSize: 256);

    expect(framer.add(pcm(tone(110, rate, detector.windowSize * 2))), hasLength(1));
  });

  group('TunerRepositoryImpl', () {
    late FakePitchDataSource source;
    late TunerRepositoryImpl repository;

    setUp(() {
      source = FakePitchDataSource();
      repository = TunerRepositoryImpl(
        dataSource: source,
        logger: Logger(level: Level.off),
      );
    });

    Future<double?> heard() async {
      await Future<void>.delayed(Duration.zero);
      final TunerState state = repository.watchTuner().value;
      return state is ListeningTunerState ? state.hertz : null;
    }

    test('without the microphone permission the tuner stays off', () async {
      source.permission = false;

      final Result<void, TunerFailure> result = await repository.start();

      expect(result, isA<FailureResult<void, TunerFailure>>());
      expect(repository.watchTuner().value, isA<OffTunerState>());
    });

    test('a busy microphone is a start failure', () async {
      source.failing = true;

      expect((await repository.start()).isFailure, isTrue);
    });

    test('a stray pitch is outvoted, a short gap keeps the pitch, a long one clears it', () async {
      await repository.start();
      source.pitches
        ..add(110)
        ..add(110)
        ..add(220);
      expect(await heard(), 110);

      source.pitches.add(null);
      expect(await heard(), 110);

      for (int i = 0; i < 15; i++) {
        source.pitches.add(null);
      }
      expect(await heard(), isNull);
    });

    test('a small step is smoothed toward the new pitch, another string is shown at once', () async {
      await repository.start();
      source.pitches
        ..add(110)
        ..add(111)
        ..add(111);
      final double smoothed = (await heard())!;
      expect(smoothed, greaterThan(110));
      expect(smoothed, lessThan(111));

      source.pitches
        ..add(147)
        ..add(147);
      expect(await heard(), 147);
    });

    test('a start right after a stop opens the microphone again', () async {
      await repository.start();
      final Future<void> stopping = repository.stop();
      final Result<void, TunerFailure> started = await repository.start();
      await stopping;

      expect(started.isFailure, isFalse);
      expect(source.stops, 1);
      expect(repository.watchTuner().value, isA<ListeningTunerState>());
    });

    test('when the system ends the stream the next start listens again', () async {
      await repository.start();
      final StreamController<double?> first = source.pitches;
      await first.close();
      await Future<void>.delayed(Duration.zero);
      expect(repository.watchTuner().value, isA<OffTunerState>());

      await repository.start();
      expect(identical(source.pitches, first), isFalse);
    });

    test('stopping frees the microphone once and turns the tuner off', () async {
      await repository.start();
      await repository.start();

      await repository.stop();
      await repository.stop();

      expect(source.stops, 1);
      expect(repository.watchTuner().value, isA<OffTunerState>());
    });
  });
}
