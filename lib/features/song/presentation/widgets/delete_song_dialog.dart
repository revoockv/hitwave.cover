import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/result.dart';
import '../di/song_getters.dart';

import 'package:hitwave.cover/features/song/domain/entities/song.dart';

/// A confirmation dialog for deleting a song.
///
/// Shows the song name and asks for confirmation before deleting.
final class _DeleteSongDialog extends WatchingWidget {
  /// The [Song] to delete.
  final Song song;

  /// Creates a new [_DeleteSongDialog].
  const _DeleteSongDialog({required this.song});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isLoading = ValueNotifier(false);

    return AlertDialog(
      title: const Text('Видалити пісню'),
      content: Text('Ви дійсно хочете видалити пісню "${song.name}"?'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Скасувати'),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (BuildContext context, bool loading, Widget? child) {
            return ElevatedButton(
              onPressed: loading ? null : () => _deleteSong(context, song.id, isLoading),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Видалити'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _deleteSong(
    BuildContext context,
    String songId,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;

    final Result<void> result = await deleteSongUseCase.call(songId: songId);

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
