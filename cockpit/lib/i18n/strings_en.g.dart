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
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$core$en core = Translations$core$en.internal(_root);
	late final Translations$settings$en settings = Translations$settings$en.internal(_root);
}

// Path: core
class Translations$core$en {
	Translations$core$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$core$bootstrapError$en bootstrapError = Translations$core$bootstrapError$en.internal(_root);
	late final Translations$core$macosNotifications$en macosNotifications = Translations$core$macosNotifications$en.internal(_root);
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$settings$language$en language = Translations$settings$language$en.internal(_root);
}

// Path: core.bootstrapError
class Translations$core$bootstrapError$en {
	Translations$core$bootstrapError$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Failed to initialize Cockpit'
	String get title => 'Failed to initialize Cockpit';

	/// en: 'Retry'
	String get retry => 'Retry';
}

// Path: core.macosNotifications
class Translations$core$macosNotifications$en {
	Translations$core$macosNotifications$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Enable Notifications on macOS'
	String get title => 'Enable Notifications on macOS';

	/// en: 'Notifications are currently disabled in your system settings. Follow the steps below to enable them:'
	String get intro => 'Notifications are currently disabled in your system settings. Follow the steps below to enable them:';

	/// en: 'Open System Settings on your Mac.'
	String get step1 => 'Open System Settings on your Mac.';

	/// en: 'Navigate to the Notifications section in the left sidebar.'
	String get step2 => 'Navigate to the Notifications section in the left sidebar.';

	/// en: 'Find and select the Cockpit application from the list.'
	String get step3 => 'Find and select the Cockpit application from the list.';

	/// en: 'Toggle the Allow Notifications switch on.'
	String get step4 => 'Toggle the Allow Notifications switch on.';

	/// en: 'Tip: If the app does not appear in the list, close and reopen it to trigger its registration in the system.'
	String get tip => 'Tip: If the app does not appear in the list, close and reopen it to trigger its registration in the system.';

	/// en: 'Got it'
	String get gotIt => 'Got it';
}

// Path: settings.language
class Translations$settings$language$en {
	Translations$settings$language$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Language'
	String get title => 'Language';

	/// en: 'System'
	String get system => 'System';

	/// en: 'English'
	String get english => 'English';

	/// en: 'Português (BR)'
	String get portugueseBr => 'Português (BR)';

	/// en: 'Español'
	String get spanish => 'Español';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'core.bootstrapError.title' => 'Failed to initialize Cockpit',
			'core.bootstrapError.retry' => 'Retry',
			'core.macosNotifications.title' => 'Enable Notifications on macOS',
			'core.macosNotifications.intro' => 'Notifications are currently disabled in your system settings. Follow the steps below to enable them:',
			'core.macosNotifications.step1' => 'Open System Settings on your Mac.',
			'core.macosNotifications.step2' => 'Navigate to the Notifications section in the left sidebar.',
			'core.macosNotifications.step3' => 'Find and select the Cockpit application from the list.',
			'core.macosNotifications.step4' => 'Toggle the Allow Notifications switch on.',
			'core.macosNotifications.tip' => 'Tip: If the app does not appear in the list, close and reopen it to trigger its registration in the system.',
			'core.macosNotifications.gotIt' => 'Got it',
			'settings.language.title' => 'Language',
			'settings.language.system' => 'System',
			'settings.language.english' => 'English',
			'settings.language.portugueseBr' => 'Português (BR)',
			'settings.language.spanish' => 'Español',
			_ => null,
		};
	}
}
