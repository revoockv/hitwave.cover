import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/song_sort.dart';
import '../widgets/artist_picker_widget.dart';
import '../widgets/delete_song_dialog_widget.dart';
import '../widgets/song_form_widget.dart';
import '../widgets/song_tile_widget.dart';
import '../widgets/songs_tab_widget.dart';
import '../widgets/songs_widget.dart';

/// The texts of the song widgets in the language of these [Translations]: the pages and wrappers build them, the
/// dumb widgets only show them.
extension SongWidgetTexts on Translations {
  /// The texts of a song tile.
  SongTileTexts get songTile => SongTileTexts(
    coversTooltip: song.coversTooltip,
    actionsTooltip: song.actions,
    editLabel: song.edit,
    deleteLabel: common.delete,
  );

  /// The texts of the artist list.
  ArtistPickerTexts get artistPicker => ArtistPickerTexts(
    searchHintText: song.artistSearch,
    clearTooltip: common.clear,
    nothingFoundText: common.nothingFound,
    songCountText: _songCount,
  );

  /// The texts of the songs tab and its lists.
  SongListTexts get songList => SongListTexts(
    tile: songTile,
    empty: EmptySongsTexts(titleText: song.noSongsTitle, messageText: song.noSongsMessage, addLabel: song.addSong),
    picker: artistPicker,
    searchHintText: song.searchSongs,
    clearTooltip: common.clear,
    nothingFoundText: common.nothingFound,
    sortLabelOf: _sortLabel,
  );

  /// The texts of the song form.
  SongFormTexts get songForm => SongFormTexts(
    artistLabel: song.artist,
    songNameLabel: song.songName,
    albumLabel: song.album,
    optionalText: song.optional,
    lyricsLabel: song.lyrics,
    requiredText: song.required,
  );

  /// The texts of the dialog that deletes the song [songName].
  DeleteSongDialogTexts deleteSongDialog(String songName) => DeleteSongDialogTexts(
    titleText: song.deleteTitle,
    messageText: song.deleteMessage(name: songName),
    cancelLabel: common.cancel,
    deleteLabel: common.delete,
  );

  String _songCount(int count) => song.songsCount(n: count);

  String _sortLabel(SongSort sort) => switch (sort) {
    SongSort.artists => song.sort.artists,
    SongSort.name => song.sort.name,
    SongSort.recent => song.sort.recent,
    SongSort.covers => song.sort.covers,
  };
}
