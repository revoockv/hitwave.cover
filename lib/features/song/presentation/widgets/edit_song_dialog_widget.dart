import 'package:flutter/material.dart';

import '../../../../core/domain/result.dart';
import '../controllers/song_form_controller.dart';
import '../di/song_getters.dart';

import 'package:hitwave.cover/features/song/domain/entities/song.dart';

import 'edit_song_cancel_button_widget.dart';
import 'edit_song_save_button_widget.dart';

/// A dialog for editing an existing song.
///
/// Contains fields for author, name, optional album, and lyrics,
/// pre-populated with the current song data.
final class EditSongDialogWidget extends StatefulWidget {

  /// The [Song] to edit.
  final Song song;

  /// Creates a new [EditSongDialogWidget].
  const EditSongDialogWidget({required this.song, super.key});

  @override
  State<EditSongDialogWidget> createState() => _EditSongDialogState();
}

class _EditSongDialogState extends State<EditSongDialogWidget> {
  static const double _fieldPadding = 16;

  static const int _lyricsMaxLines = 5;

  static const String _dialogTitle = 'Редагувати пісню';

  static const String _authorLabelText = 'Автор';

  static const String _nameLabelText = 'Назва';

  static const String _albumLabelText = "Альбом (необов'язково)";

  static const String _lyricsLabelText = 'Текст пісні';

  late final SongFormController _controller;

  /// Initializes the controller with the song data.
  @override
  void initState() {
    super.initState();
    _controller = SongFormController();
    _controller.initEdit(
      author: widget.song.author,
      name: widget.song.name,
      album: widget.song.album,
      lyrics: widget.song.lyrics,
    );
  }

  /// Disposes all controllers and notifiers.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSave(BuildContext context) async {
    final String author = _controller.author;
    final String name = _controller.name;
    final String? album = _controller.album;
    final String lyrics = _controller.lyrics;
    final String songId = widget.song.id;


    if (author.isEmpty || name.isEmpty || lyrics.isEmpty) {
      return;
    }


    _controller.isLoading.value = true;

    final Result<void> result = await updateSongUseCase(
      songId: songId,
      author: author,
      name: name,
      album: album,
      lyrics: lyrics,
    );


    if (mounted) {
      _controller.isLoading.value = false;
    }

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

  /// Builds the edit song dialog.
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(_dialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _controller.authorController,
              decoration: const InputDecoration(
                labelText: _authorLabelText,
              ),
            ),
            SizedBox(height: _fieldPadding),
            TextField(
              controller: _controller.nameController,
              decoration: const InputDecoration(
                labelText: _nameLabelText,
              ),
            ),
            SizedBox(height: _fieldPadding),
            TextField(
              controller: _controller.albumController,
              decoration: const InputDecoration(
                labelText: _albumLabelText,
              ),
            ),
            SizedBox(height: _fieldPadding),
            TextField(
              controller: _controller.lyricsController,
              maxLines: _lyricsMaxLines,
              decoration: const InputDecoration(
                labelText: _lyricsLabelText,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        const EditSongCancelButtonWidget(),
        EditSongSaveButtonWidget(
          isLoading: _controller.isLoading,
          onPressed: () => _onSave(context),
        ),
      ],
    );
  }
}
