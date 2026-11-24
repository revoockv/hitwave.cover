import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/backup/data/models/backup_data_model.dart';
import 'package:hitwave.cover/features/backup/data/models/backup_song_model.dart';
import 'package:hitwave.cover/features/backup/domain/entities/backup_data.dart';

void main() {
  const BackupSongModel song = BackupSongModel(
    id: 's1',
    author: 'Thorinshield',
    name: 'One Girl',
    lyrics: 'la la',
    coverIds: <String>['c1'],
  );

  test('a backup survives a JSON round trip', () {
    final BackupDataModel model = BackupDataModel(exportedAt: DateTime.utc(2026, 11, 4), songs: <BackupSongModel>[song]);

    final BackupData backup = BackupDataModel.fromJson(model.toJson()).toEntity();

    expect(backup.exportedAt, DateTime.utc(2026, 11, 4));
    expect(backup.songs.single.name, 'One Girl');
    expect(backup.songs.single.covers.single.id, 'c1');
  });

  test('a double-encoded JSON file is unwrapped', () {
    final BackupDataModel model = BackupDataModel(exportedAt: DateTime.utc(2026, 11, 4), songs: <BackupSongModel>[song]);

    final BackupData backup = BackupDataModel.fromJson(jsonEncode(model.toJson())).toEntity();

    expect(backup.songs.single.author, 'Thorinshield');
  });

  test('a backup file of version 1.1 is read with every field of its songs', () {
    const String file =
        '{"version":"1.1","exportedAt":"2026-11-24T14:11:05.559358","songs":[{"id":"s1","author":"Peter And Gordon",'
        '"name":"A World Without Love","album":null,"lyrics":"E\\nPlease lock me away","coverIds":[],'
        '"scrollSpeed":0.7,"leadIn":null,"wideScrollSpeed":null,"wideLeadIn":0.2}]}';

    final BackupSongModel read = BackupDataModel.fromJson(file).songs.single;

    expect(read.name, 'A World Without Love');
    expect(read.scrollSpeed, 0.7);
    expect(read.wideLeadIn, 0.2);
    expect(read.leadIn, isNull);
  });

  test('an indented backup is the same backup', () {
    final BackupDataModel model = BackupDataModel(exportedAt: DateTime.utc(2026, 11, 4), songs: <BackupSongModel>[song]);

    expect(jsonDecode(model.toJson(indent: '  ')), jsonDecode(model.toJson()));
  });
}
