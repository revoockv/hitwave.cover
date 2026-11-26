// Demo data for the screenshot and layout tests: made-up songs (no real lyrics end up in the README), two weeks of
// practice and six enhanced takes, written while the app runs on a storage folder of its own.
import 'dart:io';
import 'dart:typed_data';

import 'package:hitwave.cover/features/practice/data/models/practice_session_model.dart';
import 'package:hitwave.cover/features/recordings/data/models/recording_model.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_status.dart';
import 'package:hitwave.cover/features/settings/data/models/app_settings_model.dart';
import 'package:hitwave.cover/features/settings/domain/entities/app_settings.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/presentation/di/song_getters.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

/// Made-up songs, so that no real lyrics end up in the README.
const List<({String author, String name, String album, String lyrics})> demoSongs =
    <({String author, String name, String album, String lyrics})>[
      (
        author: 'Northern Lights',
        name: 'Paper Boats',
        album: 'Harbour',
        lyrics:
            'Capo 2 · Intro: Am  F  C  G\n\n'
            '[Am]We folded every [F]promise into paper boats\n'
            '[C]and let the river [G]carry what we never wrote\n'
            '[Am]the morning found them [F]shining on the stones\n'
            '[C]a hundred little [G]letters coming home\n\n'
            'Chorus:\n'
            '[F]Sail on, [G]sail on\n'
            '[Am]the water knows the [Em]way\n'
            '[F]sail on, [G]sail on\n'
            '[Am]and I will [G]stay\n\n'
            '[Am]The bridge is full of [F]people looking down\n'
            '[C]they count the boats that [G]never touch the ground\n'
            '[Am]and every one is [F]carrying a name\n'
            '[C]and none of them will [G]ever be the same',
      ),
      (
        author: 'Northern Lights',
        name: 'Winter Radio',
        album: 'Harbour',
        lyrics:
            'Static on the kitchen radio\n'
            'a song from somewhere I will never go\n'
            'the snow is falling slower than the beat\n'
            'and you are dancing barefoot on the sheet\n\n'
            'Turn it up, turn it up\n'
            'the night is long enough',
      ),
      (
        author: 'Mira Vale',
        name: 'Glass Garden',
        album: 'Greenhouse',
        lyrics:
            'I planted all my questions in a glass garden\n'
            'and watered them with coffee every day\n'
            'they grew into a forest without answers\n'
            'and that is how I learned to like the shade',
      ),
      (
        author: 'Mira Vale',
        name: 'Slow Train',
        album: 'Greenhouse',
        lyrics:
            'The slow train hums a lullaby of iron\n'
            'the fields roll by like pages of a book\n'
            'I never read the ending of the story\n'
            'I only like the part where people look',
      ),
      (
        author: 'The Quiet Hours',
        name: 'Lanterns',
        album: 'After Dark',
        lyrics:
            'Hang a lantern on the gate\n'
            'so the night will know to wait\n'
            'every window, every street\n'
            'keeps a light for tired feet',
      ),
    ];

/// A tenth of a second of 16-bit mono silence: the demo takes only need files that exist.
Uint8List _silentWav() {
  const int sampleRate = 44100;
  const int samples = sampleRate ~/ 10;
  final ByteData data = ByteData(44 + samples * 2);
  void id(int at, String text) {
    for (int i = 0; i < text.length; i++) {
      data.setUint8(at + i, text.codeUnitAt(i));
    }
  }

  id(0, 'RIFF');
  data.setUint32(4, 36 + samples * 2, Endian.little);
  id(8, 'WAVE');
  id(12, 'fmt ');
  data
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little);
  id(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);
  return data.buffer.asUint8List();
}

/// Adds [demoSongs], practice on 11 of the last 14 days ([sessionSeconds] plus a little more each day), six takes
/// in [storage] and [settings]; the app reads the practice, the takes and the settings when it starts again.
Future<List<Song>> seedDemoData({
  required Directory storage,
  required AppSettings settings,
  int sessionSeconds = 600,
}) async {
  for (final ({String author, String name, String album, String lyrics}) song in demoSongs) {
    await addSongUseCase(author: song.author, name: song.name, album: song.album, lyrics: song.lyrics);
  }
  final List<Song> songs = watchListOfSongsUseCase().value;
  final Box<dynamic> practice = await Hive.openBox<dynamic>('practice_sessions');
  final DateTime today = DateTime.now();
  for (int day = 0; day < 14; day++) {
    if (day % 5 == 4) continue;
    final Song song = songs[day % songs.length];
    final PracticeSessionModel session = PracticeSessionModel(
      id: 'demo-$day',
      songId: song.id,
      startedAt: DateTime(today.year, today.month, today.day - day, 19),
      seconds: sessionSeconds + (day * 437) % 1500,
    );
    await practice.put(session.id, session.toMap());
  }
  final Box<dynamic> recordings = await Hive.openBox<dynamic>('recordings');
  final Directory files = Directory('${storage.path}/recordings')..createSync(recursive: true);
  for (int i = 0; i < 6; i++) {
    final Song song = songs[i % 3];
    final String id = 'demo-take-$i';
    File('${files.path}/${id}_raw.wav').writeAsBytesSync(_silentWav());
    File('${files.path}/${id}_enhanced.wav').writeAsBytesSync(_silentWav());
    final RecordingModel take = RecordingModel(
      id: id,
      songId: song.id,
      recordedAt: DateTime(today.year, today.month, today.day - i * 2, 20, 15 + i * 7),
      durationSeconds: 140.0 + i * 23,
      rawFile: '${id}_raw.wav',
      enhancedFile: '${id}_enhanced.wav',
      keptFromSeconds: 0,
      keptToSeconds: null,
      status: RecordingStatus.enhanced,
      enhanceFailure: null,
      trimSilence: true,
    );
    await recordings.put(id, take.toMap());
  }
  final Box<dynamic> stored = await Hive.openBox<dynamic>('settings');
  await stored.put('app', AppSettingsModel.fromEntity(settings).toMap());
  return songs;
}
