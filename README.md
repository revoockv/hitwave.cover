# Hitwave Cover

**English** · [Меджусловјанскы](README.isv.md)

Hitwave Cover keeps your song lyrics and your cover recordings in one place. Open a song, let the
lyrics scroll at your pace, sing along and record a take — the app cleans up the sound on the
device, keeps every take next to its song and counts how much you practice.

Built with Flutter for Android, iOS, macOS, Windows, Linux and the web.

## Features

### Songs and lyrics
- A library of songs with artist, title, album and lyrics: add, edit and delete them.
- Search by song or artist; sort by artists, A–Z, recently opened or by the number of covers.
- The lyrics page scrolls the text by itself. The speed and the lead-in before the first line are
  remembered for every song.

### Recording covers
- Tick **Record** and press **Start**: the take is recorded while the lyrics scroll.
- Choose the microphone; the app warns about a silent take.
- **Vocal enhancement** runs on the device in embedded Python: it removes rumble and steady noise,
  evens out the loudness and, optionally, trims the silence before and after the singing. The
  original and the enhanced take are both kept.
- Listen to the takes, share one as MP3 (with a ready caption) or show it in its folder.
- **My covers**: every take of every song in one list, with search.

### Practice
- The time spent with each song is counted on its own.
- Statistics: today, this week and this month, the day streak, the number of takes, a month
  calendar of practice days and the most practiced songs.
- The home tab shows the recently opened songs and the recently played covers.

### Accounts, sync and backup
- Sign in with an email and a password (Firebase) to keep the songs in the cloud, or continue
  without an account and keep them only on the device. Songs of a guest can move into an account
  later.
- **Sync between devices** over the local Wi‑Fi network: one device shows a QR code, the other
  scans it. Songs, covers, practice and history are merged; nothing is deleted without asking —
  the app shows the differences and lets you choose what to do on both devices.
- **Backup**: export the songs to a file and import them back; with the takes, the file is a
  ZIP archive.

### Settings
- **Language**: English (default) or Interslavic (Medžuslovjansky, written in Cyrillic).
- **Theme**: light or dark glass, light or dark neumorphism.
- **Accent color**: one of eight.

## Getting started

Requirements: Flutter (Dart `^3.12`); Xcode for iOS and macOS, Android Studio for Android.

```bash
flutter pub get
flutter run                          # Android, iOS, macOS: the build packages Python itself
tool/flutter_python.sh windows run   # Windows and Linux: package Python, then run
```

Vocal enhancement needs the embedded Python of `python/` (see [python/README.md](python/README.md)).
The web build has no embedded Python and no sync between devices: there the app keeps the
songs and the lyrics without vocal enhancement.

Firebase is configured in `firebase.json`; without an account the app works fully offline.

## Development

- **Architecture**: clean architecture by the `revoockv-original@2.0.0` template (see
  `.clean_arch.toml`): every feature in `lib/features/<feature>/` has `data`, `domain` and
  `presentation` layers; state lives in repositories as `ValueNotifier` and reaches the UI through
  use cases and `watch_it`; dependencies are registered with GetIt.
- **Errors**: operations return `Result<T, F>`, where `F` is the failure enum of the feature; its
  text is chosen in `presentation/l10n/`.
- **Translations**: [slang](https://pub.dev/packages/slang). The texts are in
  `lib/core/presentation/l10n/en.i18n.json` and `isv.i18n.json`; after changing them run
  `dart run slang`.
- **Themes**: `lib/core/presentation/theme.dart` builds the theme of a style, a brightness and an
  accent; `SurfaceWidget` draws glass or neumorphic panels.
- **Storage**: Hive on the device, Cloud Firestore for signed-in users.

```bash
flutter analyze
flutter test --concurrency=1
```

Git: `develop` collects the work; every change has its own branch — `feature/NNN-name`,
`fix/NNN-name`, `refactor/NNN-name`, `docs/NNN-name` — with commits `[TYPE-NNN] …`, merged into
`develop` with `--no-ff`.
