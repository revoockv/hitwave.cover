import 'package:flutter/material.dart';

import '../../../../core/domain/result.dart';
import '../../../../core/presentation/theme.dart';
import '../di/song_getters.dart';

import 'package:hitwave.cover/features/song/domain/entities/song.dart';

/// A confirmation dialog for deleting a song.
///
/// Shows the song name and asks for confirmation before deleting.
final class DeleteSongDialogWidget extends StatefulWidget {
  /// The [Song] to delete.
  final Song song;

  /// Creates a new [DeleteSongDialogWidget].
  const DeleteSongDialogWidget({required this.song, super.key});

  @override
  State<DeleteSongDialogWidget> createState() => _DeleteSongDialogState();
}

class _DeleteSongDialogState extends State<DeleteSongDialogWidget> {
  /// Dialog title text.
  static const String _dialogTitle = 'Видалити пісню';

  /// Confirmation prompt text (without song name and question mark).
  static const String _confirmationPrompt = 'Ви дійсно хочете видалити пісню ';

  /// Question mark suffix for confirmation prompt.
  static const String _questionMark = '?';

  /// Cancel button text.
  static const String _cancelButtonText = 'Скасувати';

  /// Delete button text.
  static const String _deleteButtonText = 'Видалити';

  late final ValueNotifier<bool> isLoading;

  @override
  void initState() {
    super.initState();
    isLoading = ValueNotifier(false);
  }

  @override
  void dispose() {
    isLoading.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_dialogTitle),
      content: Text('$_confirmationPrompt${widget.song.name}$_questionMark'),
      actions: <Widget>[
        TextButton(
          onPressed: () => _handleCancel(context),
          child: Text(_cancelButtonText),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (BuildContext context, bool loading, Widget? child) {
            return ElevatedButton(
              onPressed: loading ? null : () => _deleteSong(context, widget.song.id, isLoading),
              child: loading
                  ? const SizedBox(
                      width: kLoadingIconSize,
                      height: kLoadingIconSize,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_deleteButtonText),
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

    final Result<void> result = await deleteSongUseCase(songId: songId);


    isLoading.value = false;

    if (!context.mounted) return;

    if (result.isSuccess) {
      Navigator.pop(context);
    } else {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage!)),
      );
    }
  }

  void _handleCancel(BuildContext context) {
    Navigator.pop(context);
  }
}
