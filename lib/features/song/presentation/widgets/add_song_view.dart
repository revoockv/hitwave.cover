import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/result.dart';
import '../di/song_getters.dart';

/// A dialog for adding a new song.
///
/// Contains fields for author, name, optional album, and lyrics.
final class AddSongView extends WatchingWidget {
  /// Creates a new [AddSongView].
  const AddSongView({super.key});

  static const double _padding = 16;

  @override
  Widget build(BuildContext context) {
    final TextEditingController authorController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController albumController = TextEditingController();
    final TextEditingController lyricsController = TextEditingController();

    final ValueNotifier<bool> isLoading = ValueNotifier(false);

    return AlertDialog(
      title: const Text('Додати пісню'),
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
              onPressed: loading ? null : () => _addSong(context, authorController.text, nameController.text, albumController.text, lyricsController.text, isLoading),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Додати'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _addSong(
    BuildContext context,
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

    final Result result = await addSongUseCase(
      author: author,
      name: name,
      album: album,
      lyrics: lyrics,
    );

    isLoading.value = false;
    if (result.isSuccess) {
      Navigator.pop(context);
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
    }
  }
}
