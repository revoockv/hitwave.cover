///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsIsv extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsIsv({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.isv,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <isv>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsIsv _root = this; // ignore: unused_field

	@override 
	TranslationsIsv $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsIsv(meta: meta ?? this.$meta);

	// Translations
	@override String get appTitle => 'Hitwave Cover';
	@override late final _Translations$backup$isv backup = _Translations$backup$isv._(_root);
	@override late final _Translations$common$isv common = _Translations$common$isv._(_root);
	@override late final _Translations$history$isv history = _Translations$history$isv._(_root);
	@override late final _Translations$practice$isv practice = _Translations$practice$isv._(_root);
	@override late final _Translations$recordings$isv recordings = _Translations$recordings$isv._(_root);
	@override late final _Translations$settings$isv settings = _Translations$settings$isv._(_root);
	@override late final _Translations$song$isv song = _Translations$song$isv._(_root);
	@override late final _Translations$sync$isv sync = _Translations$sync$isv._(_root);
	@override late final _Translations$tuner$isv tuner = _Translations$tuner$isv._(_root);
	@override late final _Translations$vocalEnhance$isv vocalEnhance = _Translations$vocalEnhance$isv._(_root);
}

// Path: backup
class _Translations$backup$isv extends Translations$backup$en {
	_Translations$backup$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get cancelImport => 'Отменити импорт';
	@override String conflictMessage({required Object song}) => '«${song}» уж јест међу вашими пєснями.';
	@override String get conflictTitle => 'Та пєсња уж јест';
	@override String get exportDialogTitle => 'Изберите папку за експорт';
	@override late final _Translations$backup$failure$isv failure = _Translations$backup$failure$isv._(_root);
	@override String forOthers({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n,
		few: 'Сдєлати то само за друге ${n} пєсни',
		many: 'Сдєлати то само за другых ${n} пєсниј',
		one: 'Сдєлати то само за другу ${n} пєсњу',
		other: 'Сдєлати то само за другых ${n} пєсниј',
	);
	@override String get importHint => 'Из фајла, такоже из Google Drive';
	@override String importSummary({required Object added, required Object replaced, required Object skipped}) => 'Импорт кончены: додано ${added}, замєнено ${replaced}, прескочено ${skipped}';
	@override String get includeRecordings => 'Вкључити записы';
	@override String get keepBoth => 'Оставити обе';
	@override String get keepBothHint => 'Додати пєсњу из фајла поред вашеј, с числом';
	@override String get otherLyrics => 'Текст в фајлу јест другы.';
	@override String get recordingsNote => 'Записы сут храњене само на том устројству; с ними фајл стање ZIP-архивом.';
	@override String get replace => 'Замєнити';
	@override String get replaceHint => 'Взяти текст из фајла; ваши каверы и записы остајут';
	@override String get sameLyrics => 'Текст в фајлу јест једнаки.';
	@override String get share => 'Поделити резервну копију';
	@override String get shareHint => 'Сохраните ју в Google Drive или пошљите в другу апликацију';
	@override String get shareQuestion => 'Пєсни будут подељене како фајл, кторы можете сохранити в Google Drive. Записы идут само в ZIP-архиву.';
	@override String get skip => 'Прескочити';
	@override String get skipHint => 'Оставити вашу како јест';
}

// Path: common
class _Translations$common$isv extends Translations$common$en {
	_Translations$common$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Отмєнити';
	@override String get clear => 'Очистити';
	@override String get delete => 'Избрисати';
	@override String get nothingFound => 'Ничто не најдено.';
	@override String get songDeleted => 'Пєсња избрисана';
}

// Path: history
class _Translations$history$isv extends Translations$history$en {
	_Translations$history$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override late final _Translations$history$failure$isv failure = _Translations$history$failure$isv._(_root);
}

// Path: practice
class _Translations$practice$isv extends Translations$practice$en {
	_Translations$practice$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get allStats => 'Вса статистика';
	@override String get clearFailed => 'Не удало се очистити тренингы';
	@override String get covers => 'Каверы';
	@override String get dayStreak => 'Серија дниј';
	@override String days({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n,
		one: '${n} дењ',
		few: '${n} дни',
		many: '${n} дниј',
		other: '${n} дниј',
	);
	@override String get deleteFailed => 'Не удало се избрисати тренинг';
	@override String get deleteMessage => 'Он буде одстранены из статистики.';
	@override String deleteTakes({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n,
		one: 'Такоже избрисати ${n} запис',
		few: 'Такоже избрисати ${n} записы',
		many: 'Такоже избрисати ${n} записов',
		other: 'Такоже избрисати ${n} записов',
	);
	@override String get deleteTitle => 'Избрисати тот тренинг?';
	@override String get filterAll => 'Вся';
	@override String get filterPracticeOnly => 'Само тренинги';
	@override String get filterWithTakes => 'С записами';
	@override String hoursMinutes({required Object hours, required Object minutes}) => '${hours} ч ${minutes} мин';
	@override String get importFailed => 'Не удало се додати тренингы';
	@override String get lessThanMinute => 'мење од минуты';
	@override String longest({required Object value}) => 'рекорд ${value}';
	@override String minutes({required Object minutes}) => '${minutes} мин';
	@override List<String> get monthNames => [
		'Јануар',
		'Фебруар',
		'Марец',
		'Април',
		'Мај',
		'Јуниј',
		'Јулиј',
		'Август',
		'Септембр',
		'Октобр',
		'Новембр',
		'Децембр',
	];
	@override String get nextMonth => 'Слєдујучи мєсец';
	@override String get noPracticeThisDay => 'Того дња не было тренинга.';
	@override String get noPracticeYet => 'Јешче нема тренингов. Отворите пєсњу и притисните «Старт».';
	@override String get previousMonth => 'Прєдходны мєсец';
	@override String get saveFailed => 'Не удало се сохранити тренинг';
	@override String sessions({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n,
		one: '${n} тренинг',
		few: '${n} тренингы',
		many: '${n} тренингов',
		other: '${n} тренингов',
	);
	@override String get streak => 'Серија';
	@override String get takes => 'Записы';
	@override String takesCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n,
		one: '${n} запис',
		few: '${n} записы',
		many: '${n} записов',
		other: '${n} записов',
	);
	@override String get thisMonth => 'Тутој мєсец';
	@override String get thisWeek => 'Тутој тыдењ';
	@override String get today => 'Днес';
	@override String get topSongs => 'Најчестєјше';
	@override String get total => 'Всего';
	@override String get week => 'Тыдењ';
	@override List<String> get weekdayLetters => [
		'П',
		'У',
		'С',
		'Ч',
		'П',
		'С',
		'Н',
	];
	@override List<String> get weekdayNames => [
		'Пон',
		'Уто',
		'Сре',
		'Чет',
		'Пет',
		'Соб',
		'Нед',
	];
}

// Path: recordings
class _Translations$recordings$isv extends Translations$recordings$en {
	_Translations$recordings$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get captionCopied => 'Опис скопированы — вставите его (⌘V) како подпис к фајлу.';
	@override String get deleteMessage => 'Оригинал и улєпшены фајл будут избрисане с устројства.';
	@override String get deleteTitle => 'Избрисати запис?';
	@override late final _Translations$recordings$enhanceFailure$isv enhanceFailure = _Translations$recordings$enhanceFailure$isv._(_root);
	@override String get enhanceNow => 'Улєпшити';
	@override String get enhanced => 'Улєпшены';
	@override String get enhancing => 'Улєпшају…';
	@override late final _Translations$recordings$failure$isv failure = _Translations$recordings$failure$isv._(_root);
	@override String get microphoneHint => 'Ако слушалкы сут подкључене к гнєзду, система може записывати из них. Изберите вбудованы микрофон.';
	@override String get microphoneTitle => 'Микрофон';
	@override String get noCovers => 'Јешче нема каверов. Отворите пєсњу, означите «Запис» и притисните «Старт».';
	@override String get noTakes => 'Јешче нема записов. Означите «Запис» и притисните «Старт».';
	@override String get notEnhanced => 'Не улєпшено';
	@override String get original => 'Оригинал';
	@override String get pause => 'Пауза';
	@override String get play => 'Слушати';
	@override String get preparingMp3 => 'Приправјају MP3…';
	@override String get retry => 'Улєпшити јешче раз';
	@override String get share => 'Послати';
	@override String get showInFolder => 'Показати в папке';
	@override String get silent => 'Без звука — провєрите микрофон';
	@override String get systemMicrophone => 'Како в системє';
	@override String get title => 'Записы';
}

// Path: settings
class _Translations$settings$isv extends Translations$settings$en {
	_Translations$settings$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get accentColor => 'Акцентна барва';
	@override String get clear => 'Очистити';
	@override String get clearCovers => 'Каверы';
	@override String get clearData => 'Очистити дане';
	@override String get clearHistory => 'Недавно отворене и слушане';
	@override String get clearMessage => 'Изберите, что избрисати. То не можно вратити.';
	@override String get clearPractice => 'Статистика тренингов';
	@override String get clearSongs => 'Пєсни и јих каверы';
	@override String get clearTitle => 'Очистити дане?';
	@override String get cleared => 'Дане очишчене';
	@override late final _Translations$settings$colors$isv colors = _Translations$settings$colors$isv._(_root);
	@override String get data => 'Дане';
	@override String get language => 'Језык';
	@override String get open => 'Наставјења';
	@override String get saveFailed => 'Не удало се сохранити наставјења';
	@override String get theme => 'Тема';
	@override late final _Translations$settings$themes$isv themes = _Translations$settings$themes$isv._(_root);
	@override String get title => 'Наставјења';
}

// Path: song
class _Translations$song$isv extends Translations$song$en {
	_Translations$song$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get actions => 'Дєјствија';
	@override String get add => 'Додати';
	@override String get addSong => 'Додати пєсњу';
	@override String get album => 'Албум';
	@override String get all => 'Все';
	@override String get allArtists => 'Вси изполнитељи';
	@override String get artist => 'Изполнитељ';
	@override String get artistSearch => 'Искати изполнитеља';
	@override String get coverSearch => 'Искати каверы по пєсњи';
	@override String get coversTooltip => 'Каверы';
	@override String deleteMessage({required Object name}) => 'Пєсња «${name}» буде избрисана навсегда.';
	@override String get deleteTitle => 'Избрисати пєсњу?';
	@override String get edit => 'Уредити';
	@override String get editSong => 'Уредити пєсњу';
	@override String get exportDone => 'Експорт кончены';
	@override String get exportQuestion => 'Пєсни будут сохрањене в фајл в избраној папке.';
	@override String get exportSongs => 'Експортовати';
	@override late final _Translations$song$failure$isv failure = _Translations$song$failure$isv._(_root);
	@override String get importQuestion => 'Пєсни из фајла будут додане к вашим; за пєсњу, ктору уж имате, изберете, что сдєлати. Записы приходјат само из ZIP-архива.';
	@override String get importSongs => 'Импортовати';
	@override String get leadIn => 'Отступ';
	@override String get lyrics => 'Текст пєсњи';
	@override String microphone({required Object name}) => 'Микрофон: ${name}';
	@override String get myCovers => 'Моје каверы';
	@override String get mySongs => 'Моје пєсни';
	@override String get newSong => 'Нова пєсња';
	@override String get noRecentCovers => 'Послушајте свој кавер — он појави се ту.';
	@override String get noRecentSongs => 'Отворите пєсњу — она појави се ту.';
	@override String get noSongsMessage => 'Додајте прву пєсњу или импортујте резервну копију.';
	@override String get noSongsTitle => 'Јешче нема пєснеј';
	@override String get optional => 'Необвезно';
	@override String get otherArtist => 'Другы изполнитељ';
	@override String get pause => 'Пауза';
	@override String get recentlyOpened => 'Недавно отворене';
	@override String get recentlyPlayed => 'Недавно слушане каверы';
	@override String get record => 'Запис';
	@override String get required => 'Наполните то поље';
	@override String get saveChanges => 'Сохранити измєны';
	@override String get searchSongs => 'Искати пєсни или изполнитељев';
	@override String get silentTake => 'Запис без звука. Провєрите микрофон (кнопка с микрофоном на панелу).';
	@override String get songName => 'Назва пєсњи';
	@override String songsCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n,
		one: '${n} пєсња',
		few: '${n} пєсни',
		many: '${n} пєсењ',
		other: '${n} пєсењ',
	);
	@override late final _Translations$song$sort$isv sort = _Translations$song$sort$isv._(_root);
	@override String get speed => 'Скорост';
	@override String get start => 'Старт';
	@override String get statistics => 'Статистика';
	@override String get stopRecording => 'Зауставити запис';
	@override String get sync => 'Синхронизација';
	@override String get tabCovers => 'Каверы';
	@override String get tabHome => 'Дом';
	@override String get tabSongs => 'Пєсни';
	@override String get takeSaved => 'Запис сохрањены';
	@override String get trimSilence => 'Обрєзати тишину';
}

// Path: sync
class _Translations$sync$isv extends Translations$sync$en {
	_Translations$sync$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get all => 'Все';
	@override String get anotherDevice => 'Друго устројство';
	@override String applyChosen({required Object n}) => 'Синхронизовати означене (${n})';
	@override late final _Translations$sync$badge$isv badge = _Translations$sync$badge$isv._(_root);
	@override String get codeCopied => 'Код скопированы';
	@override String get connect => 'Подкључити се';
	@override String get copyCode => 'Копировати код';
	@override String coverTitle({required Object song, required Object date}) => 'Кавер «${song}» од ${date}';
	@override String coversCount({required Object n}) => 'каверы: ${n}';
	@override String deletedCount({required Object n}) => 'избрисано: ${n}';
	@override String deletedHereAt({required Object date, required Object time}) => 'Избрисано ту ${date} в ${time}';
	@override String deletedThereAt({required Object date, required Object time}) => 'Избрисано на другом устројству ${date} в ${time}';
	@override String deletedThereAtDevice({required Object device, required Object date, required Object time}) => 'Избрисано на «${device}» ${date} в ${time}';
	@override late final _Translations$sync$difference$isv difference = _Translations$sync$difference$isv._(_root);
	@override String differs({required Object list}) => 'Различаје се: ${list}';
	@override String get done => 'Готово';
	@override late final _Translations$sync$failure$isv failure = _Translations$sync$failure$isv._(_root);
	@override String get goneSong => 'пєсња, кторој уж нема';
	@override String get intro => 'Пренесите пєсни, каверы, тренингы и историју меџу устројствами. Прєд каждой измєной видите все измєны за оба устројства, додавања и избрисања, и означајете те, ктоже треба внести.';
	@override String get orPaste => 'или вставите код из другого устројства';
	@override String peerStep({required Object device, required Object step}) => '${device}: ${step}';
	@override String peerStopped({required Object device, required Object reason}) => '${device} зауставил синхронизацију: ${reason}';
	@override String practiceItem({required Object n}) => 'Тренингы: ${n}';
	@override String get qrHint => 'На другом устројству отворите «Синхронизација» → «Скановати QR-код». Оба устројства мора быти в једној сети Wi‑Fi.';
	@override String get received => 'Додано ту';
	@override String get restoredHere => 'Было избрисано на том устројству';
	@override String restoredThere({required Object device}) => 'Было избрисано на «${device}»';
	@override String get reviewMessage => 'Внесене будут само означене измєны. Неозначене остају, как сут, на обох устројствах и будут понуђене опет в следујучи раз.';
	@override String get reviewTitle => 'Изберите, что синхронизовати';
	@override String get scanQr => 'Скановати QR-код';
	@override String get scanTitle => 'Сканујте QR-код';
	@override String get sent => 'Додано на друго устројство';
	@override String sessionsCount({required Object n}) => 'тренингы: ${n}';
	@override String get showQr => 'Показати QR-код';
	@override String songItem({required Object song}) => 'Пєсња «${song}»';
	@override String songsCount({required Object n}) => 'пєсни: ${n}';
	@override late final _Translations$sync$step$isv step = _Translations$sync$step$isv._(_root);
	@override String get synced => 'Синхронизовано';
	@override String get title => 'Синхронизација';
	@override String toHere({required Object device}) => 'Из «${device}» на то устројство';
	@override String toThere({required Object device}) => 'Из того устројства на «${device}»';
	@override String updateHere({required Object list, required Object device}) => 'Береје ${list} из «${device}»';
	@override String updateThere({required Object device, required Object list}) => '«${device}» береје ${list} из того устројства';
	@override String updatedCount({required Object n}) => 'обновјено: ${n}';
	@override String get waiting => 'Чакају, докле друго устројство сканује код…';
	@override String withCovers({required Object n}) => 'с каверами: ${n}';
}

// Path: tuner
class _Translations$tuner$isv extends Translations$tuner$en {
	_Translations$tuner$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get title => 'Тюнер';
	@override String get open => 'Настроити инструмент';
	@override String get playString => 'Заиграј на струнє';
	@override String get inTune => 'Настроено';
	@override String get tuneUp => 'Натягни выше';
	@override String get tuneDown => 'Отпусти ниже';
	@override String hertz({required Object value}) => '${value} Hz';
	@override String cents({required Object value}) => '${value} центов';
	@override String get retry => 'Попробовати знову';
	@override late final _Translations$tuner$instruments$isv instruments = _Translations$tuner$instruments$isv._(_root);
	@override late final _Translations$tuner$failure$isv failure = _Translations$tuner$failure$isv._(_root);
}

// Path: vocalEnhance
class _Translations$vocalEnhance$isv extends Translations$vocalEnhance$en {
	_Translations$vocalEnhance$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override late final _Translations$vocalEnhance$failure$isv failure = _Translations$vocalEnhance$failure$isv._(_root);
}

// Path: backup.failure
class _Translations$backup$failure$isv extends Translations$backup$failure$en {
	_Translations$backup$failure$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get exportSongs => 'Не удало се експортовати пєсни';
	@override String get importSongs => 'Не удало се импортовати пєсни';
	@override String get shareBackup => 'Не удало се поделити резервну копију';
}

// Path: history.failure
class _Translations$history$failure$isv extends Translations$history$failure$en {
	_Translations$history$failure$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get clear => 'Не удало се очистити историју';
	@override String get save => 'Не удало се запомнити историју';
}

// Path: recordings.enhanceFailure
class _Translations$recordings$enhanceFailure$isv extends Translations$recordings$enhanceFailure$en {
	_Translations$recordings$enhanceFailure$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get failed => 'Не удало се улєпшити запис';
	@override String get interrupted => 'Улєпшење было прєрвано — пустите его јешче раз';
	@override String get unavailable => 'Улєпшење звука не јест доступно на тој платформє';
}

// Path: recordings.failure
class _Translations$recordings$failure$isv extends Translations$recordings$failure$en {
	_Translations$recordings$failure$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get busy => 'Запис уже иде';
	@override String get delete => 'Не удало се избрисати запис';
	@override String get fileMissing => 'Фајл записа не најден';
	@override String get importRecordings => 'Не удало се додати записы из архива';
	@override String get listMicrophones => 'Не удало се достати спис микрофонов';
	@override String get microphonePermission => 'Нема доступа к микрофону. Дозволите его в наставјењах.';
	@override String get notFound => 'Запис не најден';
	@override String get notRecording => 'Запис не иде';
	@override String get play => 'Не удало се пустити запис';
	@override String get save => 'Не удало се сохранити запис';
	@override String get savePreferences => 'Не удало се запомнити наставјења записа';
	@override String get share => 'Не удало се послати запис';
	@override String get showInFolder => 'Не удало се отворити папку';
	@override String get start => 'Не удало се начети запис';
}

// Path: settings.colors
class _Translations$settings$colors$isv extends Translations$settings$colors$en {
	_Translations$settings$colors$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get blue => 'Сиња';
	@override String get green => 'Зелена';
	@override String get indigo => 'Индиго';
	@override String get orange => 'Оранжева';
	@override String get pink => 'Ружова';
	@override String get red => 'Чрвена';
	@override String get teal => 'Морска';
	@override String get violet => 'Фиолетова';
}

// Path: settings.themes
class _Translations$settings$themes$isv extends Translations$settings$themes$en {
	_Translations$settings$themes$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get glassDark => 'Темно стекло';
	@override String get glassLight => 'Свєтло стекло';
	@override String get neumorphicDark => 'Темны неуморфизм';
	@override String get neumorphicLight => 'Свєтлы неуморфизм';
}

// Path: song.failure
class _Translations$song$failure$isv extends Translations$song$failure$en {
	_Translations$song$failure$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get addCover => 'Не удало се додати кавер.';
	@override String get addSong => 'Не удало се додати пєсњу.';
	@override String get addSongs => 'Не удало се додати пєсни.';
	@override String get deleteCover => 'Не удало се избрисати кавер.';
	@override String get deleteSong => 'Не удало се избрисати пєсњу.';
	@override String get updateCover => 'Не удало се обновити кавер.';
	@override String get updateLeadIn => 'Не удало се сохранити отступ.';
	@override String get updateLyrics => 'Не удало се сохранити текст.';
	@override String get updateSong => 'Не удало се обновити пєсњу.';
	@override String get updateSpeed => 'Не удало се сохранити скорост.';
}

// Path: song.sort
class _Translations$song$sort$isv extends Translations$song$sort$en {
	_Translations$song$sort$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get artists => 'Изполнитељи';
	@override String get covers => 'Каверы';
	@override String get name => 'А–Ж';
	@override String get recent => 'Недавне';
}

// Path: sync.badge
class _Translations$sync$badge$isv extends Translations$sync$badge$en {
	_Translations$sync$badge$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get add => 'Додати';
	@override String get restore => 'Вернути';
	@override String get delete => 'Избрисати';
	@override String get update => 'Измєнити';
}

// Path: sync.difference
class _Translations$sync$difference$isv extends Translations$sync$difference$en {
	_Translations$sync$difference$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get album => 'албум';
	@override String get lyrics => 'текст';
}

// Path: sync.failure
class _Translations$sync$failure$isv extends Translations$sync$failure$en {
	_Translations$sync$failure$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get busy => 'Синхронизација уже иде';
	@override String get cancelled => 'Отмєњено';
	@override String get connect => 'Не удало се подкључити к устројству. Провєрите, же оба сут в једној сети Wi‑Fi.';
	@override String get emptyCode => 'Впишите или сканујте код';
	@override String get host => 'Не удало се начети синхронизацију';
	@override String get interrupted => 'Синхронизација прєрвала се';
	@override String get noNetwork => 'Нема повезања с сетју. Подкључите се к Wi‑Fi.';
	@override String get notACode => 'То не јест код синхронизације Hitwave Cover';
	@override String get nothingWaits => 'Нема синхронизације, ктора чака на рєшења';
	@override String get peerStopped => 'Друго устројство зауставило синхронизацију';
}

// Path: sync.step
class _Translations$sync$step$isv extends Translations$sync$step$en {
	_Translations$sync$step$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get applying => 'Примењају рєшења…';
	@override String get choosing => 'избира, что дєлати с различијами…';
	@override String get connecting => 'Подкључају се…';
	@override String downloading({required Object done, required Object total}) => 'Скачивају каверы ${done} из ${total}';
	@override String get joined => 'подкључило се, обмєњајемо дане…';
	@override String get merging => 'Сједињају дане…';
	@override String get reading => 'Достају спис пєснеј и каверов…';
	@override String uploading({required Object done, required Object total}) => 'Посылају каверы ${done} из ${total}';
}

// Path: tuner.instruments
class _Translations$tuner$instruments$isv extends Translations$tuner$instruments$en {
	_Translations$tuner$instruments$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get guitar => 'Гитара';
	@override String get ukulele => 'Укулеле';
	@override String get bass => 'Бас';
	@override String get violin => 'Скрипка';
	@override String get chromatic => 'Хроматичны';
}

// Path: tuner.failure
class _Translations$tuner$failure$isv extends Translations$tuner$failure$en {
	_Translations$tuner$failure$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get microphonePermission => 'Дозволи микрофон, да бы користати тюнер.';
	@override String get start => 'Не јест возможно отворити микрофон.';
}

// Path: vocalEnhance.failure
class _Translations$vocalEnhance$failure$isv extends Translations$vocalEnhance$failure$en {
	_Translations$vocalEnhance$failure$isv._(TranslationsIsv root) : this._root = root, super.internal(root);

	final TranslationsIsv _root; // ignore: unused_field

	// Translations
	@override String get analyze => 'Не удало се измєрити запис';
	@override String get enhance => 'Не удало се улєпшити запис';
	@override String get negativeLeadIn => 'Тишина на початку не може быти негативна';
	@override String get notWav => 'Улєпшены запис мора быти фајлом .wав';
	@override String get samePath => 'Улєпшены запис мора быти оддєљным фајлом';
	@override String get unavailable => 'Улєпшење звука не јест доступно на тој платформє';
}

/// The flat map containing all translations for locale <isv>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsIsv {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => 'Hitwave Cover',
			'backup.cancelImport' => 'Отменити импорт',
			'backup.conflictMessage' => ({required Object song}) => '«${song}» уж јест међу вашими пєснями.',
			'backup.conflictTitle' => 'Та пєсња уж јест',
			'backup.exportDialogTitle' => 'Изберите папку за експорт',
			'backup.failure.exportSongs' => 'Не удало се експортовати пєсни',
			'backup.failure.importSongs' => 'Не удало се импортовати пєсни',
			'backup.failure.shareBackup' => 'Не удало се поделити резервну копију',
			'backup.forOthers' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n, few: 'Сдєлати то само за друге ${n} пєсни', many: 'Сдєлати то само за другых ${n} пєсниј', one: 'Сдєлати то само за другу ${n} пєсњу', other: 'Сдєлати то само за другых ${n} пєсниј', ), 
			'backup.importHint' => 'Из фајла, такоже из Google Drive',
			'backup.importSummary' => ({required Object added, required Object replaced, required Object skipped}) => 'Импорт кончены: додано ${added}, замєнено ${replaced}, прескочено ${skipped}',
			'backup.includeRecordings' => 'Вкључити записы',
			'backup.keepBoth' => 'Оставити обе',
			'backup.keepBothHint' => 'Додати пєсњу из фајла поред вашеј, с числом',
			'backup.otherLyrics' => 'Текст в фајлу јест другы.',
			'backup.recordingsNote' => 'Записы сут храњене само на том устројству; с ними фајл стање ZIP-архивом.',
			'backup.replace' => 'Замєнити',
			'backup.replaceHint' => 'Взяти текст из фајла; ваши каверы и записы остајут',
			'backup.sameLyrics' => 'Текст в фајлу јест једнаки.',
			'backup.share' => 'Поделити резервну копију',
			'backup.shareHint' => 'Сохраните ју в Google Drive или пошљите в другу апликацију',
			'backup.shareQuestion' => 'Пєсни будут подељене како фајл, кторы можете сохранити в Google Drive. Записы идут само в ZIP-архиву.',
			'backup.skip' => 'Прескочити',
			'backup.skipHint' => 'Оставити вашу како јест',
			'common.cancel' => 'Отмєнити',
			'common.clear' => 'Очистити',
			'common.delete' => 'Избрисати',
			'common.nothingFound' => 'Ничто не најдено.',
			'common.songDeleted' => 'Пєсња избрисана',
			'history.failure.clear' => 'Не удало се очистити историју',
			'history.failure.save' => 'Не удало се запомнити историју',
			'practice.allStats' => 'Вса статистика',
			'practice.clearFailed' => 'Не удало се очистити тренингы',
			'practice.covers' => 'Каверы',
			'practice.dayStreak' => 'Серија дниј',
			'practice.days' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n, one: '${n} дењ', few: '${n} дни', many: '${n} дниј', other: '${n} дниј', ), 
			'practice.deleteFailed' => 'Не удало се избрисати тренинг',
			'practice.deleteMessage' => 'Он буде одстранены из статистики.',
			'practice.deleteTakes' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n, one: 'Такоже избрисати ${n} запис', few: 'Такоже избрисати ${n} записы', many: 'Такоже избрисати ${n} записов', other: 'Такоже избрисати ${n} записов', ), 
			'practice.deleteTitle' => 'Избрисати тот тренинг?',
			'practice.filterAll' => 'Вся',
			'practice.filterPracticeOnly' => 'Само тренинги',
			'practice.filterWithTakes' => 'С записами',
			'practice.hoursMinutes' => ({required Object hours, required Object minutes}) => '${hours} ч ${minutes} мин',
			'practice.importFailed' => 'Не удало се додати тренингы',
			'practice.lessThanMinute' => 'мење од минуты',
			'practice.longest' => ({required Object value}) => 'рекорд ${value}',
			'practice.minutes' => ({required Object minutes}) => '${minutes} мин',
			'practice.monthNames.0' => 'Јануар',
			'practice.monthNames.1' => 'Фебруар',
			'practice.monthNames.2' => 'Марец',
			'practice.monthNames.3' => 'Април',
			'practice.monthNames.4' => 'Мај',
			'practice.monthNames.5' => 'Јуниј',
			'practice.monthNames.6' => 'Јулиј',
			'practice.monthNames.7' => 'Август',
			'practice.monthNames.8' => 'Септембр',
			'practice.monthNames.9' => 'Октобр',
			'practice.monthNames.10' => 'Новембр',
			'practice.monthNames.11' => 'Децембр',
			'practice.nextMonth' => 'Слєдујучи мєсец',
			'practice.noPracticeThisDay' => 'Того дња не было тренинга.',
			'practice.noPracticeYet' => 'Јешче нема тренингов. Отворите пєсњу и притисните «Старт».',
			'practice.previousMonth' => 'Прєдходны мєсец',
			'practice.saveFailed' => 'Не удало се сохранити тренинг',
			'practice.sessions' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n, one: '${n} тренинг', few: '${n} тренингы', many: '${n} тренингов', other: '${n} тренингов', ), 
			'practice.streak' => 'Серија',
			'practice.takes' => 'Записы',
			'practice.takesCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n, one: '${n} запис', few: '${n} записы', many: '${n} записов', other: '${n} записов', ), 
			'practice.thisMonth' => 'Тутој мєсец',
			'practice.thisWeek' => 'Тутој тыдењ',
			'practice.today' => 'Днес',
			'practice.topSongs' => 'Најчестєјше',
			'practice.total' => 'Всего',
			'practice.week' => 'Тыдењ',
			'practice.weekdayLetters.0' => 'П',
			'practice.weekdayLetters.1' => 'У',
			'practice.weekdayLetters.2' => 'С',
			'practice.weekdayLetters.3' => 'Ч',
			'practice.weekdayLetters.4' => 'П',
			'practice.weekdayLetters.5' => 'С',
			'practice.weekdayLetters.6' => 'Н',
			'practice.weekdayNames.0' => 'Пон',
			'practice.weekdayNames.1' => 'Уто',
			'practice.weekdayNames.2' => 'Сре',
			'practice.weekdayNames.3' => 'Чет',
			'practice.weekdayNames.4' => 'Пет',
			'practice.weekdayNames.5' => 'Соб',
			'practice.weekdayNames.6' => 'Нед',
			'recordings.captionCopied' => 'Опис скопированы — вставите его (⌘V) како подпис к фајлу.',
			'recordings.deleteMessage' => 'Оригинал и улєпшены фајл будут избрисане с устројства.',
			'recordings.deleteTitle' => 'Избрисати запис?',
			'recordings.enhanceFailure.failed' => 'Не удало се улєпшити запис',
			'recordings.enhanceFailure.interrupted' => 'Улєпшење было прєрвано — пустите его јешче раз',
			'recordings.enhanceFailure.unavailable' => 'Улєпшење звука не јест доступно на тој платформє',
			'recordings.enhanceNow' => 'Улєпшити',
			'recordings.enhanced' => 'Улєпшены',
			'recordings.enhancing' => 'Улєпшају…',
			'recordings.failure.busy' => 'Запис уже иде',
			'recordings.failure.delete' => 'Не удало се избрисати запис',
			'recordings.failure.fileMissing' => 'Фајл записа не најден',
			'recordings.failure.importRecordings' => 'Не удало се додати записы из архива',
			'recordings.failure.listMicrophones' => 'Не удало се достати спис микрофонов',
			'recordings.failure.microphonePermission' => 'Нема доступа к микрофону. Дозволите его в наставјењах.',
			'recordings.failure.notFound' => 'Запис не најден',
			'recordings.failure.notRecording' => 'Запис не иде',
			'recordings.failure.play' => 'Не удало се пустити запис',
			'recordings.failure.save' => 'Не удало се сохранити запис',
			'recordings.failure.savePreferences' => 'Не удало се запомнити наставјења записа',
			'recordings.failure.share' => 'Не удало се послати запис',
			'recordings.failure.showInFolder' => 'Не удало се отворити папку',
			'recordings.failure.start' => 'Не удало се начети запис',
			'recordings.microphoneHint' => 'Ако слушалкы сут подкључене к гнєзду, система може записывати из них. Изберите вбудованы микрофон.',
			'recordings.microphoneTitle' => 'Микрофон',
			'recordings.noCovers' => 'Јешче нема каверов. Отворите пєсњу, означите «Запис» и притисните «Старт».',
			'recordings.noTakes' => 'Јешче нема записов. Означите «Запис» и притисните «Старт».',
			'recordings.notEnhanced' => 'Не улєпшено',
			'recordings.original' => 'Оригинал',
			'recordings.pause' => 'Пауза',
			'recordings.play' => 'Слушати',
			'recordings.preparingMp3' => 'Приправјају MP3…',
			'recordings.retry' => 'Улєпшити јешче раз',
			'recordings.share' => 'Послати',
			'recordings.showInFolder' => 'Показати в папке',
			'recordings.silent' => 'Без звука — провєрите микрофон',
			'recordings.systemMicrophone' => 'Како в системє',
			'recordings.title' => 'Записы',
			'settings.accentColor' => 'Акцентна барва',
			'settings.clear' => 'Очистити',
			'settings.clearCovers' => 'Каверы',
			'settings.clearData' => 'Очистити дане',
			'settings.clearHistory' => 'Недавно отворене и слушане',
			'settings.clearMessage' => 'Изберите, что избрисати. То не можно вратити.',
			'settings.clearPractice' => 'Статистика тренингов',
			'settings.clearSongs' => 'Пєсни и јих каверы',
			'settings.clearTitle' => 'Очистити дане?',
			'settings.cleared' => 'Дане очишчене',
			'settings.colors.blue' => 'Сиња',
			'settings.colors.green' => 'Зелена',
			'settings.colors.indigo' => 'Индиго',
			'settings.colors.orange' => 'Оранжева',
			'settings.colors.pink' => 'Ружова',
			'settings.colors.red' => 'Чрвена',
			'settings.colors.teal' => 'Морска',
			'settings.colors.violet' => 'Фиолетова',
			'settings.data' => 'Дане',
			'settings.language' => 'Језык',
			'settings.open' => 'Наставјења',
			'settings.saveFailed' => 'Не удало се сохранити наставјења',
			'settings.theme' => 'Тема',
			'settings.themes.glassDark' => 'Темно стекло',
			'settings.themes.glassLight' => 'Свєтло стекло',
			'settings.themes.neumorphicDark' => 'Темны неуморфизм',
			'settings.themes.neumorphicLight' => 'Свєтлы неуморфизм',
			'settings.title' => 'Наставјења',
			'song.actions' => 'Дєјствија',
			'song.add' => 'Додати',
			'song.addSong' => 'Додати пєсњу',
			'song.album' => 'Албум',
			'song.all' => 'Все',
			'song.allArtists' => 'Вси изполнитељи',
			'song.artist' => 'Изполнитељ',
			'song.artistSearch' => 'Искати изполнитеља',
			'song.coverSearch' => 'Искати каверы по пєсњи',
			'song.coversTooltip' => 'Каверы',
			'song.deleteMessage' => ({required Object name}) => 'Пєсња «${name}» буде избрисана навсегда.',
			'song.deleteTitle' => 'Избрисати пєсњу?',
			'song.edit' => 'Уредити',
			'song.editSong' => 'Уредити пєсњу',
			'song.exportDone' => 'Експорт кончены',
			'song.exportQuestion' => 'Пєсни будут сохрањене в фајл в избраној папке.',
			'song.exportSongs' => 'Експортовати',
			'song.failure.addCover' => 'Не удало се додати кавер.',
			'song.failure.addSong' => 'Не удало се додати пєсњу.',
			'song.failure.addSongs' => 'Не удало се додати пєсни.',
			'song.failure.deleteCover' => 'Не удало се избрисати кавер.',
			'song.failure.deleteSong' => 'Не удало се избрисати пєсњу.',
			'song.failure.updateCover' => 'Не удало се обновити кавер.',
			'song.failure.updateLeadIn' => 'Не удало се сохранити отступ.',
			'song.failure.updateLyrics' => 'Не удало се сохранити текст.',
			'song.failure.updateSong' => 'Не удало се обновити пєсњу.',
			'song.failure.updateSpeed' => 'Не удало се сохранити скорост.',
			'song.importQuestion' => 'Пєсни из фајла будут додане к вашим; за пєсњу, ктору уж имате, изберете, что сдєлати. Записы приходјат само из ZIP-архива.',
			'song.importSongs' => 'Импортовати',
			'song.leadIn' => 'Отступ',
			'song.lyrics' => 'Текст пєсњи',
			'song.microphone' => ({required Object name}) => 'Микрофон: ${name}',
			'song.myCovers' => 'Моје каверы',
			'song.mySongs' => 'Моје пєсни',
			'song.newSong' => 'Нова пєсња',
			'song.noRecentCovers' => 'Послушајте свој кавер — он појави се ту.',
			'song.noRecentSongs' => 'Отворите пєсњу — она појави се ту.',
			'song.noSongsMessage' => 'Додајте прву пєсњу или импортујте резервну копију.',
			'song.noSongsTitle' => 'Јешче нема пєснеј',
			'song.optional' => 'Необвезно',
			'song.otherArtist' => 'Другы изполнитељ',
			'song.pause' => 'Пауза',
			'song.recentlyOpened' => 'Недавно отворене',
			'song.recentlyPlayed' => 'Недавно слушане каверы',
			'song.record' => 'Запис',
			'song.required' => 'Наполните то поље',
			'song.saveChanges' => 'Сохранити измєны',
			'song.searchSongs' => 'Искати пєсни или изполнитељев',
			'song.silentTake' => 'Запис без звука. Провєрите микрофон (кнопка с микрофоном на панелу).',
			'song.songName' => 'Назва пєсњи',
			'song.songsCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('isv'))(n, one: '${n} пєсња', few: '${n} пєсни', many: '${n} пєсењ', other: '${n} пєсењ', ), 
			'song.sort.artists' => 'Изполнитељи',
			'song.sort.covers' => 'Каверы',
			'song.sort.name' => 'А–Ж',
			'song.sort.recent' => 'Недавне',
			'song.speed' => 'Скорост',
			'song.start' => 'Старт',
			'song.statistics' => 'Статистика',
			'song.stopRecording' => 'Зауставити запис',
			'song.sync' => 'Синхронизација',
			'song.tabCovers' => 'Каверы',
			'song.tabHome' => 'Дом',
			'song.tabSongs' => 'Пєсни',
			'song.takeSaved' => 'Запис сохрањены',
			'song.trimSilence' => 'Обрєзати тишину',
			'sync.all' => 'Все',
			'sync.anotherDevice' => 'Друго устројство',
			'sync.applyChosen' => ({required Object n}) => 'Синхронизовати означене (${n})',
			'sync.badge.add' => 'Додати',
			'sync.badge.restore' => 'Вернути',
			'sync.badge.delete' => 'Избрисати',
			'sync.badge.update' => 'Измєнити',
			'sync.codeCopied' => 'Код скопированы',
			'sync.connect' => 'Подкључити се',
			'sync.copyCode' => 'Копировати код',
			'sync.coverTitle' => ({required Object song, required Object date}) => 'Кавер «${song}» од ${date}',
			'sync.coversCount' => ({required Object n}) => 'каверы: ${n}',
			'sync.deletedCount' => ({required Object n}) => 'избрисано: ${n}',
			'sync.deletedHereAt' => ({required Object date, required Object time}) => 'Избрисано ту ${date} в ${time}',
			'sync.deletedThereAt' => ({required Object date, required Object time}) => 'Избрисано на другом устројству ${date} в ${time}',
			'sync.deletedThereAtDevice' => ({required Object device, required Object date, required Object time}) => 'Избрисано на «${device}» ${date} в ${time}',
			'sync.difference.album' => 'албум',
			'sync.difference.lyrics' => 'текст',
			'sync.differs' => ({required Object list}) => 'Различаје се: ${list}',
			'sync.done' => 'Готово',
			'sync.failure.busy' => 'Синхронизација уже иде',
			'sync.failure.cancelled' => 'Отмєњено',
			'sync.failure.connect' => 'Не удало се подкључити к устројству. Провєрите, же оба сут в једној сети Wi‑Fi.',
			'sync.failure.emptyCode' => 'Впишите или сканујте код',
			'sync.failure.host' => 'Не удало се начети синхронизацију',
			'sync.failure.interrupted' => 'Синхронизација прєрвала се',
			'sync.failure.noNetwork' => 'Нема повезања с сетју. Подкључите се к Wi‑Fi.',
			'sync.failure.notACode' => 'То не јест код синхронизације Hitwave Cover',
			'sync.failure.nothingWaits' => 'Нема синхронизације, ктора чака на рєшења',
			'sync.failure.peerStopped' => 'Друго устројство зауставило синхронизацију',
			'sync.goneSong' => 'пєсња, кторој уж нема',
			'sync.intro' => 'Пренесите пєсни, каверы, тренингы и историју меџу устројствами. Прєд каждой измєной видите все измєны за оба устројства, додавања и избрисања, и означајете те, ктоже треба внести.',
			'sync.orPaste' => 'или вставите код из другого устројства',
			'sync.peerStep' => ({required Object device, required Object step}) => '${device}: ${step}',
			'sync.peerStopped' => ({required Object device, required Object reason}) => '${device} зауставил синхронизацију: ${reason}',
			'sync.practiceItem' => ({required Object n}) => 'Тренингы: ${n}',
			'sync.qrHint' => 'На другом устројству отворите «Синхронизација» → «Скановати QR-код». Оба устројства мора быти в једној сети Wi‑Fi.',
			'sync.received' => 'Додано ту',
			'sync.restoredHere' => 'Было избрисано на том устројству',
			'sync.restoredThere' => ({required Object device}) => 'Было избрисано на «${device}»',
			'sync.reviewMessage' => 'Внесене будут само означене измєны. Неозначене остају, как сут, на обох устројствах и будут понуђене опет в следујучи раз.',
			'sync.reviewTitle' => 'Изберите, что синхронизовати',
			'sync.scanQr' => 'Скановати QR-код',
			'sync.scanTitle' => 'Сканујте QR-код',
			'sync.sent' => 'Додано на друго устројство',
			'sync.sessionsCount' => ({required Object n}) => 'тренингы: ${n}',
			'sync.showQr' => 'Показати QR-код',
			'sync.songItem' => ({required Object song}) => 'Пєсња «${song}»',
			'sync.songsCount' => ({required Object n}) => 'пєсни: ${n}',
			'sync.step.applying' => 'Примењају рєшења…',
			'sync.step.choosing' => 'избира, что дєлати с различијами…',
			'sync.step.connecting' => 'Подкључају се…',
			'sync.step.downloading' => ({required Object done, required Object total}) => 'Скачивају каверы ${done} из ${total}',
			'sync.step.joined' => 'подкључило се, обмєњајемо дане…',
			'sync.step.merging' => 'Сједињају дане…',
			'sync.step.reading' => 'Достају спис пєснеј и каверов…',
			'sync.step.uploading' => ({required Object done, required Object total}) => 'Посылају каверы ${done} из ${total}',
			'sync.synced' => 'Синхронизовано',
			'sync.title' => 'Синхронизација',
			'sync.toHere' => ({required Object device}) => 'Из «${device}» на то устројство',
			'sync.toThere' => ({required Object device}) => 'Из того устројства на «${device}»',
			'sync.updateHere' => ({required Object list, required Object device}) => 'Береје ${list} из «${device}»',
			'sync.updateThere' => ({required Object device, required Object list}) => '«${device}» береје ${list} из того устројства',
			'sync.updatedCount' => ({required Object n}) => 'обновјено: ${n}',
			'sync.waiting' => 'Чакају, докле друго устројство сканује код…',
			'sync.withCovers' => ({required Object n}) => 'с каверами: ${n}',
			'tuner.title' => 'Тюнер',
			'tuner.open' => 'Настроити инструмент',
			'tuner.playString' => 'Заиграј на струнє',
			'tuner.inTune' => 'Настроено',
			'tuner.tuneUp' => 'Натягни выше',
			'tuner.tuneDown' => 'Отпусти ниже',
			'tuner.hertz' => ({required Object value}) => '${value} Hz',
			'tuner.cents' => ({required Object value}) => '${value} центов',
			'tuner.retry' => 'Попробовати знову',
			'tuner.instruments.guitar' => 'Гитара',
			'tuner.instruments.ukulele' => 'Укулеле',
			'tuner.instruments.bass' => 'Бас',
			'tuner.instruments.violin' => 'Скрипка',
			'tuner.instruments.chromatic' => 'Хроматичны',
			'tuner.failure.microphonePermission' => 'Дозволи микрофон, да бы користати тюнер.',
			'tuner.failure.start' => 'Не јест возможно отворити микрофон.',
			'vocalEnhance.failure.analyze' => 'Не удало се измєрити запис',
			'vocalEnhance.failure.enhance' => 'Не удало се улєпшити запис',
			'vocalEnhance.failure.negativeLeadIn' => 'Тишина на початку не може быти негативна',
			'vocalEnhance.failure.notWav' => 'Улєпшены запис мора быти фајлом .wав',
			'vocalEnhance.failure.samePath' => 'Улєпшены запис мора быти оддєљным фајлом',
			'vocalEnhance.failure.unavailable' => 'Улєпшење звука не јест доступно на тој платформє',
			_ => null,
		};
	}
}
