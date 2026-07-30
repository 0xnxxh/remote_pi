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
	late final Translations$common$en common = Translations$common$en.internal(_root);
	late final Translations$cockpit$en cockpit = Translations$cockpit$en.internal(_root);
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

// Path: common
class Translations$common$en {
	Translations$common$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	/// en: 'Create'
	String get create => 'Create';

	/// en: 'Got it'
	String get gotIt => 'Got it';
}

// Path: cockpit
class Translations$cockpit$en {
	Translations$cockpit$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$cockpit$confirmDialog$en confirmDialog = Translations$cockpit$confirmDialog$en.internal(_root);
	late final Translations$cockpit$historyDialog$en historyDialog = Translations$cockpit$historyDialog$en.internal(_root);
	late final Translations$cockpit$worktreeCreateDialog$en worktreeCreateDialog = Translations$cockpit$worktreeCreateDialog$en.internal(_root);
	late final Translations$cockpit$subfolderDialog$en subfolderDialog = Translations$cockpit$subfolderDialog$en.internal(_root);
	late final Translations$cockpit$commitMessageDialog$en commitMessageDialog = Translations$cockpit$commitMessageDialog$en.internal(_root);
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

// Path: cockpit.confirmDialog
class Translations$cockpit$confirmDialog$en {
	Translations$cockpit$confirmDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Unsaved changes'
	String get unsavedChangesTitle => 'Unsaved changes';

	/// en: '“${fileName}” has unsaved changes. Save them before closing?'
	String unsavedChangesMessage({required Object fileName}) => '“${fileName}” has unsaved changes. Save them before closing?';

	/// en: 'Don't save'
	String get dontSave => 'Don\'t save';

	/// en: 'Save & close'
	String get saveAndClose => 'Save & close';
}

// Path: cockpit.historyDialog
class Translations$cockpit$historyDialog$en {
	Translations$cockpit$historyDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Session history'
	String get title => 'Session history';

	/// en: 'Opening one replaces this agent's current transcript'
	String get subtitle => 'Opening one replaces this agent\'s current transcript';

	/// en: 'No saved sessions in this folder.'
	String get empty => 'No saved sessions in this folder.';

	/// en: 'Untitled session'
	String get untitledSession => 'Untitled session';

	/// en: 'now'
	String get justNow => 'now';

	/// en: '${n} min ago'
	String minutesAgo({required Object n}) => '${n} min ago';

	/// en: '${n} h ago'
	String hoursAgo({required Object n}) => '${n} h ago';

	/// en: '${n} d ago'
	String daysAgo({required Object n}) => '${n} d ago';
}

// Path: cockpit.worktreeCreateDialog
class Translations$cockpit$worktreeCreateDialog$en {
	Translations$cockpit$worktreeCreateDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Fork worktree'
	String get forkTitle => 'Fork worktree';

	/// en: 'Create worktree'
	String get createTitle => 'Create worktree';

	/// en: 'New worktree branched from ${root}.'
	String forkSubtitle({required Object root}) => 'New worktree branched from ${root}.';

	/// en: 'New feature in ${root} — new branch from the current HEAD.'
	String createSubtitle({required Object root}) => 'New feature in ${root} — new branch from the current HEAD.';

	/// en: 'feat/minha-feature'
	String get namePlaceholder => 'feat/minha-feature';

	/// en: 'No spaces in the name.'
	String get errorWhitespace => 'No spaces in the name.';

	/// en: 'Invalid character for a branch name.'
	String get errorInvalidChar => 'Invalid character for a branch name.';

	/// en: 'Invalid sequence (e.g. "..", "//", starting/ending with "/").'
	String get errorInvalidSequence => 'Invalid sequence (e.g. "..", "//", starting/ending with "/").';

	/// en: 'Reserved position (do not start with "-"/"." or end with ".lock").'
	String get errorReserved => 'Reserved position (do not start with "-"/"." or end with ".lock").';

	/// en: 'A branch with that name already exists.'
	String get errorDuplicateBranch => 'A branch with that name already exists.';

	/// en: 'A worktree with that name already exists.'
	String get errorDuplicateWorktree => 'A worktree with that name already exists.';

	/// en: 'Fork'
	String get fork => 'Fork';
}

// Path: cockpit.subfolderDialog
class Translations$cockpit$subfolderDialog$en {
	Translations$cockpit$subfolderDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Where to work?'
	String get title => 'Where to work?';

	/// en: 'No subfolders here.'
	String get empty => 'No subfolders here.';

	/// en: 'Use the root of ${project}'
	String useRoot({required Object project}) => 'Use the root of ${project}';

	/// en: 'Use ${project}/${rel}'
	String usePath({required Object project, required Object rel}) => 'Use ${project}/${rel}';

	/// en: 'Use this folder'
	String get useThisFolder => 'Use this folder';
}

// Path: cockpit.commitMessageDialog
class Translations$cockpit$commitMessageDialog$en {
	Translations$cockpit$commitMessageDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Commit'
	String get commitTitle => 'Commit';

	/// en: 'Stage and Commit'
	String get stageAndCommitTitle => 'Stage and Commit';

	/// en: 'Commit "${fileName}" only.'
	String scopeNote({required Object fileName}) => 'Commit "${fileName}" only.';

	/// en: 'fix: short summary of the change'
	String get placeholder => 'fix: short summary of the change';

	/// en: 'The first line (subject) cannot be empty.'
	String get errorEmptySubject => 'The first line (subject) cannot be empty.';

	/// en: 'Subject too short (min ${min} characters).'
	String errorTooShort({required Object min}) => 'Subject too short (min ${min} characters).';

	/// en: 'Subject too long (max ${max} characters).'
	String errorTooLong({required Object max}) => 'Subject too long (max ${max} characters).';

	/// en: 'Subject should not end with a period.'
	String get errorTrailingPeriod => 'Subject should not end with a period.';

	/// en: 'Subject contains control characters.'
	String get errorControlChars => 'Subject contains control characters.';

	/// en: 'Leave the second line blank (git subject/body separator).'
	String get errorBlankSecondLine => 'Leave the second line blank (git subject/body separator).';
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
			'common.cancel' => 'Cancel',
			'common.confirm' => 'Confirm',
			'common.create' => 'Create',
			'common.gotIt' => 'Got it',
			'cockpit.confirmDialog.unsavedChangesTitle' => 'Unsaved changes',
			'cockpit.confirmDialog.unsavedChangesMessage' => ({required Object fileName}) => '“${fileName}” has unsaved changes. Save them before closing?',
			'cockpit.confirmDialog.dontSave' => 'Don\'t save',
			'cockpit.confirmDialog.saveAndClose' => 'Save & close',
			'cockpit.historyDialog.title' => 'Session history',
			'cockpit.historyDialog.subtitle' => 'Opening one replaces this agent\'s current transcript',
			'cockpit.historyDialog.empty' => 'No saved sessions in this folder.',
			'cockpit.historyDialog.untitledSession' => 'Untitled session',
			'cockpit.historyDialog.justNow' => 'now',
			'cockpit.historyDialog.minutesAgo' => ({required Object n}) => '${n} min ago',
			'cockpit.historyDialog.hoursAgo' => ({required Object n}) => '${n} h ago',
			'cockpit.historyDialog.daysAgo' => ({required Object n}) => '${n} d ago',
			'cockpit.worktreeCreateDialog.forkTitle' => 'Fork worktree',
			'cockpit.worktreeCreateDialog.createTitle' => 'Create worktree',
			'cockpit.worktreeCreateDialog.forkSubtitle' => ({required Object root}) => 'New worktree branched from ${root}.',
			'cockpit.worktreeCreateDialog.createSubtitle' => ({required Object root}) => 'New feature in ${root} — new branch from the current HEAD.',
			'cockpit.worktreeCreateDialog.namePlaceholder' => 'feat/minha-feature',
			'cockpit.worktreeCreateDialog.errorWhitespace' => 'No spaces in the name.',
			'cockpit.worktreeCreateDialog.errorInvalidChar' => 'Invalid character for a branch name.',
			'cockpit.worktreeCreateDialog.errorInvalidSequence' => 'Invalid sequence (e.g. "..", "//", starting/ending with "/").',
			'cockpit.worktreeCreateDialog.errorReserved' => 'Reserved position (do not start with "-"/"." or end with ".lock").',
			'cockpit.worktreeCreateDialog.errorDuplicateBranch' => 'A branch with that name already exists.',
			'cockpit.worktreeCreateDialog.errorDuplicateWorktree' => 'A worktree with that name already exists.',
			'cockpit.worktreeCreateDialog.fork' => 'Fork',
			'cockpit.subfolderDialog.title' => 'Where to work?',
			'cockpit.subfolderDialog.empty' => 'No subfolders here.',
			'cockpit.subfolderDialog.useRoot' => ({required Object project}) => 'Use the root of ${project}',
			'cockpit.subfolderDialog.usePath' => ({required Object project, required Object rel}) => 'Use ${project}/${rel}',
			'cockpit.subfolderDialog.useThisFolder' => 'Use this folder',
			'cockpit.commitMessageDialog.commitTitle' => 'Commit',
			'cockpit.commitMessageDialog.stageAndCommitTitle' => 'Stage and Commit',
			'cockpit.commitMessageDialog.scopeNote' => ({required Object fileName}) => 'Commit "${fileName}" only.',
			'cockpit.commitMessageDialog.placeholder' => 'fix: short summary of the change',
			'cockpit.commitMessageDialog.errorEmptySubject' => 'The first line (subject) cannot be empty.',
			'cockpit.commitMessageDialog.errorTooShort' => ({required Object min}) => 'Subject too short (min ${min} characters).',
			'cockpit.commitMessageDialog.errorTooLong' => ({required Object max}) => 'Subject too long (max ${max} characters).',
			'cockpit.commitMessageDialog.errorTrailingPeriod' => 'Subject should not end with a period.',
			'cockpit.commitMessageDialog.errorControlChars' => 'Subject contains control characters.',
			'cockpit.commitMessageDialog.errorBlankSecondLine' => 'Leave the second line blank (git subject/body separator).',
			'settings.language.title' => 'Language',
			'settings.language.system' => 'System',
			'settings.language.english' => 'English',
			'settings.language.portugueseBr' => 'Português (BR)',
			'settings.language.spanish' => 'Español',
			_ => null,
		};
	}
}
