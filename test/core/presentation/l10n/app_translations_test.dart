import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/presentation/l10n/app_translations.dart';

void main() {
  Future<Translations> load(String languageCode) => const TranslationsDelegate().load(Locale(languageCode));

  test('English counts songs with one and other', () async {
    final Translations t = await load('en');

    expect(t.song.songsCount(n: 1), '1 song');
    expect(t.song.songsCount(n: 5), '5 songs');
  });

  test('Interslavic counts songs with the Slavic forms', () async {
    final Translations t = await load('isv');

    expect(t.song.songsCount(n: 1), '1 пєсња');
    expect(t.song.songsCount(n: 21), '21 пєсња');
    expect(t.song.songsCount(n: 3), '3 пєсни');
    expect(t.song.songsCount(n: 24), '24 пєсни');
    expect(t.song.songsCount(n: 5), '5 пєсењ');
    expect(t.song.songsCount(n: 12), '12 пєсењ');
    expect(t.song.songsCount(n: 0), '0 пєсењ');
  });

  test('Interslavic is supported, other languages fall back to English', () {
    expect(const TranslationsDelegate().isSupported(const Locale('isv')), isTrue);
    expect(AppLocaleUtils.supportedLocalesRaw, <String>['en', 'isv']);
  });
}
