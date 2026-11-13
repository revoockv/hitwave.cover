///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'Hitwave Cover'
	String get appTitle => 'Hitwave Cover';

	late final Translations$auth$en auth = Translations$auth$en.internal(_root);
	late final Translations$backup$en backup = Translations$backup$en.internal(_root);
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$history$en history = Translations$history$en.internal(_root);
	late final Translations$practice$en practice = Translations$practice$en.internal(_root);
	late final Translations$recordings$en recordings = Translations$recordings$en.internal(_root);
	late final Translations$song$en song = Translations$song$en.internal(_root);
	late final Translations$sync$en sync = Translations$sync$en.internal(_root);
	late final Translations$vocalEnhance$en vocalEnhance = Translations$vocalEnhance$en.internal(_root);
}

// Path: auth
class Translations$auth$en {
	Translations$auth$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Create an account'
	String get createAccount => 'Create an account';

	/// en: 'Email'
	String get email => 'Email';

	late final Translations$auth$failure$en failure = Translations$auth$failure$en.internal(_root);

	/// en: 'Already have an account? Sign in'
	String get haveAccount => 'Already have an account? Sign in';

	/// en: 'Hide password'
	String get hidePassword => 'Hide password';

	/// en: 'No account? Sign up'
	String get noAccount => 'No account? Sign up';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Show password'
	String get showPassword => 'Show password';

	/// en: 'Sign in'
	String get signIn => 'Sign in';

	/// en: 'Sign in to your account'
	String get signInTitle => 'Sign in to your account';

	/// en: 'Sign out'
	String get signOut => 'Sign out';

	/// en: 'Could not sign out.'
	String get signOutFailed => 'Could not sign out.';

	/// en: 'Sign up'
	String get signUp => 'Sign up';

	/// en: 'Song lyrics and covers always at hand'
	String get tagline => 'Song lyrics and covers always at hand';

	/// en: 'Welcome!'
	String get welcome => 'Welcome!';

	/// en: 'Continue without an account'
	String get withoutAccount => 'Continue without an account';

	/// en: 'Songs will be kept only on this device. You can sign in any time later.'
	String get withoutAccountNote => 'Songs will be kept only on this device. You can sign in any time later.';
}

// Path: backup
class Translations$backup$en {
	Translations$backup$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Choose a folder for the export'
	String get exportDialogTitle => 'Choose a folder for the export';

	late final Translations$backup$failure$en failure = Translations$backup$failure$en.internal(_root);

	/// en: 'Include takes'
	String get includeRecordings => 'Include takes';

	/// en: 'Takes are kept only on this device; with them the file becomes a ZIP archive.'
	String get recordingsNote => 'Takes are kept only on this device; with them the file becomes a ZIP archive.';
}

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Something went wrong. Try again later.'
	String get genericError => 'Something went wrong. Try again later.';

	/// en: 'Nothing found.'
	String get nothingFound => 'Nothing found.';

	/// en: 'Song deleted'
	String get songDeleted => 'Song deleted';
}

// Path: history
class Translations$history$en {
	Translations$history$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$history$failure$en failure = Translations$history$failure$en.internal(_root);
}

// Path: practice
class Translations$practice$en {
	Translations$practice$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'All statistics'
	String get allStats => 'All statistics';

	/// en: 'Covers'
	String get covers => 'Covers';

	/// en: 'Day streak'
	String get dayStreak => 'Day streak';

	/// en: '(one) {{n} day} (other) {{n} days}'
	String days({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} day',
		other: '${n} days',
	);

	/// en: '{hours} h {minutes} min'
	String hoursMinutes({required Object hours, required Object minutes}) => '${hours} h ${minutes} min';

	/// en: 'Could not add the practice sessions'
	String get importFailed => 'Could not add the practice sessions';

	/// en: 'less than a minute'
	String get lessThanMinute => 'less than a minute';

	/// en: 'longest {value}'
	String longest({required Object value}) => 'longest ${value}';

	/// en: '{minutes} min'
	String minutes({required Object minutes}) => '${minutes} min';

	List<String> get monthNames => [
		'January',
		'February',
		'March',
		'April',
		'May',
		'June',
		'July',
		'August',
		'September',
		'October',
		'November',
		'December',
	];

	/// en: 'Next month'
	String get nextMonth => 'Next month';

	/// en: 'No practice this day.'
	String get noPracticeThisDay => 'No practice this day.';

	/// en: 'No practice yet. Open a song and press “Start”.'
	String get noPracticeYet => 'No practice yet. Open a song and press “Start”.';

	/// en: 'Previous month'
	String get previousMonth => 'Previous month';

	/// en: 'Could not save the practice'
	String get saveFailed => 'Could not save the practice';

	/// en: '(one) {{n} session} (other) {{n} sessions}'
	String sessions({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} session',
		other: '${n} sessions',
	);

	/// en: 'Streak'
	String get streak => 'Streak';

	/// en: 'Takes'
	String get takes => 'Takes';

	/// en: '(one) {{n} take} (other) {{n} takes}'
	String takesCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} take',
		other: '${n} takes',
	);

	/// en: 'This month'
	String get thisMonth => 'This month';

	/// en: 'This week'
	String get thisWeek => 'This week';

	/// en: 'Today'
	String get today => 'Today';

	/// en: 'Most practiced'
	String get topSongs => 'Most practiced';

	/// en: 'Total'
	String get total => 'Total';

	/// en: 'Week'
	String get week => 'Week';

	List<String> get weekdayLetters => [
		'M',
		'T',
		'W',
		'T',
		'F',
		'S',
		'S',
	];
	List<String> get weekdayNames => [
		'Mon',
		'Tue',
		'Wed',
		'Thu',
		'Fri',
		'Sat',
		'Sun',
	];
}

// Path: recordings
class Translations$recordings$en {
	Translations$recordings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Caption copied — paste it (⌘V) as the caption of the file.'
	String get captionCopied => 'Caption copied — paste it (⌘V) as the caption of the file.';

	/// en: 'The original and the enhanced file will be deleted from the device.'
	String get deleteMessage => 'The original and the enhanced file will be deleted from the device.';

	/// en: 'Delete the take?'
	String get deleteTitle => 'Delete the take?';

	late final Translations$recordings$enhanceFailure$en enhanceFailure = Translations$recordings$enhanceFailure$en.internal(_root);

	/// en: 'Enhanced'
	String get enhanced => 'Enhanced';

	/// en: 'Enhancing…'
	String get enhancing => 'Enhancing…';

	late final Translations$recordings$failure$en failure = Translations$recordings$failure$en.internal(_root);

	/// en: 'If headphones are plugged into the jack, the system may record from them. Choose the built-in microphone.'
	String get microphoneHint => 'If headphones are plugged into the jack, the system may record from them. Choose the built-in microphone.';

	/// en: 'Microphone'
	String get microphoneTitle => 'Microphone';

	/// en: 'No covers yet. Open a song, tick “Record” and press “Start”.'
	String get noCovers => 'No covers yet. Open a song, tick “Record” and press “Start”.';

	/// en: 'No takes yet. Tick “Record” and press “Start”.'
	String get noTakes => 'No takes yet. Tick “Record” and press “Start”.';

	/// en: 'Not enhanced'
	String get notEnhanced => 'Not enhanced';

	/// en: 'Original'
	String get original => 'Original';

	/// en: 'Pause'
	String get pause => 'Pause';

	/// en: 'Listen'
	String get play => 'Listen';

	/// en: 'Preparing MP3…'
	String get preparingMp3 => 'Preparing MP3…';

	/// en: 'Enhance again'
	String get retry => 'Enhance again';

	/// en: 'Share'
	String get share => 'Share';

	/// en: 'Show in folder'
	String get showInFolder => 'Show in folder';

	/// en: 'No sound — check the microphone'
	String get silent => 'No sound — check the microphone';

	/// en: 'System default'
	String get systemMicrophone => 'System default';

	/// en: 'Takes'
	String get title => 'Takes';
}

// Path: song
class Translations$song$en {
	Translations$song$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Actions'
	String get actions => 'Actions';

	/// en: 'Add'
	String get add => 'Add';

	/// en: 'Add song'
	String get addSong => 'Add song';

	/// en: 'Album'
	String get album => 'Album';

	/// en: 'All'
	String get all => 'All';

	/// en: 'All artists'
	String get allArtists => 'All artists';

	/// en: 'Artist'
	String get artist => 'Artist';

	/// en: 'Search artist'
	String get artistSearch => 'Search artist';

	/// en: 'Search covers by song'
	String get coverSearch => 'Search covers by song';

	/// en: 'Covers'
	String get coversTooltip => 'Covers';

	/// en: '“{name}” will be deleted forever.'
	String deleteMessage({required Object name}) => '“${name}” will be deleted forever.';

	/// en: 'Delete the song?'
	String get deleteTitle => 'Delete the song?';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Edit song'
	String get editSong => 'Edit song';

	/// en: 'Export finished'
	String get exportDone => 'Export finished';

	/// en: 'The songs will be saved to a file in the chosen folder.'
	String get exportQuestion => 'The songs will be saved to a file in the chosen folder.';

	/// en: 'Export'
	String get exportSongs => 'Export';

	late final Translations$song$failure$en failure = Translations$song$failure$en.internal(_root);

	/// en: 'Import finished'
	String get importDone => 'Import finished';

	/// en: 'The songs from the file will be added to yours. Takes come only from a ZIP archive.'
	String get importQuestion => 'The songs from the file will be added to yours. Takes come only from a ZIP archive.';

	/// en: 'Import'
	String get importSongs => 'Import';

	/// en: 'Keep on the device'
	String get keepOnDevice => 'Keep on the device';

	/// en: 'Lead-in'
	String get leadIn => 'Lead-in';

	/// en: 'Lyrics'
	String get lyrics => 'Lyrics';

	/// en: 'Microphone: {name}'
	String microphone({required Object name}) => 'Microphone: ${name}';

	/// en: 'More'
	String get more => 'More';

	/// en: 'My covers'
	String get myCovers => 'My covers';

	/// en: 'My songs'
	String get mySongs => 'My songs';

	/// en: 'New song'
	String get newSong => 'New song';

	/// en: 'Listen to your cover — it will show up here.'
	String get noRecentCovers => 'Listen to your cover — it will show up here.';

	/// en: 'Open a song — it will show up here.'
	String get noRecentSongs => 'Open a song — it will show up here.';

	/// en: 'Add your first song or import a backup.'
	String get noSongsMessage => 'Add your first song or import a backup.';

	/// en: 'No songs yet'
	String get noSongsTitle => 'No songs yet';

	/// en: 'Optional'
	String get optional => 'Optional';

	/// en: 'Another artist'
	String get otherArtist => 'Another artist';

	/// en: 'Pause'
	String get pause => 'Pause';

	/// en: 'Recently opened'
	String get recentlyOpened => 'Recently opened';

	/// en: 'Recently played covers'
	String get recentlyPlayed => 'Recently played covers';

	/// en: 'Record'
	String get record => 'Record';

	/// en: 'Fill in this field'
	String get required => 'Fill in this field';

	/// en: 'Save changes'
	String get saveChanges => 'Save changes';

	/// en: 'Search songs or artists'
	String get searchSongs => 'Search songs or artists';

	/// en: 'Sign in to an account'
	String get signInAccount => 'Sign in to an account';

	/// en: 'The take has no sound. Check the microphone (the microphone button on the panel).'
	String get silentTake => 'The take has no sound. Check the microphone (the microphone button on the panel).';

	/// en: 'Song title'
	String get songName => 'Song title';

	/// en: '(one) {{n} song} (other) {{n} songs}'
	String songsCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} song',
		other: '${n} songs',
	);

	late final Translations$song$sort$en sort = Translations$song$sort$en.internal(_root);

	/// en: 'Speed'
	String get speed => 'Speed';

	/// en: 'Start'
	String get start => 'Start';

	/// en: 'Statistics'
	String get statistics => 'Statistics';

	/// en: 'Stop recording'
	String get stopRecording => 'Stop recording';

	/// en: 'Sync'
	String get sync => 'Sync';

	/// en: 'Covers'
	String get tabCovers => 'Covers';

	/// en: 'Home'
	String get tabHome => 'Home';

	/// en: 'Songs'
	String get tabSongs => 'Songs';

	/// en: 'Take saved, enhancing the sound…'
	String get takeSaved => 'Take saved, enhancing the sound…';

	/// en: 'Move'
	String get transfer => 'Move';

	/// en: 'Songs on this device: {n}. Moved songs will be in the account on all devices and will disappear from here. If you keep them, they stay available when you continue without an account.'
	String transferMessage({required Object n}) => 'Songs on this device: ${n}.\n\nMoved songs will be in the account on all devices and will disappear from here. If you keep them, they stay available when you continue without an account.';

	/// en: 'Move the songs to the account?'
	String get transferTitle => 'Move the songs to the account?';

	/// en: 'Songs moved to the account'
	String get transferred => 'Songs moved to the account';

	/// en: 'Trim silence'
	String get trimSilence => 'Trim silence';
}

// Path: sync
class Translations$sync$en {
	Translations$sync$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'All changes:'
	String get allChanges => 'All changes:';

	/// en: 'All deletions:'
	String get allDeletions => 'All deletions:';

	/// en: 'Another device'
	String get anotherDevice => 'Another device';

	late final Translations$sync$bulk$en bulk = Translations$sync$bulk$en.internal(_root);

	/// en: 'Code copied'
	String get codeCopied => 'Code copied';

	/// en: 'These songs and covers were deleted or changed on only one of the devices. Choose for each what to do on both.'
	String get conflictsMessage => 'These songs and covers were deleted or changed on only one of the devices. Choose for each what to do on both.';

	/// en: 'What to do with the differences?'
	String get conflictsTitle => 'What to do with the differences?';

	/// en: 'Connect'
	String get connect => 'Connect';

	/// en: 'Continue'
	String get continueSync => 'Continue';

	/// en: 'Copy code'
	String get copyCode => 'Copy code';

	/// en: 'Cover of “{song}” from {date}'
	String coverTitle({required Object song, required Object date}) => 'Cover of “${song}” from ${date}';

	/// en: 'covers: {n}'
	String coversCount({required Object n}) => 'covers: ${n}';

	/// en: 'Delete here too'
	String get deleteHere => 'Delete here too';

	/// en: 'Delete there too'
	String get deleteThere => 'Delete there too';

	/// en: 'deleted: {n}'
	String deletedCount({required Object n}) => 'deleted: ${n}';

	/// en: 'Deleted here {date} at {time}'
	String deletedHereAt({required Object date, required Object time}) => 'Deleted here ${date} at ${time}';

	/// en: 'Deleted on the other device {date} at {time}'
	String deletedThereAt({required Object date, required Object time}) => 'Deleted on the other device ${date} at ${time}';

	late final Translations$sync$difference$en difference = Translations$sync$difference$en.internal(_root);

	/// en: 'Differs: {list}'
	String differs({required Object list}) => 'Differs: ${list}';

	/// en: 'Done'
	String get done => 'Done';

	late final Translations$sync$failure$en failure = Translations$sync$failure$en.internal(_root);

	/// en: 'a song that is gone'
	String get goneSong => 'a song that is gone';

	/// en: 'Move songs, covers, practice and history between devices. Nothing is deleted: each device gets what it misses.'
	String get intro => 'Move songs, covers, practice and history between devices. Nothing is deleted: each device gets what it misses.';

	/// en: 'Keep this one'
	String get keepThis => 'Keep this one';

	late final Translations$sync$kind$en kind = Translations$sync$kind$en.internal(_root);

	/// en: 'or paste the code from another device'
	String get orPaste => 'or paste the code from another device';

	/// en: '{device}: {step}'
	String peerStep({required Object device, required Object step}) => '${device}: ${step}';

	/// en: '{device} stopped syncing: {reason}'
	String peerStopped({required Object device, required Object reason}) => '${device} stopped syncing: ${reason}';

	/// en: 'On the other device open “Sync” → “Scan QR code”. Both devices must be on the same Wi‑Fi network.'
	String get qrHint => 'On the other device open “Sync” → “Scan QR code”. Both devices must be on the same Wi‑Fi network.';

	/// en: 'Added here'
	String get received => 'Added here';

	/// en: 'Restore here'
	String get restoreHere => 'Restore here';

	/// en: 'Restore there'
	String get restoreThere => 'Restore there';

	/// en: 'Scan QR code'
	String get scanQr => 'Scan QR code';

	/// en: 'Scan the QR code'
	String get scanTitle => 'Scan the QR code';

	/// en: 'Added to the other device'
	String get sent => 'Added to the other device';

	/// en: 'practice: {n}'
	String sessionsCount({required Object n}) => 'practice: ${n}';

	/// en: 'Show QR code'
	String get showQr => 'Show QR code';

	/// en: 'songs: {n}'
	String songsCount({required Object n}) => 'songs: ${n}';

	late final Translations$sync$step$en step = Translations$sync$step$en.internal(_root);

	/// en: 'Synced'
	String get synced => 'Synced';

	/// en: 'Take the other one'
	String get takeOther => 'Take the other one';

	/// en: 'Sync'
	String get title => 'Sync';

	/// en: 'updated: {n}'
	String updatedCount({required Object n}) => 'updated: ${n}';

	/// en: 'Waiting for the other device to scan the code…'
	String get waiting => 'Waiting for the other device to scan the code…';
}

// Path: vocalEnhance
class Translations$vocalEnhance$en {
	Translations$vocalEnhance$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$vocalEnhance$failure$en failure = Translations$vocalEnhance$failure$en.internal(_root);
}

// Path: auth.failure
class Translations$auth$failure$en {
	Translations$auth$failure$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'This email is already in use.'
	String get emailAlreadyInUse => 'This email is already in use.';

	/// en: 'Please fill in all fields.'
	String get emptyFields => 'Please fill in all fields.';

	/// en: 'Wrong email or password.'
	String get invalidCredential => 'Wrong email or password.';

	/// en: 'The email address is not valid.'
	String get invalidEmail => 'The email address is not valid.';

	/// en: 'Too many attempts. Try again later.'
	String get tooManyRequests => 'Too many attempts. Try again later.';

	/// en: 'This account has been disabled.'
	String get userDisabled => 'This account has been disabled.';

	/// en: 'No user has this email.'
	String get userNotFound => 'No user has this email.';

	/// en: 'The password is too simple.'
	String get weakPassword => 'The password is too simple.';

	/// en: 'Wrong password.'
	String get wrongPassword => 'Wrong password.';
}

// Path: backup.failure
class Translations$backup$failure$en {
	Translations$backup$failure$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Could not export the songs'
	String get exportSongs => 'Could not export the songs';

	/// en: 'Could not import the songs'
	String get importSongs => 'Could not import the songs';
}

// Path: history.failure
class Translations$history$failure$en {
	Translations$history$failure$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Could not remember the history'
	String get save => 'Could not remember the history';
}

// Path: recordings.enhanceFailure
class Translations$recordings$enhanceFailure$en {
	Translations$recordings$enhanceFailure$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Could not enhance the take'
	String get failed => 'Could not enhance the take';

	/// en: 'The enhancement was interrupted — start it again'
	String get interrupted => 'The enhancement was interrupted — start it again';

	/// en: 'Sound enhancement is not available on this platform'
	String get unavailable => 'Sound enhancement is not available on this platform';
}

// Path: recordings.failure
class Translations$recordings$failure$en {
	Translations$recordings$failure$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Already recording'
	String get busy => 'Already recording';

	/// en: 'Could not delete the take'
	String get delete => 'Could not delete the take';

	/// en: 'The file of the take is missing'
	String get fileMissing => 'The file of the take is missing';

	/// en: 'Could not add the takes from the archive'
	String get importRecordings => 'Could not add the takes from the archive';

	/// en: 'Could not list the microphones'
	String get listMicrophones => 'Could not list the microphones';

	/// en: 'No access to the microphone. Allow it in the settings.'
	String get microphonePermission => 'No access to the microphone. Allow it in the settings.';

	/// en: 'Take not found'
	String get notFound => 'Take not found';

	/// en: 'Not recording'
	String get notRecording => 'Not recording';

	/// en: 'Could not play the take'
	String get play => 'Could not play the take';

	/// en: 'Could not save the take'
	String get save => 'Could not save the take';

	/// en: 'Could not remember the recording options'
	String get savePreferences => 'Could not remember the recording options';

	/// en: 'Could not share the take'
	String get share => 'Could not share the take';

	/// en: 'Could not open the folder'
	String get showInFolder => 'Could not open the folder';

	/// en: 'Could not start recording'
	String get start => 'Could not start recording';
}

// Path: song.failure
class Translations$song$failure$en {
	Translations$song$failure$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Could not add the cover.'
	String get addCover => 'Could not add the cover.';

	/// en: 'Could not add the song.'
	String get addSong => 'Could not add the song.';

	/// en: 'Could not add the songs.'
	String get addSongs => 'Could not add the songs.';

	/// en: 'Could not delete the cover.'
	String get deleteCover => 'Could not delete the cover.';

	/// en: 'Could not delete the song.'
	String get deleteSong => 'Could not delete the song.';

	/// en: 'Could not remember the choice.'
	String get keepLocal => 'Could not remember the choice.';

	/// en: 'Sign in or continue without an account first.'
	String get notAuthenticated => 'Sign in or continue without an account first.';

	/// en: 'Not all songs moved to the account. The rest stayed on this device.'
	String get transfer => 'Not all songs moved to the account. The rest stayed on this device.';

	/// en: 'Could not update the cover.'
	String get updateCover => 'Could not update the cover.';

	/// en: 'Could not save the lead-in.'
	String get updateLeadIn => 'Could not save the lead-in.';

	/// en: 'Could not save the lyrics.'
	String get updateLyrics => 'Could not save the lyrics.';

	/// en: 'Could not update the song.'
	String get updateSong => 'Could not update the song.';

	/// en: 'Could not save the speed.'
	String get updateSpeed => 'Could not save the speed.';
}

// Path: song.sort
class Translations$song$sort$en {
	Translations$song$sort$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Artists'
	String get artists => 'Artists';

	/// en: 'Covers'
	String get covers => 'Covers';

	/// en: 'A–Z'
	String get name => 'A–Z';

	/// en: 'Recent'
	String get recent => 'Recent';
}

// Path: sync.bulk
class Translations$sync$bulk$en {
	Translations$sync$bulk$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'delete'
	String get delete => 'delete';

	/// en: 'keep these'
	String get keepThis => 'keep these';

	/// en: 'restore'
	String get restore => 'restore';

	/// en: 'take the other'
	String get takeOther => 'take the other';
}

// Path: sync.difference
class Translations$sync$difference$en {
	Translations$sync$difference$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'album'
	String get album => 'album';

	/// en: 'lyrics'
	String get lyrics => 'lyrics';
}

// Path: sync.failure
class Translations$sync$failure$en {
	Translations$sync$failure$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Syncing is already running'
	String get busy => 'Syncing is already running';

	/// en: 'Cancelled'
	String get cancelled => 'Cancelled';

	/// en: 'Could not connect to the device. Check that both are on the same Wi‑Fi network.'
	String get connect => 'Could not connect to the device. Check that both are on the same Wi‑Fi network.';

	/// en: 'Enter or scan the code'
	String get emptyCode => 'Enter or scan the code';

	/// en: 'Could not start syncing'
	String get host => 'Could not start syncing';

	/// en: 'Syncing was interrupted'
	String get interrupted => 'Syncing was interrupted';

	/// en: 'No network connection. Connect to Wi‑Fi.'
	String get noNetwork => 'No network connection. Connect to Wi‑Fi.';

	/// en: 'This is not a sync code of hitwave.cover'
	String get notACode => 'This is not a sync code of hitwave.cover';

	/// en: 'No sync is waiting for decisions'
	String get nothingWaits => 'No sync is waiting for decisions';

	/// en: 'The other device stopped syncing'
	String get peerStopped => 'The other device stopped syncing';
}

// Path: sync.kind
class Translations$sync$kind$en {
	Translations$sync$kind$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cover deleted on this device'
	String get coverDeletedHere => 'Cover deleted on this device';

	/// en: 'Cover deleted on the other device'
	String get coverDeletedThere => 'Cover deleted on the other device';

	/// en: 'The song differs'
	String get songChanged => 'The song differs';

	/// en: 'Song deleted on this device'
	String get songDeletedHere => 'Song deleted on this device';

	/// en: 'Song deleted on the other device'
	String get songDeletedThere => 'Song deleted on the other device';
}

// Path: sync.step
class Translations$sync$step$en {
	Translations$sync$step$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Applying the decisions…'
	String get applying => 'Applying the decisions…';

	/// en: 'is choosing what to do with the differences…'
	String get choosing => 'is choosing what to do with the differences…';

	/// en: 'Connecting…'
	String get connecting => 'Connecting…';

	/// en: 'Downloading covers {done} of {total}'
	String downloading({required Object done, required Object total}) => 'Downloading covers ${done} of ${total}';

	/// en: 'connected, exchanging data…'
	String get joined => 'connected, exchanging data…';

	/// en: 'Merging the data…'
	String get merging => 'Merging the data…';

	/// en: 'Getting the list of songs and covers…'
	String get reading => 'Getting the list of songs and covers…';

	/// en: 'Sending covers {done} of {total}'
	String uploading({required Object done, required Object total}) => 'Sending covers ${done} of ${total}';
}

// Path: vocalEnhance.failure
class Translations$vocalEnhance$failure$en {
	Translations$vocalEnhance$failure$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Could not measure the take'
	String get analyze => 'Could not measure the take';

	/// en: 'Could not enhance the take'
	String get enhance => 'Could not enhance the take';

	/// en: 'The silence at the start cannot be negative'
	String get negativeLeadIn => 'The silence at the start cannot be negative';

	/// en: 'The enhanced take must be a .wav file'
	String get notWav => 'The enhanced take must be a .wav file';

	/// en: 'The enhanced take must be a separate file'
	String get samePath => 'The enhanced take must be a separate file';

	/// en: 'Sound enhancement is not available on this platform'
	String get unavailable => 'Sound enhancement is not available on this platform';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => 'Hitwave Cover',
			'auth.createAccount' => 'Create an account',
			'auth.email' => 'Email',
			'auth.failure.emailAlreadyInUse' => 'This email is already in use.',
			'auth.failure.emptyFields' => 'Please fill in all fields.',
			'auth.failure.invalidCredential' => 'Wrong email or password.',
			'auth.failure.invalidEmail' => 'The email address is not valid.',
			'auth.failure.tooManyRequests' => 'Too many attempts. Try again later.',
			'auth.failure.userDisabled' => 'This account has been disabled.',
			'auth.failure.userNotFound' => 'No user has this email.',
			'auth.failure.weakPassword' => 'The password is too simple.',
			'auth.failure.wrongPassword' => 'Wrong password.',
			'auth.haveAccount' => 'Already have an account? Sign in',
			'auth.hidePassword' => 'Hide password',
			'auth.noAccount' => 'No account? Sign up',
			'auth.password' => 'Password',
			'auth.showPassword' => 'Show password',
			'auth.signIn' => 'Sign in',
			'auth.signInTitle' => 'Sign in to your account',
			'auth.signOut' => 'Sign out',
			'auth.signOutFailed' => 'Could not sign out.',
			'auth.signUp' => 'Sign up',
			'auth.tagline' => 'Song lyrics and covers always at hand',
			'auth.welcome' => 'Welcome!',
			'auth.withoutAccount' => 'Continue without an account',
			'auth.withoutAccountNote' => 'Songs will be kept only on this device. You can sign in any time later.',
			'backup.exportDialogTitle' => 'Choose a folder for the export',
			'backup.failure.exportSongs' => 'Could not export the songs',
			'backup.failure.importSongs' => 'Could not import the songs',
			'backup.includeRecordings' => 'Include takes',
			'backup.recordingsNote' => 'Takes are kept only on this device; with them the file becomes a ZIP archive.',
			'common.cancel' => 'Cancel',
			'common.clear' => 'Clear',
			'common.delete' => 'Delete',
			'common.genericError' => 'Something went wrong. Try again later.',
			'common.nothingFound' => 'Nothing found.',
			'common.songDeleted' => 'Song deleted',
			'history.failure.save' => 'Could not remember the history',
			'practice.allStats' => 'All statistics',
			'practice.covers' => 'Covers',
			'practice.dayStreak' => 'Day streak',
			'practice.days' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} day', other: '${n} days', ), 
			'practice.hoursMinutes' => ({required Object hours, required Object minutes}) => '${hours} h ${minutes} min',
			'practice.importFailed' => 'Could not add the practice sessions',
			'practice.lessThanMinute' => 'less than a minute',
			'practice.longest' => ({required Object value}) => 'longest ${value}',
			'practice.minutes' => ({required Object minutes}) => '${minutes} min',
			'practice.monthNames.0' => 'January',
			'practice.monthNames.1' => 'February',
			'practice.monthNames.2' => 'March',
			'practice.monthNames.3' => 'April',
			'practice.monthNames.4' => 'May',
			'practice.monthNames.5' => 'June',
			'practice.monthNames.6' => 'July',
			'practice.monthNames.7' => 'August',
			'practice.monthNames.8' => 'September',
			'practice.monthNames.9' => 'October',
			'practice.monthNames.10' => 'November',
			'practice.monthNames.11' => 'December',
			'practice.nextMonth' => 'Next month',
			'practice.noPracticeThisDay' => 'No practice this day.',
			'practice.noPracticeYet' => 'No practice yet. Open a song and press “Start”.',
			'practice.previousMonth' => 'Previous month',
			'practice.saveFailed' => 'Could not save the practice',
			'practice.sessions' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} session', other: '${n} sessions', ), 
			'practice.streak' => 'Streak',
			'practice.takes' => 'Takes',
			'practice.takesCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} take', other: '${n} takes', ), 
			'practice.thisMonth' => 'This month',
			'practice.thisWeek' => 'This week',
			'practice.today' => 'Today',
			'practice.topSongs' => 'Most practiced',
			'practice.total' => 'Total',
			'practice.week' => 'Week',
			'practice.weekdayLetters.0' => 'M',
			'practice.weekdayLetters.1' => 'T',
			'practice.weekdayLetters.2' => 'W',
			'practice.weekdayLetters.3' => 'T',
			'practice.weekdayLetters.4' => 'F',
			'practice.weekdayLetters.5' => 'S',
			'practice.weekdayLetters.6' => 'S',
			'practice.weekdayNames.0' => 'Mon',
			'practice.weekdayNames.1' => 'Tue',
			'practice.weekdayNames.2' => 'Wed',
			'practice.weekdayNames.3' => 'Thu',
			'practice.weekdayNames.4' => 'Fri',
			'practice.weekdayNames.5' => 'Sat',
			'practice.weekdayNames.6' => 'Sun',
			'recordings.captionCopied' => 'Caption copied — paste it (⌘V) as the caption of the file.',
			'recordings.deleteMessage' => 'The original and the enhanced file will be deleted from the device.',
			'recordings.deleteTitle' => 'Delete the take?',
			'recordings.enhanceFailure.failed' => 'Could not enhance the take',
			'recordings.enhanceFailure.interrupted' => 'The enhancement was interrupted — start it again',
			'recordings.enhanceFailure.unavailable' => 'Sound enhancement is not available on this platform',
			'recordings.enhanced' => 'Enhanced',
			'recordings.enhancing' => 'Enhancing…',
			'recordings.failure.busy' => 'Already recording',
			'recordings.failure.delete' => 'Could not delete the take',
			'recordings.failure.fileMissing' => 'The file of the take is missing',
			'recordings.failure.importRecordings' => 'Could not add the takes from the archive',
			'recordings.failure.listMicrophones' => 'Could not list the microphones',
			'recordings.failure.microphonePermission' => 'No access to the microphone. Allow it in the settings.',
			'recordings.failure.notFound' => 'Take not found',
			'recordings.failure.notRecording' => 'Not recording',
			'recordings.failure.play' => 'Could not play the take',
			'recordings.failure.save' => 'Could not save the take',
			'recordings.failure.savePreferences' => 'Could not remember the recording options',
			'recordings.failure.share' => 'Could not share the take',
			'recordings.failure.showInFolder' => 'Could not open the folder',
			'recordings.failure.start' => 'Could not start recording',
			'recordings.microphoneHint' => 'If headphones are plugged into the jack, the system may record from them. Choose the built-in microphone.',
			'recordings.microphoneTitle' => 'Microphone',
			'recordings.noCovers' => 'No covers yet. Open a song, tick “Record” and press “Start”.',
			'recordings.noTakes' => 'No takes yet. Tick “Record” and press “Start”.',
			'recordings.notEnhanced' => 'Not enhanced',
			'recordings.original' => 'Original',
			'recordings.pause' => 'Pause',
			'recordings.play' => 'Listen',
			'recordings.preparingMp3' => 'Preparing MP3…',
			'recordings.retry' => 'Enhance again',
			'recordings.share' => 'Share',
			'recordings.showInFolder' => 'Show in folder',
			'recordings.silent' => 'No sound — check the microphone',
			'recordings.systemMicrophone' => 'System default',
			'recordings.title' => 'Takes',
			'song.actions' => 'Actions',
			'song.add' => 'Add',
			'song.addSong' => 'Add song',
			'song.album' => 'Album',
			'song.all' => 'All',
			'song.allArtists' => 'All artists',
			'song.artist' => 'Artist',
			'song.artistSearch' => 'Search artist',
			'song.coverSearch' => 'Search covers by song',
			'song.coversTooltip' => 'Covers',
			'song.deleteMessage' => ({required Object name}) => '“${name}” will be deleted forever.',
			'song.deleteTitle' => 'Delete the song?',
			'song.edit' => 'Edit',
			'song.editSong' => 'Edit song',
			'song.exportDone' => 'Export finished',
			'song.exportQuestion' => 'The songs will be saved to a file in the chosen folder.',
			'song.exportSongs' => 'Export',
			'song.failure.addCover' => 'Could not add the cover.',
			'song.failure.addSong' => 'Could not add the song.',
			'song.failure.addSongs' => 'Could not add the songs.',
			'song.failure.deleteCover' => 'Could not delete the cover.',
			'song.failure.deleteSong' => 'Could not delete the song.',
			'song.failure.keepLocal' => 'Could not remember the choice.',
			'song.failure.notAuthenticated' => 'Sign in or continue without an account first.',
			'song.failure.transfer' => 'Not all songs moved to the account. The rest stayed on this device.',
			'song.failure.updateCover' => 'Could not update the cover.',
			'song.failure.updateLeadIn' => 'Could not save the lead-in.',
			'song.failure.updateLyrics' => 'Could not save the lyrics.',
			'song.failure.updateSong' => 'Could not update the song.',
			'song.failure.updateSpeed' => 'Could not save the speed.',
			'song.importDone' => 'Import finished',
			'song.importQuestion' => 'The songs from the file will be added to yours. Takes come only from a ZIP archive.',
			'song.importSongs' => 'Import',
			'song.keepOnDevice' => 'Keep on the device',
			'song.leadIn' => 'Lead-in',
			'song.lyrics' => 'Lyrics',
			'song.microphone' => ({required Object name}) => 'Microphone: ${name}',
			'song.more' => 'More',
			'song.myCovers' => 'My covers',
			'song.mySongs' => 'My songs',
			'song.newSong' => 'New song',
			'song.noRecentCovers' => 'Listen to your cover — it will show up here.',
			'song.noRecentSongs' => 'Open a song — it will show up here.',
			'song.noSongsMessage' => 'Add your first song or import a backup.',
			'song.noSongsTitle' => 'No songs yet',
			'song.optional' => 'Optional',
			'song.otherArtist' => 'Another artist',
			'song.pause' => 'Pause',
			'song.recentlyOpened' => 'Recently opened',
			'song.recentlyPlayed' => 'Recently played covers',
			'song.record' => 'Record',
			'song.required' => 'Fill in this field',
			'song.saveChanges' => 'Save changes',
			'song.searchSongs' => 'Search songs or artists',
			'song.signInAccount' => 'Sign in to an account',
			'song.silentTake' => 'The take has no sound. Check the microphone (the microphone button on the panel).',
			'song.songName' => 'Song title',
			'song.songsCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} song', other: '${n} songs', ), 
			'song.sort.artists' => 'Artists',
			'song.sort.covers' => 'Covers',
			'song.sort.name' => 'A–Z',
			'song.sort.recent' => 'Recent',
			'song.speed' => 'Speed',
			'song.start' => 'Start',
			'song.statistics' => 'Statistics',
			'song.stopRecording' => 'Stop recording',
			'song.sync' => 'Sync',
			'song.tabCovers' => 'Covers',
			'song.tabHome' => 'Home',
			'song.tabSongs' => 'Songs',
			'song.takeSaved' => 'Take saved, enhancing the sound…',
			'song.transfer' => 'Move',
			'song.transferMessage' => ({required Object n}) => 'Songs on this device: ${n}.\n\nMoved songs will be in the account on all devices and will disappear from here. If you keep them, they stay available when you continue without an account.',
			'song.transferTitle' => 'Move the songs to the account?',
			'song.transferred' => 'Songs moved to the account',
			'song.trimSilence' => 'Trim silence',
			'sync.allChanges' => 'All changes:',
			'sync.allDeletions' => 'All deletions:',
			'sync.anotherDevice' => 'Another device',
			'sync.bulk.delete' => 'delete',
			'sync.bulk.keepThis' => 'keep these',
			'sync.bulk.restore' => 'restore',
			'sync.bulk.takeOther' => 'take the other',
			'sync.codeCopied' => 'Code copied',
			'sync.conflictsMessage' => 'These songs and covers were deleted or changed on only one of the devices. Choose for each what to do on both.',
			'sync.conflictsTitle' => 'What to do with the differences?',
			'sync.connect' => 'Connect',
			'sync.continueSync' => 'Continue',
			'sync.copyCode' => 'Copy code',
			'sync.coverTitle' => ({required Object song, required Object date}) => 'Cover of “${song}” from ${date}',
			'sync.coversCount' => ({required Object n}) => 'covers: ${n}',
			'sync.deleteHere' => 'Delete here too',
			'sync.deleteThere' => 'Delete there too',
			'sync.deletedCount' => ({required Object n}) => 'deleted: ${n}',
			'sync.deletedHereAt' => ({required Object date, required Object time}) => 'Deleted here ${date} at ${time}',
			'sync.deletedThereAt' => ({required Object date, required Object time}) => 'Deleted on the other device ${date} at ${time}',
			'sync.difference.album' => 'album',
			'sync.difference.lyrics' => 'lyrics',
			'sync.differs' => ({required Object list}) => 'Differs: ${list}',
			'sync.done' => 'Done',
			'sync.failure.busy' => 'Syncing is already running',
			'sync.failure.cancelled' => 'Cancelled',
			'sync.failure.connect' => 'Could not connect to the device. Check that both are on the same Wi‑Fi network.',
			'sync.failure.emptyCode' => 'Enter or scan the code',
			'sync.failure.host' => 'Could not start syncing',
			'sync.failure.interrupted' => 'Syncing was interrupted',
			'sync.failure.noNetwork' => 'No network connection. Connect to Wi‑Fi.',
			'sync.failure.notACode' => 'This is not a sync code of hitwave.cover',
			'sync.failure.nothingWaits' => 'No sync is waiting for decisions',
			'sync.failure.peerStopped' => 'The other device stopped syncing',
			'sync.goneSong' => 'a song that is gone',
			'sync.intro' => 'Move songs, covers, practice and history between devices. Nothing is deleted: each device gets what it misses.',
			'sync.keepThis' => 'Keep this one',
			'sync.kind.coverDeletedHere' => 'Cover deleted on this device',
			'sync.kind.coverDeletedThere' => 'Cover deleted on the other device',
			'sync.kind.songChanged' => 'The song differs',
			'sync.kind.songDeletedHere' => 'Song deleted on this device',
			'sync.kind.songDeletedThere' => 'Song deleted on the other device',
			'sync.orPaste' => 'or paste the code from another device',
			'sync.peerStep' => ({required Object device, required Object step}) => '${device}: ${step}',
			'sync.peerStopped' => ({required Object device, required Object reason}) => '${device} stopped syncing: ${reason}',
			'sync.qrHint' => 'On the other device open “Sync” → “Scan QR code”. Both devices must be on the same Wi‑Fi network.',
			'sync.received' => 'Added here',
			'sync.restoreHere' => 'Restore here',
			'sync.restoreThere' => 'Restore there',
			'sync.scanQr' => 'Scan QR code',
			'sync.scanTitle' => 'Scan the QR code',
			'sync.sent' => 'Added to the other device',
			'sync.sessionsCount' => ({required Object n}) => 'practice: ${n}',
			'sync.showQr' => 'Show QR code',
			'sync.songsCount' => ({required Object n}) => 'songs: ${n}',
			'sync.step.applying' => 'Applying the decisions…',
			'sync.step.choosing' => 'is choosing what to do with the differences…',
			'sync.step.connecting' => 'Connecting…',
			'sync.step.downloading' => ({required Object done, required Object total}) => 'Downloading covers ${done} of ${total}',
			'sync.step.joined' => 'connected, exchanging data…',
			'sync.step.merging' => 'Merging the data…',
			'sync.step.reading' => 'Getting the list of songs and covers…',
			'sync.step.uploading' => ({required Object done, required Object total}) => 'Sending covers ${done} of ${total}',
			'sync.synced' => 'Synced',
			'sync.takeOther' => 'Take the other one',
			'sync.title' => 'Sync',
			'sync.updatedCount' => ({required Object n}) => 'updated: ${n}',
			'sync.waiting' => 'Waiting for the other device to scan the code…',
			'vocalEnhance.failure.analyze' => 'Could not measure the take',
			'vocalEnhance.failure.enhance' => 'Could not enhance the take',
			'vocalEnhance.failure.negativeLeadIn' => 'The silence at the start cannot be negative',
			'vocalEnhance.failure.notWav' => 'The enhanced take must be a .wav file',
			'vocalEnhance.failure.samePath' => 'The enhanced take must be a separate file',
			'vocalEnhance.failure.unavailable' => 'Sound enhancement is not available on this platform',
			_ => null,
		};
	}
}
