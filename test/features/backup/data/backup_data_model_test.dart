import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/backup/data/models/backup_data_model.dart';
import 'package:hitwave.cover/features/backup/domain/entities/backup_data.dart';

void main() {
  final Map<String, dynamic> song = <String, dynamic>{
    'id': 's1',
    'author': 'Thorinshield',
    'name': 'One Girl',
    'album': null,
    'lyrics': 'la la',
    'coverIds': <String>['c1'],
  };

  test('a backup survives a JSON round trip', () {
    final BackupDataModel model = BackupDataModel(exportedAt: DateTime.utc(2026, 11, 4), songs: <Map<String, dynamic>>[song]);

    final BackupData backup = BackupDataModel.fromJson(model.toJson()).toEntity();

    expect(backup.exportedAt, DateTime.utc(2026, 11, 4));
    expect(backup.songs.single.name, 'One Girl');
    expect(backup.songs.single.covers.single.id, 'c1');
  });

  test('a double-encoded JSON file is unwrapped', () {
    final BackupDataModel model = BackupDataModel(exportedAt: DateTime.utc(2026, 11, 4), songs: <Map<String, dynamic>>[song]);

    final BackupData backup = BackupDataModel.fromJson(jsonEncode(model.toJson())).toEntity();

    expect(backup.songs.single.author, 'Thorinshield');
  });
}
