import 'package:flutter/material.dart';

import '../../../../core/domain/result.dart';
import '../../../../core/presentation/theme.dart';
import '../di/song_getters.dart';

import 'package:hitwave.cover/features/song/domain/entities/song.dart';

/// A full page for confirming song deletion.
///
/// Shows the song name and asks for confirmation before deleting.
final class DeleteSongPage extends StatefulWidget {
  /// The [Song] to delete.
  final Song song;

  /// Creates a new [DeleteSongPage].
  const DeleteSongPage({required this.song, super.key});

  @override
  State<DeleteSongPage> createState() => _DeleteSongPageState();
}

class _DeleteSongPageState extends State<DeleteSongPage> {
  static const String _pageTitle = 'Видалити пісню';

  static const String _confirmMessagePrefix = 'Ви дійсно хочете видалити пісню ';

  static const String _questionMark = '?';

  static const String _cancelButtonText = 'Скасувати';

  static const String _deleteButtonText = 'Видалити';

  late final ValueNotifier<bool> isLoading;

  /// Initializes the loading state notifier.
  @override
  void initState() {
    super.initState();
    isLoading = ValueNotifier(false);
  }

  /// Disposes the loading state notifier.
  @override
  void dispose() {
    isLoading.dispose();
    super.dispose();
  }

  Future<void> _deleteSong(BuildContext context, String songId) async {
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

  VoidCallback _onCancel(BuildContext context) {
    return () => Navigator.pop(context);
  }

  /// Builds the delete song page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(_pageTitle),
      ),
      body: Padding(
        padding: EdgeInsets.all(kLargePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('$_confirmMessagePrefix${widget.song.name}$_questionMark'),
            SizedBox(height: kLargePadding),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextButton(
                    onPressed: _onCancel(context),
                    child: const Text(_cancelButtonText),
                  ),
                ),
                SizedBox(width: kStandardPadding),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isLoading,
                    builder: (BuildContext context, bool loading, Widget? child) {
                      return ElevatedButton(
                        onPressed: loading ? null : () => _deleteSong(context, widget.song.id),
                        child: loading
                            ? SizedBox(
                                width: kLoadingIconSize,
                                height: kLoadingIconSize,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(_deleteButtonText),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
