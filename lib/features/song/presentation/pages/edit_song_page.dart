import 'package:flutter/material.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import '../controllers/song_form_controller.dart';
import '../di/song_getters.dart';
import '../widgets/song_form_widget.dart';

/// A full page for editing an existing song.
///
/// The fields start with the current song data. Closes after a successful
/// save; on failure stays open and shows the error.
final class EditSongPage extends StatefulWidget {
  /// The [Song] to edit.
  final Song song;

  /// Creates a new [EditSongPage].
  const EditSongPage({required this.song, super.key});

  @override
  State<EditSongPage> createState() => _EditSongPageState();
}

class _EditSongPageState extends State<EditSongPage> {
  static const String _pageTitle = 'Редагувати пісню';

  static const String _saveButtonText = 'Зберегти зміни';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  Future<void> _onSave() async {
    _controller.isLoading.value = true;

    final Result<void> result = await updateSongUseCase(
      songId: widget.song.id,
      author: _controller.author,
      name: _controller.name,
      album: _controller.album,
      lyrics: _controller.lyrics,
    );

    if (!mounted) return;

    _controller.isLoading.value = false;
    result.when(success: _onSucceeded, failure: _onFailed);
  }

  /// Closes the page after a successful save.
  void _onSucceeded(void _) {
    Navigator.of(context).pop();
  }

  /// Shows the error of a failed save; the entered data stays in the form.
  void _onFailed(String error) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  /// Builds the edit song page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(_pageTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: SongFormWidget(
            controller: _controller,
            formKey: _formKey,
            submitLabel: _saveButtonText,
            isLoading: _controller.isLoading,
            onSubmit: _onSave,
          ),
        ),
      ),
    );
  }
}
