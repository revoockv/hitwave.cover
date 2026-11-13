import 'package:flutter/material.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/theme.dart';
import '../controllers/song_form_controller.dart';
import '../di/song_getters.dart';

import 'package:hitwave.cover/features/song/domain/entities/song.dart';

/// A full page for editing an existing song.
///
/// Contains fields for author, name, optional album, and lyrics,
/// pre-populated with the current song data.
final class EditSongPage extends StatefulWidget {
  /// The [Song] to edit.
  final Song song;

  /// Creates a new [EditSongPage].
  const EditSongPage({required this.song, super.key});

  @override
  State<EditSongPage> createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  static const int _lyricsMaxLines = 5;

  static const String _pageTitle = 'Редагувати пісню';

  static const String _authorLabelText = 'Автор';

  static const String _nameLabelText = 'Назва';

  static const String _albumLabelText = "Альбом (необов'язково)";

  static const String _lyricsLabelText = 'Текст пісні';

  static const String _cancelButtonText = 'Скасувати';

  static const String _saveButtonText = 'Зберегти';

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

    Navigator.pop(context);
    result.when(success: _onSucceeded, failure: _onFailed);
  }

  /// Nothing more to do after a successful action: the page is already closed.
  void _onSucceeded(void _) {}

  /// Shows the error of a failed action.
  void _onFailed(String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  VoidCallback _onCancel(BuildContext context) {
    return () => Navigator.pop(context);
  }

  /// Builds the edit song page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(_pageTitle),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _controller.authorController,
                decoration: const InputDecoration(
                  labelText: _authorLabelText,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              TextField(
                controller: _controller.nameController,
                decoration: const InputDecoration(
                  labelText: _nameLabelText,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              TextField(
                controller: _controller.albumController,
                decoration: const InputDecoration(
                  labelText: _albumLabelText,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              TextField(
                controller: _controller.lyricsController,
                maxLines: _lyricsMaxLines,
                decoration: const InputDecoration(
                  labelText: _lyricsLabelText,
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      onPressed: _onCancel(context),
                      child: const Text(_cancelButtonText),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _controller.isLoading,
                      builder: (BuildContext context, bool loading, Widget? child) {
                        return ElevatedButton(
                          onPressed: loading ? null : () => _onSave(context),
                          child: loading
                              ? const SizedBox(
                                  width: AppTheme.loadingIndicatorSize,
                                  height: AppTheme.loadingIndicatorSize,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text(_saveButtonText),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
