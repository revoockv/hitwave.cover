import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/result.dart';
import '../di/song_getters.dart';

import 'package:hitwave.cover/features/song/domain/entities/song.dart';

/// A dialog for editing an existing song.
///
/// Contains fields for author, name, optional album, and lyrics,
/// pre-populated with the current song data.
final class EditSongDialog extends WatchingWidget {
  /// The [Song] to edit.
  final Song song;

  /// Creates a new [EditSongDialog].
  const EditSongDialog({required this.song});

  static const double _padding = 16;

  @override
  Widget build(BuildContext context) {
    final TextEditingController authorController = TextEditingController(text: song.author);
    final TextEditingController nameController = TextEditingController(text: song.name);
    final TextEditingController albumController = TextEditingController(text: song.album);
    final TextEditingController lyricsController = TextEditingController(text: song.lyrics);

    final ValueNotifier<bool> isLoading = ValueNotifier(false);

    return AlertDialog(
      title: const Text('Редагувати пісню'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: 'Автор',
              ),
            ),
            const SizedBox(height: _padding),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Назва',
              ),
            ),
            const SizedBox(height: _padding),
            TextField(
              controller: albumController,
              decoration: const InputDecoration(
                labelText: 'Альбом (необов\'язково)',
              ),
            ),
            const SizedBox(height: _padding),
            TextField(
              controller: lyricsController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Текст пісні',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (BuildContext context, bool loading, Widget? child) {
            return ElevatedButton(
              onPressed: loading ? null : () => _updateSong(context, song.id, authorController.text, nameController.text, albumController.text, lyricsController.text, isLoading),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Зберегти'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _updateSong(
    BuildContext context,
    String songId,
    String author,
    String name,
    String? album,
    String lyrics,
    ValueNotifier<bool> isLoading,
  ) async {
    if (author.isEmpty || name.isEmpty || lyrics.isEmpty) {
      return;
    }

    isLoading.value = true;

    final Result<void> result = await updateSongUseCase(
      songId: songId,
      author: author,
      name: name,
      album: album,
      lyrics: lyrics,
    );

    isLoading.value = false;

    if (result is SuccessResult<void>) {
      Navigator.pop(context);
    } else if (result is FailureResult<void>) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }
}
