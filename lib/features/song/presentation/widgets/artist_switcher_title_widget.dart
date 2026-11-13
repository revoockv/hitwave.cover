import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import 'artist_picker_widget.dart';

/// App bar title "Artist ▾" that opens a bottom sheet to switch the artist.
///
/// The sheet lists every artist of [songs] with a search field; the chosen
/// one is passed to [onArtistSelected].
final class ArtistSwitcherTitleWidget extends StatelessWidget {
  /// Part of the screen height taken by the sheet.
  static const double _sheetHeightFactor = 0.7;

  /// The title text with the artist name.
  final Widget title;

  /// Songs whose artists are offered.
  final List<Song> songs;

  /// The artist being shown.
  final String selectedArtist;

  /// Called with the artist chosen in the sheet.
  final void Function(String artist) onArtistSelected;

  /// Creates a new [ArtistSwitcherTitleWidget].
  const ArtistSwitcherTitleWidget({
    required this.title,
    required this.songs,
    required this.selectedArtist,
    required this.onArtistSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final Color iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Tooltip(
      message: t.song.otherArtist,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () => _onPressed(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingTiny),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Flexible(child: title),
              Icon(Icons.arrow_drop_down, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onPressed(BuildContext context) async {
    final double height = MediaQuery.sizeOf(context).height * _sheetHeightFactor;
    final String? artist = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext context) => SizedBox(
        height: height,
        child: ArtistPickerWidget(
          songs: songs,
          selectedArtist: selectedArtist,
          onArtistSelected: Navigator.of(context).pop,
        ),
      ),
    );
    if (artist != null) {
      onArtistSelected(artist);
    }
  }
}
