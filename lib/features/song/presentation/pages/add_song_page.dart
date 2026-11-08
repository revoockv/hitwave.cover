import 'package:flutter/material.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/theme.dart';
import '../controllers/song_form_controller.dart';
import '../di/song_getters.dart';
import '../widgets/song_form_widget.dart';

/// A full page for adding a new song.
///
/// Closes after a successful save; on failure stays open and shows the error.
final class AddSongPage extends StatefulWidget {
  /// Creates a new [AddSongPage].
  const AddSongPage({super.key});

  @override
  State<AddSongPage> createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddSongPage> {
  static const String _pageTitle = 'Нова пісня';

  static const String _saveButtonText = 'Додати пісню';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final SongFormController _controller;

  /// Initializes the controller and its text fields.
  @override
  void initState() {
    super.initState();
    _controller = SongFormController();
    _controller.init();
  }

  /// Disposes all controllers and notifiers.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    _controller.isLoading.value = true;

    final Result<void> result = await addSongUseCase(
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

  /// Builds the add song page.
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
