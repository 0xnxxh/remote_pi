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

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Done'
	String get done => 'Done';

	/// en: 'Add'
	String get add => 'Add';

	/// en: 'Test'
	String get test => 'Test';

	/// en: 'OK'
	String get ok => 'OK';

	/// en: 'Loading…'
	String get loading => 'Loading…';

	/// en: 'Checking…'
	String get checking => 'Checking…';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Restart'
	String get restart => 'Restart';
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
	late final Translations$cockpit$agentEditDialog$en agentEditDialog = Translations$cockpit$agentEditDialog$en.internal(_root);
	late final Translations$cockpit$agentSetupChecklist$en agentSetupChecklist = Translations$cockpit$agentSetupChecklist$en.internal(_root);
	late final Translations$cockpit$agentComposer$en agentComposer = Translations$cockpit$agentComposer$en.internal(_root);
	late final Translations$cockpit$welcomeView$en welcomeView = Translations$cockpit$welcomeView$en.internal(_root);
	late final Translations$cockpit$modelPicker$en modelPicker = Translations$cockpit$modelPicker$en.internal(_root);
	late final Translations$cockpit$paneView$en paneView = Translations$cockpit$paneView$en.internal(_root);
	late final Translations$cockpit$fileViewer$en fileViewer = Translations$cockpit$fileViewer$en.internal(_root);
	late final Translations$cockpit$workspaceSettingsDialog$en workspaceSettingsDialog = Translations$cockpit$workspaceSettingsDialog$en.internal(_root);
	late final Translations$cockpit$realmDialogs$en realmDialogs = Translations$cockpit$realmDialogs$en.internal(_root);
	late final Translations$cockpit$dbRedisTable$en dbRedisTable = Translations$cockpit$dbRedisTable$en.internal(_root);
	late final Translations$cockpit$dbQueryView$en dbQueryView = Translations$cockpit$dbQueryView$en.internal(_root);
	late final Translations$cockpit$dbMongoView$en dbMongoView = Translations$cockpit$dbMongoView$en.internal(_root);
	late final Translations$cockpit$dbConnectionDialog$en dbConnectionDialog = Translations$cockpit$dbConnectionDialog$en.internal(_root);
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$settings$language$en language = Translations$settings$language$en.internal(_root);
	late final Translations$settings$revokeDialog$en revokeDialog = Translations$settings$revokeDialog$en.internal(_root);
	late final Translations$settings$pairingDialog$en pairingDialog = Translations$settings$pairingDialog$en.internal(_root);
	late final Translations$settings$page$en page = Translations$settings$page$en.internal(_root);
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

// Path: cockpit.agentEditDialog
class Translations$cockpit$agentEditDialog$en {
	Translations$cockpit$agentEditDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Edit agent'
	String get title => 'Edit agent';

	/// en: 'Agent name'
	String get agentName => 'Agent name';

	/// en: 'Relay (remote-pi)'
	String get relaySection => 'Relay (remote-pi)';

	/// en: 'Auto-connect on start'
	String get autoConnect => 'Auto-connect on start';

	/// en: 'Information'
	String get informationSection => 'Information';

	/// en: 'Folder'
	String get folder => 'Folder';

	/// en: 'Model'
	String get model => 'Model';

	/// en: 'State'
	String get state => 'State';

	/// en: 'Context'
	String get context => 'Context';

	/// en: 'empty'
	String get statusEmpty => 'empty';

	/// en: 'starting'
	String get statusStarting => 'starting';

	/// en: 'ready'
	String get statusReady => 'ready';

	/// en: 'streaming'
	String get statusStreaming => 'streaming';

	/// en: 'ended'
	String get statusEnded => 'ended';
}

// Path: cockpit.agentSetupChecklist
class Translations$cockpit$agentSetupChecklist$en {
	Translations$cockpit$agentSetupChecklist$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Set up the agent environment'
	String get title => 'Set up the agent environment';

	/// en: 'Running an agent needs Pi installed. Complete the steps below — terminals and files work without any of this.'
	String get intro => 'Running an agent needs Pi installed. Complete the steps below — terminals and files work without any of this.';

	/// en: 'Pi Code installed'
	String get step1Title => 'Pi Code installed';

	/// en: 'The `pi` binary must be accessible.'
	String get step1Description => 'The `pi` binary must be accessible.';

	/// en: 'remote-pi extension on Pi'
	String get step2Title => 'remote-pi extension on Pi';

	/// en: 'Registered in ~/.pi/agent/settings.json.'
	String get step2Description => 'Registered in ~/.pi/agent/settings.json.';

	/// en: 'Supervisor installed'
	String get step3Title => 'Supervisor installed';

	/// en: 'pi-supervisord service (remote-pi install).'
	String get step3Description => 'pi-supervisord service (remote-pi install).';

	/// en: 'Install'
	String get install => 'Install';

	/// en: 'Install remote-pi extension'
	String get installExtensionTitle => 'Install remote-pi extension';

	/// en: 'Install supervisor'
	String get installSupervisorTitle => 'Install supervisor';

	/// en: 'Create agent'
	String get createAgent => 'Create agent';

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Check again'
	String get checkAgain => 'Check again';

	/// en: 'Not required in this setup'
	String get notRequired => 'Not required in this setup';

	/// en: 'Installing…'
	String get installing => 'Installing…';

	/// en: 'Installed successfully.'
	String get installedSuccessfully => 'Installed successfully.';
}

// Path: cockpit.agentComposer
class Translations$cockpit$agentComposer$en {
	Translations$cockpit$agentComposer$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'New session — clears the conversation'
	String get cmdNewDescription => 'New session — clears the conversation';

	/// en: 'Compacts the agent context'
	String get cmdCompactDescription => 'Compacts the agent context';

	/// en: 'Attach file'
	String get attachFile => 'Attach file';

	/// en: 'Maximum of ${max} images.'
	String maxImages({required Object max}) => 'Maximum of ${max} images.';

	/// en: 'Message to the agent, use @files or /commands'
	String get placeholder => 'Message to the agent, use @files or /commands';

	/// en: 'Stop'
	String get stop => 'Stop';

	/// en: 'Send'
	String get send => 'Send';

	/// en: 'Relay online'
	String get relayOnline => 'Relay online';

	/// en: 'Relay reconnecting...'
	String get relayReconnecting => 'Relay reconnecting...';

	/// en: 'Relay offline'
	String get relayOffline => 'Relay offline';

	/// en: 'Context: ${pct}% of the window'
	String contextTooltip({required Object pct}) => 'Context: ${pct}% of the window';

	/// en: 'The current model cannot see images — switch to one with vision.'
	String get visionWarning => 'The current model cannot see images — switch to one with vision.';

	/// en: 'model'
	String get modelFallback => 'model';
}

// Path: cockpit.welcomeView
class Translations$cockpit$welcomeView$en {
	Translations$cockpit$welcomeView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Welcome to Cockpit'
	String get title => 'Welcome to Cockpit';

	/// en: 'Open a folder to start a workspace.'
	String get subtitle => 'Open a folder to start a workspace.';

	/// en: 'Create workspace'
	String get createWorkspace => 'Create workspace';
}

// Path: cockpit.modelPicker
class Translations$cockpit$modelPicker$en {
	Translations$cockpit$modelPicker$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Search model (${count})'
	String search({required Object count}) => 'Search model (${count})';
}

// Path: cockpit.paneView
class Translations$cockpit$paneView$en {
	Translations$cockpit$paneView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Close pane?'
	String get closePaneTitle => 'Close pane?';

	/// en: 'This closes all ${count} tab(s) in this pane and ends the agents/terminals in it.'
	String closePaneMessage({required Object count}) => 'This closes all ${count} tab(s) in this pane and ends the agents/terminals in it.';

	/// en: 'Close'
	String get close => 'Close';

	/// en: 'All tabs'
	String get allTabs => 'All tabs';

	/// en: 'Pin tab'
	String get pinTab => 'Pin tab';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Reset Title'
	String get resetTitle => 'Reset Title';

	/// en: 'Copy Id'
	String get copyId => 'Copy Id';

	/// en: 'Auto-relay'
	String get autoRelay => 'Auto-relay';

	/// en: 'History'
	String get history => 'History';

	/// en: 'New tab'
	String get newTab => 'New tab';

	/// en: 'New terminal…'
	String get newTerminal => 'New terminal…';

	/// en: 'Split right'
	String get splitRight => 'Split right';

	/// en: 'Split down'
	String get splitDown => 'Split down';

	/// en: 'Close pane'
	String get closePane => 'Close pane';

	/// en: 'Drop here to move the tab'
	String get dropHereToMove => 'Drop here to move the tab';

	/// en: 'Dock as tab'
	String get dockAsTab => 'Dock as tab';
}

// Path: cockpit.fileViewer
class Translations$cockpit$fileViewer$en {
	Translations$cockpit$fileViewer$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Can't open this file.'
	String get cantOpen => 'Can\'t open this file.';

	/// en: 'Could not load the image.'
	String get couldNotLoadImage => 'Could not load the image.';

	/// en: 'Preview'
	String get preview => 'Preview';

	/// en: 'Source'
	String get source => 'Source';
}

// Path: cockpit.workspaceSettingsDialog
class Translations$cockpit$workspaceSettingsDialog$en {
	Translations$cockpit$workspaceSettingsDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Choose workspace photo'
	String get choosePhotoTitle => 'Choose workspace photo';

	/// en: 'Workspace settings'
	String get title => 'Workspace settings';

	/// en: 'Workspace name'
	String get namePlaceholder => 'Workspace name';

	/// en: 'Add photo'
	String get addPhoto => 'Add photo';

	/// en: 'Change photo'
	String get changePhoto => 'Change photo';

	/// en: 'Remove'
	String get remove => 'Remove';

	/// en: 'Color'
	String get color => 'Color';

	/// en: 'Folder'
	String get folder => 'Folder';
}

// Path: cockpit.realmDialogs
class Translations$cockpit$realmDialogs$en {
	Translations$cockpit$realmDialogs$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Realm name'
	String get namePlaceholder => 'Realm name';

	/// en: 'A realm with this name already exists.'
	String get duplicateName => 'A realm with this name already exists.';

	/// en: 'New realm'
	String get newRealmTitle => 'New realm';

	/// en: 'Rename realm'
	String get renameRealmTitle => 'Rename realm';

	/// en: 'Rename'
	String get rename => 'Rename';

	/// en: 'Delete realm'
	String get deleteRealmTitle => 'Delete realm';

	/// en: 'Delete "${name}"? No workspace is deleted — the folder list just changes.${suffix}'
	String deleteMessage({required Object name, required Object suffix}) => 'Delete "${name}"? No workspace is deleted — the folder list just changes.${suffix}';

	/// en: ' Its workspace will move to Default.'
	String get deleteSuffixOne => ' Its workspace will move to Default.';

	/// en: ' Its ${count} workspaces will move to Default.'
	String deleteSuffixMany({required Object count}) => ' Its ${count} workspaces will move to Default.';

	/// en: 'Manage realms'
	String get manageRealmsTitle => 'Manage realms';

	/// en: '(one) {1 workspace} (other) {${n} workspaces}'
	String workspaceCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 workspace',
		other: '${n} workspaces',
	);
}

// Path: cockpit.dbRedisTable
class Translations$cockpit$dbRedisTable$en {
	Translations$cockpit$dbRedisTable$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Delete key'
	String get deleteKeyTitle => 'Delete key';

	/// en: 'Delete "${key}" from this Redis database?'
	String deleteKeyMessage({required Object key}) => 'Delete "${key}" from this Redis database?';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'New key'
	String get newKey => 'New key';

	/// en: 'KEY'
	String get columnKey => 'KEY';

	/// en: 'VALUE'
	String get columnValue => 'VALUE';

	/// en: 'TYPE'
	String get columnType => 'TYPE';

	/// en: 'TTL'
	String get columnTtl => 'TTL';

	/// en: '(one) {1 key} (other) {${n} keys}'
	String keyCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 key',
		other: '${n} keys',
	);

	/// en: 'No keys in this database.'
	String get noKeys => 'No keys in this database.';

	/// en: 'No keys match "${pattern}".'
	String noKeysMatch({required Object pattern}) => 'No keys match "${pattern}".';

	/// en: 'Load more'
	String get loadMore => 'Load more';

	/// en: 'Loading full value…'
	String get loadingFullValue => 'Loading full value…';

	/// en: 'TTL must be a number of seconds.'
	String get ttlMustBeNumber => 'TTL must be a number of seconds.';

	/// en: 'Add key'
	String get addKey => 'Add key';

	/// en: 'key'
	String get keyFieldHint => 'key';

	/// en: 'ttl (s, optional)'
	String get ttlFieldHint => 'ttl (s, optional)';

	/// en: 'value'
	String get valueFieldHint => 'value';

	/// en: 'Search — pattern, e.g. user:*'
	String get searchHint => 'Search — pattern, e.g. user:*';
}

// Path: cockpit.dbQueryView
class Translations$cockpit$dbQueryView$en {
	Translations$cockpit$dbQueryView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Save query as'
	String get saveQueryAs => 'Save query as';

	/// en: 'Could not save'
	String get couldNotSave => 'Could not save';

	/// en: 'Select database'
	String get selectDatabase => 'Select database';

	/// en: 'No SQL connections — add one in the Database panel'
	String get noSqlConnections => 'No SQL connections — add one in the Database panel';

	/// en: 'Running…'
	String get running => 'Running…';

	/// en: 'Run selection'
	String get runSelection => 'Run selection';

	/// en: 'Run'
	String get run => 'Run';

	/// en: 'Pick a database above, then Run (⌘↵).'
	String get pickDatabaseHint => 'Pick a database above, then Run (⌘↵).';

	/// en: 'Run the query (⌘↵) to see results here.'
	String get runQueryHint => 'Run the query (⌘↵) to see results here.';

	/// en: 'No rows.'
	String get noRows => 'No rows.';

	/// en: '(one) {1 row affected} (other) {${n} rows affected}'
	String rowsAffected({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 row affected',
		other: '${n} rows affected',
	);

	/// en: '${n} rows'
	String rowsFooter({required Object n}) => '${n} rows';

	/// en: ' · truncated (raise -- limit)'
	String get truncatedSuffix => ' · truncated (raise -- limit)';

	/// en: 'Table'
	String get table => 'Table';

	/// en: 'JSON'
	String get json => 'JSON';

	/// en: 'unsaved'
	String get unsaved => 'unsaved';

	/// en: 'saved'
	String get saved => 'saved';

	/// en: 'Copied'
	String get copied => 'Copied';

	/// en: 'Copy'
	String get copy => 'Copy';
}

// Path: cockpit.dbMongoView
class Translations$cockpit$dbMongoView$en {
	Translations$cockpit$dbMongoView$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Delete document'
	String get deleteDocumentTitle => 'Delete document';

	/// en: 'Delete the document with _id ${id} from "${collection}"?'
	String deleteDocumentMessage({required Object id, required Object collection}) => 'Delete the document with _id ${id} from "${collection}"?';

	/// en: 'Filter — JSON, e.g. {"status": "active"}'
	String get filterHint => 'Filter — JSON, e.g. {"status": "active"}';

	/// en: '(one) {1 doc} (other) {${n} docs}'
	String docCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '1 doc',
		other: '${n} docs',
	);

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'Insert document'
	String get insertDocument => 'Insert document';

	/// en: 'No documents in this collection.'
	String get noDocuments => 'No documents in this collection.';

	/// en: 'No documents match this filter.'
	String get noDocumentsMatch => 'No documents match this filter.';

	/// en: 'Load more'
	String get loadMore => 'Load more';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Insert'
	String get insert => 'Insert';
}

// Path: cockpit.dbConnectionDialog
class Translations$cockpit$dbConnectionDialog$en {
	Translations$cockpit$dbConnectionDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Choose SQLite database'
	String get chooseFileTitle => 'Choose SQLite database';

	/// en: 'File'
	String get file => 'File';

	/// en: 'Choose a SQLite file…'
	String get chooseFilePlaceholder => 'Choose a SQLite file…';

	/// en: 'Name'
	String get name => 'Name';

	/// en: 'Host'
	String get host => 'Host';

	/// en: 'Port'
	String get port => 'Port';

	/// en: 'Database'
	String get database => 'Database';

	/// en: 'User'
	String get user => 'User';

	/// en: 'Password'
	String get password => 'Password';

	/// en: 'Save Password'
	String get savePassword => 'Save Password';

	/// en: 'Use SSL/TLS'
	String get useTls => 'Use SSL/TLS';

	/// en: 'implied by mongodb+srv'
	String get tlsHintSrv => 'implied by mongodb+srv';

	/// en: 'managed DBs (RDS, Atlas…) usually require it'
	String get tlsHintManaged => 'managed DBs (RDS, Atlas…) usually require it';

	/// en: 'Allow writes (agents)'
	String get allowWrites => 'Allow writes (agents)';

	/// en: 'off = agents can only read via CLI'
	String get allowWritesHint => 'off = agents can only read via CLI';

	/// en: 'Visible to agents'
	String get visibleToAgents => 'Visible to agents';

	/// en: 'off = hidden from the CLI, GUI only'
	String get visibleToAgentsHint => 'off = hidden from the CLI, GUI only';

	/// en: 'Testing connection…'
	String get testing => 'Testing connection…';

	/// en: 'Connection OK'
	String get connectionOk => 'Connection OK';

	/// en: 'Connection failed'
	String get connectionFailed => 'Connection failed';

	/// en: 'Edit connection'
	String get editTitle => 'Edit connection';

	/// en: 'New connection'
	String get newTitle => 'New connection';
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

// Path: settings.revokeDialog
class Translations$settings$revokeDialog$en {
	Translations$settings$revokeDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Device removed.'
	String get deviceRemoved => 'Device removed.';

	/// en: 'Failed to revoke the device.'
	String get failedToRevoke => 'Failed to revoke the device.';

	/// en: 'Revoking…'
	String get revoking => 'Revoking…';

	/// en: 'Revoking ${name}…'
	String revokingDevice({required Object name}) => 'Revoking ${name}…';

	/// en: 'Connecting to the relay and removing access.'
	String get connectingMessage => 'Connecting to the relay and removing access.';

	/// en: 'Ok'
	String get ok => 'Ok';
}

// Path: settings.pairingDialog
class Translations$settings$pairingDialog$en {
	Translations$settings$pairingDialog$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Pair device'
	String get title => 'Pair device';

	/// en: 'Connecting to the relay…'
	String get connectingToRelay => 'Connecting to the relay…';

	/// en: 'Open the Remote Pi app on your phone.'
	String get step1 => 'Open the Remote Pi app on your phone.';

	/// en: 'Tap add / pair device.'
	String get step2 => 'Tap add / pair device.';

	/// en: 'Point the camera at the QR below.'
	String get step3 => 'Point the camera at the QR below.';

	/// en: 'Could not generate the QR.'
	String get qrGenerationFailed => 'Could not generate the QR.';

	/// en: 'The code refreshes on its own. Keep this window open.'
	String get autoRefreshHint => 'The code refreshes on its own. Keep this window open.';

	/// en: 'Pairing failed.'
	String get pairingFailed => 'Pairing failed.';

	/// en: 'Try again'
	String get tryAgain => 'Try again';

	/// en: 'Copied!'
	String get copied => 'Copied!';

	/// en: 'Copy data'
	String get copyData => 'Copy data';
}

// Path: settings.page
class Translations$settings$page$en {
	Translations$settings$page$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$settings$page$header$en header = Translations$settings$page$header$en.internal(_root);
	late final Translations$settings$page$nav$en nav = Translations$settings$page$nav$en.internal(_root);
	late final Translations$settings$page$general$en general = Translations$settings$page$general$en.internal(_root);
	late final Translations$settings$page$diagnostics$en diagnostics = Translations$settings$page$diagnostics$en.internal(_root);
	late final Translations$settings$page$storage$en storage = Translations$settings$page$storage$en.internal(_root);
	late final Translations$settings$page$terminal$en terminal = Translations$settings$page$terminal$en.internal(_root);
	late final Translations$settings$page$appearance$en appearance = Translations$settings$page$appearance$en.internal(_root);
	late final Translations$settings$page$notifications$en notifications = Translations$settings$page$notifications$en.internal(_root);
	late final Translations$settings$page$shortcuts$en shortcuts = Translations$settings$page$shortcuts$en.internal(_root);
	late final Translations$settings$page$languages$en languages = Translations$settings$page$languages$en.internal(_root);
	late final Translations$settings$page$connectivity$en connectivity = Translations$settings$page$connectivity$en.internal(_root);
	late final Translations$settings$page$schedules$en schedules = Translations$settings$page$schedules$en.internal(_root);
	late final Translations$settings$page$daemons$en daemons = Translations$settings$page$daemons$en.internal(_root);
}

// Path: settings.page.header
class Translations$settings$page$header$en {
	Translations$settings$page$header$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Settings'
	String get title => 'Settings';
}

// Path: settings.page.nav
class Translations$settings$page$nav$en {
	Translations$settings$page$nav$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'General'
	String get general => 'General';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Terminal'
	String get terminal => 'Terminal';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Shortcuts'
	String get shortcuts => 'Shortcuts';

	/// en: 'Notifications'
	String get notifications => 'Notifications';

	/// en: 'Connectivity'
	String get connectivity => 'Connectivity';

	/// en: 'Daemon Agents'
	String get daemonAgents => 'Daemon Agents';

	/// en: 'Schedules'
	String get schedules => 'Schedules';
}

// Path: settings.page.general
class Translations$settings$page$general$en {
	Translations$settings$page$general$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Agent'
	String get sectionAgent => 'Agent';

	/// en: 'Enable agents'
	String get enableAgentsTitle => 'Enable agents';

	/// en: 'Show the option to open agent tabs (pi). When off, Cockpit works as a terminal-only workspace.'
	String get enableAgentsDesc => 'Show the option to open agent tabs (pi). When off, Cockpit works as a terminal-only workspace.';

	/// en: 'Show Cockpit terminal'
	String get showCockpitTitle => 'Show Cockpit terminal';

	/// en: 'Keep a pathless, terminal-only workspace pinned at the top of the rail. Turning it off closes its terminals.'
	String get showCockpitDesc => 'Keep a pathless, terminal-only workspace pinned at the top of the rail. Turning it off closes its terminals.';

	/// en: 'Updates'
	String get sectionUpdates => 'Updates';

	/// en: 'Check for updates'
	String get checkUpdatesTitle => 'Check for updates';

	/// en: 'How often Cockpit should look for new versions.'
	String get checkUpdatesDesc => 'How often Cockpit should look for new versions.';

	/// en: 'Can't turn agents off while an agent tab is open. Close all agent tabs first, then disable it.'
	String get agentsInUseError => 'Can\'t turn agents off while an agent tab is open. Close all agent tabs first, then disable it.';

	late final Translations$settings$page$general$updateFrequency$en updateFrequency = Translations$settings$page$general$updateFrequency$en.internal(_root);
}

// Path: settings.page.diagnostics
class Translations$settings$page$diagnostics$en {
	Translations$settings$page$diagnostics$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Diagnostics'
	String get sectionTitle => 'Diagnostics';

	/// en: 'Log file'
	String get logFileTitle => 'Log file';

	/// en: 'Errors and startup events are recorded here, kept for ${days} days. ${path}'
	String logFileDesc({required Object days, required Object path}) => 'Errors and startup events are recorded here, kept for ${days} days.\n${path}';

	/// en: 'unavailable'
	String get unavailable => 'unavailable';

	/// en: 'Reveal'
	String get reveal => 'Reveal';

	/// en: 'Report a problem'
	String get reportTitle => 'Report a problem';

	/// en: 'Opens a pre-filled issue with your version, OS and recent log. Nothing is sent automatically — you review it first.'
	String get reportDesc => 'Opens a pre-filled issue with your version, OS and recent log. Nothing is sent automatically — you review it first.';

	/// en: 'Report…'
	String get reportButton => 'Report…';

	/// en: 'Problem report'
	String get reportDialogTitle => 'Problem report';

	/// en: 'Reported manually from Settings.'
	String get reportDialogError => 'Reported manually from Settings.';

	/// en: 'Describe what went wrong in the issue. The recent log is included below and in "Copy details".'
	String get reportDialogDescription => 'Describe what went wrong in the issue. The recent log is included below and in "Copy details".';
}

// Path: settings.page.storage
class Translations$settings$page$storage$en {
	Translations$settings$page$storage$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Storage'
	String get sectionTitle => 'Storage';

	/// en: 'Storage location'
	String get locationTitle => 'Storage location';

	/// en: 'Cockpit keeps its projects, layouts and settings here. Point it at a synced folder to back it up. ${root}'
	String locationDesc({required Object root}) => 'Cockpit keeps its projects, layouts and settings here. Point it at a synced folder to back it up.\n${root}';

	/// en: 'Use default'
	String get useDefault => 'Use default';

	/// en: 'Working…'
	String get working => 'Working…';

	/// en: 'Change…'
	String get change => 'Change…';

	/// en: 'Reset Cockpit'
	String get resetTitle => 'Reset Cockpit';

	/// en: 'Delete all local data — projects, layouts, settings and terminal history — and return to the default location.'
	String get resetDesc => 'Delete all local data — projects, layouts, settings and terminal history — and return to the default location.';

	/// en: 'Reset…'
	String get resetButton => 'Reset…';

	/// en: 'Reset'
	String get resetConfirm => 'Reset';

	/// en: 'Reset Cockpit?'
	String get resetDialogTitle => 'Reset Cockpit?';

	/// en: 'This permanently deletes all local Cockpit data — projects, layouts, settings and terminal history. This cannot be undone. Cockpit will close so you can start fresh.'
	String get resetDialogContent => 'This permanently deletes all local Cockpit data — projects, layouts, settings and terminal history. This cannot be undone. Cockpit will close so you can start fresh.';

	/// en: 'Restart required'
	String get restartRequiredTitle => 'Restart required';

	/// en: 'Cockpit will use this folder from the next launch: ${path}'
	String restartChangeFolderMessage({required Object path}) => 'Cockpit will use this folder from the next launch:\n${path}';

	/// en: 'Cockpit will use the default system location from the next launch. Your data in the custom folder is left untouched.'
	String get restartUseDefaultMessage => 'Cockpit will use the default system location from the next launch. Your data in the custom folder is left untouched.';

	/// en: 'All Cockpit data was cleared. Restart to start fresh.'
	String get restartResetMessage => 'All Cockpit data was cleared. Restart to start fresh.';

	/// en: 'Later'
	String get later => 'Later';

	/// en: 'Quit Cockpit'
	String get quitCockpit => 'Quit Cockpit';

	/// en: 'Choose a folder for Cockpit data'
	String get chooseFolderDialogTitle => 'Choose a folder for Cockpit data';
}

// Path: settings.page.terminal
class Translations$settings$page$terminal$en {
	Translations$settings$page$terminal$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Default terminal'
	String get sectionDefaultTerminal => 'Default terminal';

	/// en: 'Engine'
	String get engineTitle => 'Engine';

	/// en: 'Used by new terminal tabs and task output buffers. Open tabs keep their current engine.'
	String get engineDesc => 'Used by new terminal tabs and task output buffers. Open tabs keep their current engine.';

	/// en: 'Shell'
	String get shellTitle => 'Shell';

	/// en: 'Which shell new terminal tabs open. The arrow next to + still opens any other one, just for that tab.'
	String get shellDesc => 'Which shell new terminal tabs open. The arrow next to + still opens any other one, just for that tab.';

	/// en: 'No WSL distros found. Install one (wsl.exe --install) and restart Cockpit to see it listed here.'
	String get noWslMessage => 'No WSL distros found. Install one (wsl.exe --install) and restart Cockpit to see it listed here.';
}

// Path: settings.page.appearance
class Translations$settings$page$appearance$en {
	Translations$settings$page$appearance$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Theme'
	String get sectionTheme => 'Theme';

	/// en: 'System'
	String get themeSystem => 'System';

	/// en: 'Light'
	String get themeLight => 'Light';

	/// en: 'Dark'
	String get themeDark => 'Dark';

	/// en: 'Fonts'
	String get sectionFonts => 'Fonts';

	/// en: 'Interface font'
	String get interfaceFontTitle => 'Interface font';

	/// en: 'Used across the whole app. Empty = system default.'
	String get interfaceFontDesc => 'Used across the whole app. Empty = system default.';

	/// en: 'Interface size'
	String get interfaceSizeTitle => 'Interface size';

	/// en: 'Code font'
	String get codeFontTitle => 'Code font';

	/// en: 'Code and diffs. Empty = system default.'
	String get codeFontDesc => 'Code and diffs. Empty = system default.';

	/// en: 'Code size'
	String get codeSizeTitle => 'Code size';

	/// en: 'Terminal font'
	String get terminalFontTitle => 'Terminal font';

	/// en: 'Uses the code size. Empty = system default.'
	String get terminalFontDesc => 'Uses the code size. Empty = system default.';

	/// en: 'Syntax'
	String get sectionSyntax => 'Syntax';

	/// en: 'Highlight theme'
	String get highlightThemeTitle => 'Highlight theme';

	/// en: 'Code colors, independent of the app theme.'
	String get highlightThemeDesc => 'Code colors, independent of the app theme.';

	/// en: 'Conversation'
	String get sectionConversation => 'Conversation';

	/// en: 'Pin user message'
	String get pinUserMessageTitle => 'Pin user message';

	/// en: 'The question stays fixed at the top while the answer scrolls.'
	String get pinUserMessageDesc => 'The question stays fixed at the top while the answer scrolls.';
}

// Path: settings.page.notifications
class Translations$settings$page$notifications$en {
	Translations$settings$page$notifications$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Notifications'
	String get sectionTitle => 'Notifications';

	/// en: 'Enable notifications'
	String get enableTitle => 'Enable notifications';

	/// en: 'Alert me when an agent finishes a turn and the window is not focused.'
	String get enableDesc => 'Alert me when an agent finishes a turn and the window is not focused.';

	/// en: 'System permission'
	String get systemPermissionTitle => 'System permission';

	/// en: 'Cockpit is allowed to send notifications.'
	String get grantedDesc => 'Cockpit is allowed to send notifications.';

	/// en: 'macOS has not granted notification access yet.'
	String get notGrantedDesc => 'macOS has not granted notification access yet.';

	/// en: 'Granted'
	String get granted => 'Granted';

	/// en: 'Request permission'
	String get requestPermission => 'Request permission';

	/// en: 'Play sound on finish'
	String get playSoundTitle => 'Play sound on finish';

	/// en: 'Play a short chime when a turn finishes and the window is focused (on any tab or workspace).'
	String get playSoundDesc => 'Play a short chime when a turn finishes and the window is focused (on any tab or workspace).';
}

// Path: settings.page.shortcuts
class Translations$settings$page$shortcuts$en {
	Translations$settings$page$shortcuts$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Keyboard shortcuts are not customizable yet.'
	String get notCustomizable => 'Keyboard shortcuts are not customizable yet.';
}

// Path: settings.page.languages
class Translations$settings$page$languages$en {
	Translations$settings$page$languages$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'FORMATTING'
	String get sectionFormatting => 'FORMATTING';

	/// en: 'Format on save'
	String get formatOnSaveTitle => 'Format on save';

	/// en: 'Format the file automatically when you save (⌘S).'
	String get formatOnSaveDesc => 'Format the file automatically when you save (⌘S).';

	/// en: 'LANGUAGE SERVERS'
	String get sectionLanguageServers => 'LANGUAGE SERVERS';

	/// en: 'Errors and formatting use each language's language server. Cockpit does not install servers — it uses what is already on your machine. ● responds · ○ not found or invalid command (install the server or adjust the command).'
	String get footerNote => 'Errors and formatting use each language\'s language server. Cockpit does not install servers — it uses what is already on your machine. ● responds · ○ not found or invalid command (install the server or adjust the command).';

	/// en: 'Language server command'
	String get serverCommandLabel => 'Language server command';

	/// en: 'Formatter command (optional)'
	String get formatterCommandLabel => 'Formatter command (optional)';

	/// en: 'External formatter with %FILE% placeholder. Takes precedence over the LSP formatter when set.'
	String get formatterHint => 'External formatter with %FILE% placeholder. Takes precedence over the LSP formatter when set.';

	/// en: 'Reset to default'
	String get resetToDefault => 'Reset to default';

	/// en: 'Save & restart'
	String get saveAndRestart => 'Save & restart';

	/// en: 'Server responds'
	String get statusResponds => 'Server responds';

	/// en: 'Server not found or command invalid'
	String get statusNotFound => 'Server not found or command invalid';
}

// Path: settings.page.connectivity
class Translations$settings$page$connectivity$en {
	Translations$settings$page$connectivity$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Relay'
	String get sectionRelay => 'Relay';

	/// en: 'Paired devices'
	String get sectionPairedDevices => 'Paired devices';

	/// en: 'Reload'
	String get reloadTooltip => 'Reload';

	/// en: 'Failed to list devices.'
	String get failedToListDevices => 'Failed to list devices.';

	/// en: 'No paired devices.'
	String get noPairedDevices => 'No paired devices.';

	/// en: 'Relay address'
	String get relayAddressTitle => 'Relay address';

	/// en: 'Server that connects your agents to the phone. Applies to every agent with the relay enabled.'
	String get relayAddressDesc => 'Server that connects your agents to the phone. Applies to every agent with the relay enabled.';

	/// en: 'Saving…'
	String get saving => 'Saving…';

	/// en: 'Check'
	String get check => 'Check';

	/// en: 'Online'
	String get healthOnline => 'Online';

	/// en: 'No response'
	String get healthNoResponse => 'No response';

	/// en: 'Not checked'
	String get healthNotChecked => 'Not checked';

	/// en: 'Device'
	String get deviceDefaultLabel => 'Device';

	/// en: 'Revoke'
	String get revoke => 'Revoke';

	/// en: 'Pair new device'
	String get pairNewDevice => 'Pair new device';

	/// en: 'Revoke device?'
	String get revokeDialogTitle => 'Revoke device?';

	/// en: '"${name}" will lose access to your agents and will need to pair again. You must be connected to the relay — the app will connect automatically to revoke.'
	String revokeDialogContent({required Object name}) => '"${name}" will lose access to your agents and will need to pair again.\n\nYou must be connected to the relay — the app will connect automatically to revoke.';
}

// Path: settings.page.schedules
class Translations$settings$page$schedules$en {
	Translations$settings$page$schedules$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Scheduled prompts'
	String get sectionScheduledPrompts => 'Scheduled prompts';

	/// en: 'Create schedule'
	String get createSchedule => 'Create schedule';

	/// en: 'Create a Daemon Agent first.'
	String get createDaemonFirst => 'Create a Daemon Agent first.';

	/// en: 'Supervisor offline. Schedules need pi-supervisord running (`remote-pi install`).'
	String get supervisorOffline => 'Supervisor offline. Schedules need pi-supervisord running (`remote-pi install`).';

	/// en: 'Failed to list schedules.'
	String get failedToListSchedules => 'Failed to list schedules.';

	/// en: 'No schedules. Create a recurring prompt for a daemon.'
	String get noSchedules => 'No schedules. Create a recurring prompt for a daemon.';

	/// en: 'Run now'
	String get runNow => 'Run now';

	/// en: 'View log'
	String get viewLog => 'View log';

	/// en: 'disabled'
	String get disabled => 'disabled';

	/// en: 'next ${when}'
	String nextRun({required Object when}) => 'next ${when}';

	/// en: 'last: ${label}'
	String lastRun({required Object label}) => 'last: ${label}';

	/// en: 'Remove schedule?'
	String get removeScheduleDialogTitle => 'Remove schedule?';

	/// en: 'The job "${schedule}" for ${daemon} is deleted. Its runs stop.'
	String removeScheduleDialogContent({required Object schedule, required Object daemon}) => 'The job "${schedule}" for ${daemon} is deleted. Its runs stop.';

	/// en: 'New schedule'
	String get newScheduleTitle => 'New schedule';

	/// en: 'Daemon'
	String get daemonLabel => 'Daemon';

	/// en: 'When (cron expression)'
	String get whenLabel => 'When (cron expression)';

	/// en: 'Next run shows up here'
	String get previewPlaceholder => 'Next run shows up here';

	/// en: 'Next: computed on save'
	String get previewComputed => 'Next: computed on save';

	/// en: 'Next: ${when}'
	String previewNext({required Object when}) => 'Next: ${when}';

	/// en: 'every day 9am'
	String get exampleEveryDay9am => 'every day 9am';

	/// en: 'hourly'
	String get exampleHourly => 'hourly';

	/// en: 'every 15 min'
	String get exampleEvery15Min => 'every 15 min';

	/// en: 'weekdays 6pm'
	String get exampleWeekdays6pm => 'weekdays 6pm';

	/// en: 'Prompt'
	String get promptLabel => 'Prompt';

	/// en: 'Timezone (optional)'
	String get timezoneLabel => 'Timezone (optional)';

	/// en: 'Skip if the agent is busy'
	String get skipIfBusy => 'Skip if the agent is busy';

	/// en: 'Wake the daemon if stopped'
	String get wakeIfStopped => 'Wake the daemon if stopped';

	/// en: 'Recover 1 missed run (catchup)'
	String get catchup => 'Recover 1 missed run (catchup)';

	/// en: 'Fill in the expression and the prompt.'
	String get fillRequiredError => 'Fill in the expression and the prompt.';

	/// en: 'Creating…'
	String get creating => 'Creating…';

	/// en: 'Failed to create the schedule.'
	String get failedToCreateSchedule => 'Failed to create the schedule.';

	/// en: 'History — ${schedule}'
	String historyTitle({required Object schedule}) => 'History — ${schedule}';

	/// en: 'Failed to read the log.'
	String get failedToReadLog => 'Failed to read the log.';

	/// en: 'No records yet.'
	String get noRecordsYet => 'No records yet.';

	/// en: 'delivered'
	String get cronDelivered => 'delivered';

	/// en: 'woke + delivered'
	String get cronWokeDelivered => 'woke + delivered';

	/// en: 'failed'
	String get cronFailed => 'failed';

	/// en: 'skipped (busy)'
	String get cronSkippedBusy => 'skipped (busy)';

	/// en: 'skipped (stopped)'
	String get cronSkippedStopped => 'skipped (stopped)';

	/// en: 'skipped (disabled)'
	String get cronSkippedDisabled => 'skipped (disabled)';
}

// Path: settings.page.daemons
class Translations$settings$page$daemons$en {
	Translations$settings$page$daemons$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Always-on agents'
	String get sectionAlwaysOnAgents => 'Always-on agents';

	/// en: 'Create daemon'
	String get createDaemon => 'Create daemon';

	/// en: 'Start all'
	String get startAll => 'Start all';

	/// en: 'Stop all'
	String get stopAll => 'Stop all';

	/// en: 'Restart all'
	String get restartAll => 'Restart all';

	/// en: 'Restart supervisor'
	String get restartSupervisor => 'Restart supervisor';

	/// en: 'Restart the supervisor?'
	String get restartSupervisorDialogTitle => 'Restart the supervisor?';

	/// en: 'Restarts the supervisor process (reloads the code). All daemons restart with it and go offline for a few seconds.'
	String get restartSupervisorDialogContent => 'Restarts the supervisor process (reloads the code). All daemons restart with it and go offline for a few seconds.';

	/// en: 'Remove daemon?'
	String get removeDaemonDialogTitle => 'Remove daemon?';

	/// en: '"${name}" stops running and leaves the registry. The folder and its local config are kept — you can recreate it later.'
	String removeDaemonDialogContent({required Object name}) => '"${name}" stops running and leaves the registry. The folder and its local config are kept — you can recreate it later.';

	/// en: 'Supervisor offline'
	String get supervisorOfflineTitle => 'Supervisor offline';

	/// en: 'pi-supervisord is not running. Install it with `remote-pi install` to manage 24/7 agents.'
	String get supervisorOfflineDesc => 'pi-supervisord is not running. Install it with `remote-pi install` to manage 24/7 agents.';

	/// en: 'Failed to list daemons.'
	String get failedToListDaemons => 'Failed to list daemons.';

	/// en: 'No registered agents. Create one from a folder.'
	String get noRegisteredAgents => 'No registered agents. Create one from a folder.';

	/// en: 'Start'
	String get start => 'Start';

	/// en: 'Stop'
	String get stop => 'Stop';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'running'
	String get stateRunning => 'running';

	/// en: 'starting'
	String get stateStarting => 'starting';

	/// en: 'stopped'
	String get stateStopped => 'stopped';

	/// en: 'failed'
	String get stateFailed => 'failed';

	/// en: 'New daemon'
	String get newDaemonTitle => 'New daemon';

	/// en: 'Edit daemon'
	String get editDaemonTitle => 'Edit daemon';

	/// en: 'Name'
	String get nameLabel => 'Name';

	/// en: 'e.g. PC, Server, Home'
	String get namePlaceholder => 'e.g. PC, Server, Home';

	/// en: 'Enter a name.'
	String get nameRequiredError => 'Enter a name.';

	/// en: 'An agent with this name already exists.'
	String get nameDuplicateError => 'An agent with this name already exists.';

	/// en: 'Folder'
	String get folderLabel => 'Folder';

	/// en: 'No folder chosen'
	String get noFolderChosen => 'No folder chosen';

	/// en: 'Choose'
	String get choose => 'Choose';

	/// en: 'Change'
	String get changeFolder => 'Change';

	/// en: 'The folder cannot be changed.'
	String get folderCannotBeChanged => 'The folder cannot be changed.';

	/// en: 'Choose a folder.'
	String get folderRequiredError => 'Choose a folder.';

	/// en: 'An agent already exists in this folder.'
	String get folderDuplicateError => 'An agent already exists in this folder.';

	/// en: 'Choose the Daemon Agent folder'
	String get pickFolderDialogTitle => 'Choose the Daemon Agent folder';
}

// Path: settings.page.general.updateFrequency
class Translations$settings$page$general$updateFrequency$en {
	Translations$settings$page$general$updateFrequency$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Daily'
	String get daily => 'Daily';

	/// en: 'Weekly'
	String get weekly => 'Weekly';

	/// en: 'Monthly'
	String get monthly => 'Monthly';

	/// en: 'Never'
	String get never => 'Never';
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
			'common.save' => 'Save',
			'common.close' => 'Close',
			'common.delete' => 'Delete',
			'common.done' => 'Done',
			'common.add' => 'Add',
			'common.test' => 'Test',
			'common.ok' => 'OK',
			'common.loading' => 'Loading…',
			'common.checking' => 'Checking…',
			'common.remove' => 'Remove',
			'common.restart' => 'Restart',
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
			'cockpit.agentEditDialog.title' => 'Edit agent',
			'cockpit.agentEditDialog.agentName' => 'Agent name',
			'cockpit.agentEditDialog.relaySection' => 'Relay (remote-pi)',
			'cockpit.agentEditDialog.autoConnect' => 'Auto-connect on start',
			'cockpit.agentEditDialog.informationSection' => 'Information',
			'cockpit.agentEditDialog.folder' => 'Folder',
			'cockpit.agentEditDialog.model' => 'Model',
			'cockpit.agentEditDialog.state' => 'State',
			'cockpit.agentEditDialog.context' => 'Context',
			'cockpit.agentEditDialog.statusEmpty' => 'empty',
			'cockpit.agentEditDialog.statusStarting' => 'starting',
			'cockpit.agentEditDialog.statusReady' => 'ready',
			'cockpit.agentEditDialog.statusStreaming' => 'streaming',
			'cockpit.agentEditDialog.statusEnded' => 'ended',
			'cockpit.agentSetupChecklist.title' => 'Set up the agent environment',
			'cockpit.agentSetupChecklist.intro' => 'Running an agent needs Pi installed. Complete the steps below — terminals and files work without any of this.',
			'cockpit.agentSetupChecklist.step1Title' => 'Pi Code installed',
			'cockpit.agentSetupChecklist.step1Description' => 'The `pi` binary must be accessible.',
			'cockpit.agentSetupChecklist.step2Title' => 'remote-pi extension on Pi',
			'cockpit.agentSetupChecklist.step2Description' => 'Registered in ~/.pi/agent/settings.json.',
			'cockpit.agentSetupChecklist.step3Title' => 'Supervisor installed',
			'cockpit.agentSetupChecklist.step3Description' => 'pi-supervisord service (remote-pi install).',
			'cockpit.agentSetupChecklist.install' => 'Install',
			'cockpit.agentSetupChecklist.installExtensionTitle' => 'Install remote-pi extension',
			'cockpit.agentSetupChecklist.installSupervisorTitle' => 'Install supervisor',
			'cockpit.agentSetupChecklist.createAgent' => 'Create agent',
			'cockpit.agentSetupChecklist.back' => 'Back',
			'cockpit.agentSetupChecklist.checkAgain' => 'Check again',
			'cockpit.agentSetupChecklist.notRequired' => 'Not required in this setup',
			'cockpit.agentSetupChecklist.installing' => 'Installing…',
			'cockpit.agentSetupChecklist.installedSuccessfully' => 'Installed successfully.',
			'cockpit.agentComposer.cmdNewDescription' => 'New session — clears the conversation',
			'cockpit.agentComposer.cmdCompactDescription' => 'Compacts the agent context',
			'cockpit.agentComposer.attachFile' => 'Attach file',
			'cockpit.agentComposer.maxImages' => ({required Object max}) => 'Maximum of ${max} images.',
			'cockpit.agentComposer.placeholder' => 'Message to the agent, use @files or /commands',
			'cockpit.agentComposer.stop' => 'Stop',
			'cockpit.agentComposer.send' => 'Send',
			'cockpit.agentComposer.relayOnline' => 'Relay online',
			'cockpit.agentComposer.relayReconnecting' => 'Relay reconnecting...',
			'cockpit.agentComposer.relayOffline' => 'Relay offline',
			'cockpit.agentComposer.contextTooltip' => ({required Object pct}) => 'Context: ${pct}% of the window',
			'cockpit.agentComposer.visionWarning' => 'The current model cannot see images — switch to one with vision.',
			'cockpit.agentComposer.modelFallback' => 'model',
			'cockpit.welcomeView.title' => 'Welcome to Cockpit',
			'cockpit.welcomeView.subtitle' => 'Open a folder to start a workspace.',
			'cockpit.welcomeView.createWorkspace' => 'Create workspace',
			'cockpit.modelPicker.search' => ({required Object count}) => 'Search model (${count})',
			'cockpit.paneView.closePaneTitle' => 'Close pane?',
			'cockpit.paneView.closePaneMessage' => ({required Object count}) => 'This closes all ${count} tab(s) in this pane and ends the agents/terminals in it.',
			'cockpit.paneView.close' => 'Close',
			'cockpit.paneView.allTabs' => 'All tabs',
			'cockpit.paneView.pinTab' => 'Pin tab',
			'cockpit.paneView.rename' => 'Rename',
			'cockpit.paneView.resetTitle' => 'Reset Title',
			'cockpit.paneView.copyId' => 'Copy Id',
			'cockpit.paneView.autoRelay' => 'Auto-relay',
			'cockpit.paneView.history' => 'History',
			'cockpit.paneView.newTab' => 'New tab',
			'cockpit.paneView.newTerminal' => 'New terminal…',
			'cockpit.paneView.splitRight' => 'Split right',
			'cockpit.paneView.splitDown' => 'Split down',
			'cockpit.paneView.closePane' => 'Close pane',
			'cockpit.paneView.dropHereToMove' => 'Drop here to move the tab',
			'cockpit.paneView.dockAsTab' => 'Dock as tab',
			'cockpit.fileViewer.cantOpen' => 'Can\'t open this file.',
			'cockpit.fileViewer.couldNotLoadImage' => 'Could not load the image.',
			'cockpit.fileViewer.preview' => 'Preview',
			'cockpit.fileViewer.source' => 'Source',
			'cockpit.workspaceSettingsDialog.choosePhotoTitle' => 'Choose workspace photo',
			'cockpit.workspaceSettingsDialog.title' => 'Workspace settings',
			'cockpit.workspaceSettingsDialog.namePlaceholder' => 'Workspace name',
			'cockpit.workspaceSettingsDialog.addPhoto' => 'Add photo',
			'cockpit.workspaceSettingsDialog.changePhoto' => 'Change photo',
			'cockpit.workspaceSettingsDialog.remove' => 'Remove',
			'cockpit.workspaceSettingsDialog.color' => 'Color',
			'cockpit.workspaceSettingsDialog.folder' => 'Folder',
			'cockpit.realmDialogs.namePlaceholder' => 'Realm name',
			'cockpit.realmDialogs.duplicateName' => 'A realm with this name already exists.',
			'cockpit.realmDialogs.newRealmTitle' => 'New realm',
			'cockpit.realmDialogs.renameRealmTitle' => 'Rename realm',
			'cockpit.realmDialogs.rename' => 'Rename',
			'cockpit.realmDialogs.deleteRealmTitle' => 'Delete realm',
			'cockpit.realmDialogs.deleteMessage' => ({required Object name, required Object suffix}) => 'Delete "${name}"? No workspace is deleted — the folder list just changes.${suffix}',
			'cockpit.realmDialogs.deleteSuffixOne' => ' Its workspace will move to Default.',
			'cockpit.realmDialogs.deleteSuffixMany' => ({required Object count}) => ' Its ${count} workspaces will move to Default.',
			'cockpit.realmDialogs.manageRealmsTitle' => 'Manage realms',
			'cockpit.realmDialogs.workspaceCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 workspace', other: '${n} workspaces', ), 
			'cockpit.dbRedisTable.deleteKeyTitle' => 'Delete key',
			'cockpit.dbRedisTable.deleteKeyMessage' => ({required Object key}) => 'Delete "${key}" from this Redis database?',
			'cockpit.dbRedisTable.refresh' => 'Refresh',
			'cockpit.dbRedisTable.newKey' => 'New key',
			'cockpit.dbRedisTable.columnKey' => 'KEY',
			'cockpit.dbRedisTable.columnValue' => 'VALUE',
			'cockpit.dbRedisTable.columnType' => 'TYPE',
			'cockpit.dbRedisTable.columnTtl' => 'TTL',
			'cockpit.dbRedisTable.keyCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 key', other: '${n} keys', ), 
			'cockpit.dbRedisTable.noKeys' => 'No keys in this database.',
			'cockpit.dbRedisTable.noKeysMatch' => ({required Object pattern}) => 'No keys match "${pattern}".',
			'cockpit.dbRedisTable.loadMore' => 'Load more',
			'cockpit.dbRedisTable.loadingFullValue' => 'Loading full value…',
			'cockpit.dbRedisTable.ttlMustBeNumber' => 'TTL must be a number of seconds.',
			'cockpit.dbRedisTable.addKey' => 'Add key',
			'cockpit.dbRedisTable.keyFieldHint' => 'key',
			'cockpit.dbRedisTable.ttlFieldHint' => 'ttl (s, optional)',
			'cockpit.dbRedisTable.valueFieldHint' => 'value',
			'cockpit.dbRedisTable.searchHint' => 'Search — pattern, e.g. user:*',
			'cockpit.dbQueryView.saveQueryAs' => 'Save query as',
			'cockpit.dbQueryView.couldNotSave' => 'Could not save',
			'cockpit.dbQueryView.selectDatabase' => 'Select database',
			'cockpit.dbQueryView.noSqlConnections' => 'No SQL connections — add one in the Database panel',
			'cockpit.dbQueryView.running' => 'Running…',
			'cockpit.dbQueryView.runSelection' => 'Run selection',
			'cockpit.dbQueryView.run' => 'Run',
			'cockpit.dbQueryView.pickDatabaseHint' => 'Pick a database above, then Run (⌘↵).',
			'cockpit.dbQueryView.runQueryHint' => 'Run the query (⌘↵) to see results here.',
			'cockpit.dbQueryView.noRows' => 'No rows.',
			'cockpit.dbQueryView.rowsAffected' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 row affected', other: '${n} rows affected', ), 
			'cockpit.dbQueryView.rowsFooter' => ({required Object n}) => '${n} rows',
			'cockpit.dbQueryView.truncatedSuffix' => ' · truncated (raise -- limit)',
			'cockpit.dbQueryView.table' => 'Table',
			'cockpit.dbQueryView.json' => 'JSON',
			'cockpit.dbQueryView.unsaved' => 'unsaved',
			'cockpit.dbQueryView.saved' => 'saved',
			'cockpit.dbQueryView.copied' => 'Copied',
			'cockpit.dbQueryView.copy' => 'Copy',
			'cockpit.dbMongoView.deleteDocumentTitle' => 'Delete document',
			'cockpit.dbMongoView.deleteDocumentMessage' => ({required Object id, required Object collection}) => 'Delete the document with _id ${id} from "${collection}"?',
			'cockpit.dbMongoView.filterHint' => 'Filter — JSON, e.g. {"status": "active"}',
			'cockpit.dbMongoView.docCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '1 doc', other: '${n} docs', ), 
			'cockpit.dbMongoView.refresh' => 'Refresh',
			'cockpit.dbMongoView.insertDocument' => 'Insert document',
			'cockpit.dbMongoView.noDocuments' => 'No documents in this collection.',
			'cockpit.dbMongoView.noDocumentsMatch' => 'No documents match this filter.',
			'cockpit.dbMongoView.loadMore' => 'Load more',
			'cockpit.dbMongoView.edit' => 'Edit',
			'cockpit.dbMongoView.insert' => 'Insert',
			'cockpit.dbConnectionDialog.chooseFileTitle' => 'Choose SQLite database',
			'cockpit.dbConnectionDialog.file' => 'File',
			'cockpit.dbConnectionDialog.chooseFilePlaceholder' => 'Choose a SQLite file…',
			'cockpit.dbConnectionDialog.name' => 'Name',
			'cockpit.dbConnectionDialog.host' => 'Host',
			'cockpit.dbConnectionDialog.port' => 'Port',
			'cockpit.dbConnectionDialog.database' => 'Database',
			'cockpit.dbConnectionDialog.user' => 'User',
			'cockpit.dbConnectionDialog.password' => 'Password',
			'cockpit.dbConnectionDialog.savePassword' => 'Save Password',
			'cockpit.dbConnectionDialog.useTls' => 'Use SSL/TLS',
			'cockpit.dbConnectionDialog.tlsHintSrv' => 'implied by mongodb+srv',
			'cockpit.dbConnectionDialog.tlsHintManaged' => 'managed DBs (RDS, Atlas…) usually require it',
			'cockpit.dbConnectionDialog.allowWrites' => 'Allow writes (agents)',
			'cockpit.dbConnectionDialog.allowWritesHint' => 'off = agents can only read via CLI',
			'cockpit.dbConnectionDialog.visibleToAgents' => 'Visible to agents',
			'cockpit.dbConnectionDialog.visibleToAgentsHint' => 'off = hidden from the CLI, GUI only',
			'cockpit.dbConnectionDialog.testing' => 'Testing connection…',
			'cockpit.dbConnectionDialog.connectionOk' => 'Connection OK',
			'cockpit.dbConnectionDialog.connectionFailed' => 'Connection failed',
			'cockpit.dbConnectionDialog.editTitle' => 'Edit connection',
			'cockpit.dbConnectionDialog.newTitle' => 'New connection',
			'settings.language.title' => 'Language',
			'settings.language.system' => 'System',
			'settings.language.english' => 'English',
			'settings.language.portugueseBr' => 'Português (BR)',
			'settings.language.spanish' => 'Español',
			'settings.revokeDialog.deviceRemoved' => 'Device removed.',
			'settings.revokeDialog.failedToRevoke' => 'Failed to revoke the device.',
			'settings.revokeDialog.revoking' => 'Revoking…',
			'settings.revokeDialog.revokingDevice' => ({required Object name}) => 'Revoking ${name}…',
			'settings.revokeDialog.connectingMessage' => 'Connecting to the relay and removing access.',
			'settings.revokeDialog.ok' => 'Ok',
			'settings.pairingDialog.title' => 'Pair device',
			'settings.pairingDialog.connectingToRelay' => 'Connecting to the relay…',
			'settings.pairingDialog.step1' => 'Open the Remote Pi app on your phone.',
			'settings.pairingDialog.step2' => 'Tap add / pair device.',
			'settings.pairingDialog.step3' => 'Point the camera at the QR below.',
			'settings.pairingDialog.qrGenerationFailed' => 'Could not generate the QR.',
			'settings.pairingDialog.autoRefreshHint' => 'The code refreshes on its own. Keep this window open.',
			'settings.pairingDialog.pairingFailed' => 'Pairing failed.',
			'settings.pairingDialog.tryAgain' => 'Try again',
			'settings.pairingDialog.copied' => 'Copied!',
			'settings.pairingDialog.copyData' => 'Copy data',
			'settings.page.header.back' => 'Back',
			'settings.page.header.title' => 'Settings',
			'settings.page.nav.general' => 'General',
			'settings.page.nav.appearance' => 'Appearance',
			'settings.page.nav.terminal' => 'Terminal',
			'settings.page.nav.language' => 'Language',
			'settings.page.nav.shortcuts' => 'Shortcuts',
			'settings.page.nav.notifications' => 'Notifications',
			'settings.page.nav.connectivity' => 'Connectivity',
			'settings.page.nav.daemonAgents' => 'Daemon Agents',
			'settings.page.nav.schedules' => 'Schedules',
			'settings.page.general.sectionAgent' => 'Agent',
			'settings.page.general.enableAgentsTitle' => 'Enable agents',
			'settings.page.general.enableAgentsDesc' => 'Show the option to open agent tabs (pi). When off, Cockpit works as a terminal-only workspace.',
			'settings.page.general.showCockpitTitle' => 'Show Cockpit terminal',
			'settings.page.general.showCockpitDesc' => 'Keep a pathless, terminal-only workspace pinned at the top of the rail. Turning it off closes its terminals.',
			'settings.page.general.sectionUpdates' => 'Updates',
			'settings.page.general.checkUpdatesTitle' => 'Check for updates',
			'settings.page.general.checkUpdatesDesc' => 'How often Cockpit should look for new versions.',
			'settings.page.general.agentsInUseError' => 'Can\'t turn agents off while an agent tab is open. Close all agent tabs first, then disable it.',
			'settings.page.general.updateFrequency.daily' => 'Daily',
			'settings.page.general.updateFrequency.weekly' => 'Weekly',
			'settings.page.general.updateFrequency.monthly' => 'Monthly',
			'settings.page.general.updateFrequency.never' => 'Never',
			'settings.page.diagnostics.sectionTitle' => 'Diagnostics',
			'settings.page.diagnostics.logFileTitle' => 'Log file',
			'settings.page.diagnostics.logFileDesc' => ({required Object days, required Object path}) => 'Errors and startup events are recorded here, kept for ${days} days.\n${path}',
			'settings.page.diagnostics.unavailable' => 'unavailable',
			'settings.page.diagnostics.reveal' => 'Reveal',
			'settings.page.diagnostics.reportTitle' => 'Report a problem',
			'settings.page.diagnostics.reportDesc' => 'Opens a pre-filled issue with your version, OS and recent log. Nothing is sent automatically — you review it first.',
			'settings.page.diagnostics.reportButton' => 'Report…',
			'settings.page.diagnostics.reportDialogTitle' => 'Problem report',
			'settings.page.diagnostics.reportDialogError' => 'Reported manually from Settings.',
			'settings.page.diagnostics.reportDialogDescription' => 'Describe what went wrong in the issue. The recent log is included below and in "Copy details".',
			'settings.page.storage.sectionTitle' => 'Storage',
			'settings.page.storage.locationTitle' => 'Storage location',
			'settings.page.storage.locationDesc' => ({required Object root}) => 'Cockpit keeps its projects, layouts and settings here. Point it at a synced folder to back it up.\n${root}',
			'settings.page.storage.useDefault' => 'Use default',
			'settings.page.storage.working' => 'Working…',
			'settings.page.storage.change' => 'Change…',
			'settings.page.storage.resetTitle' => 'Reset Cockpit',
			'settings.page.storage.resetDesc' => 'Delete all local data — projects, layouts, settings and terminal history — and return to the default location.',
			'settings.page.storage.resetButton' => 'Reset…',
			'settings.page.storage.resetConfirm' => 'Reset',
			'settings.page.storage.resetDialogTitle' => 'Reset Cockpit?',
			'settings.page.storage.resetDialogContent' => 'This permanently deletes all local Cockpit data — projects, layouts, settings and terminal history. This cannot be undone. Cockpit will close so you can start fresh.',
			'settings.page.storage.restartRequiredTitle' => 'Restart required',
			'settings.page.storage.restartChangeFolderMessage' => ({required Object path}) => 'Cockpit will use this folder from the next launch:\n${path}',
			'settings.page.storage.restartUseDefaultMessage' => 'Cockpit will use the default system location from the next launch. Your data in the custom folder is left untouched.',
			'settings.page.storage.restartResetMessage' => 'All Cockpit data was cleared. Restart to start fresh.',
			'settings.page.storage.later' => 'Later',
			'settings.page.storage.quitCockpit' => 'Quit Cockpit',
			'settings.page.storage.chooseFolderDialogTitle' => 'Choose a folder for Cockpit data',
			'settings.page.terminal.sectionDefaultTerminal' => 'Default terminal',
			'settings.page.terminal.engineTitle' => 'Engine',
			'settings.page.terminal.engineDesc' => 'Used by new terminal tabs and task output buffers. Open tabs keep their current engine.',
			'settings.page.terminal.shellTitle' => 'Shell',
			'settings.page.terminal.shellDesc' => 'Which shell new terminal tabs open. The arrow next to + still opens any other one, just for that tab.',
			'settings.page.terminal.noWslMessage' => 'No WSL distros found. Install one (wsl.exe --install) and restart Cockpit to see it listed here.',
			'settings.page.appearance.sectionTheme' => 'Theme',
			'settings.page.appearance.themeSystem' => 'System',
			'settings.page.appearance.themeLight' => 'Light',
			'settings.page.appearance.themeDark' => 'Dark',
			'settings.page.appearance.sectionFonts' => 'Fonts',
			'settings.page.appearance.interfaceFontTitle' => 'Interface font',
			'settings.page.appearance.interfaceFontDesc' => 'Used across the whole app. Empty = system default.',
			'settings.page.appearance.interfaceSizeTitle' => 'Interface size',
			'settings.page.appearance.codeFontTitle' => 'Code font',
			'settings.page.appearance.codeFontDesc' => 'Code and diffs. Empty = system default.',
			'settings.page.appearance.codeSizeTitle' => 'Code size',
			'settings.page.appearance.terminalFontTitle' => 'Terminal font',
			'settings.page.appearance.terminalFontDesc' => 'Uses the code size. Empty = system default.',
			'settings.page.appearance.sectionSyntax' => 'Syntax',
			'settings.page.appearance.highlightThemeTitle' => 'Highlight theme',
			'settings.page.appearance.highlightThemeDesc' => 'Code colors, independent of the app theme.',
			'settings.page.appearance.sectionConversation' => 'Conversation',
			'settings.page.appearance.pinUserMessageTitle' => 'Pin user message',
			'settings.page.appearance.pinUserMessageDesc' => 'The question stays fixed at the top while the answer scrolls.',
			'settings.page.notifications.sectionTitle' => 'Notifications',
			'settings.page.notifications.enableTitle' => 'Enable notifications',
			'settings.page.notifications.enableDesc' => 'Alert me when an agent finishes a turn and the window is not focused.',
			'settings.page.notifications.systemPermissionTitle' => 'System permission',
			'settings.page.notifications.grantedDesc' => 'Cockpit is allowed to send notifications.',
			'settings.page.notifications.notGrantedDesc' => 'macOS has not granted notification access yet.',
			'settings.page.notifications.granted' => 'Granted',
			'settings.page.notifications.requestPermission' => 'Request permission',
			'settings.page.notifications.playSoundTitle' => 'Play sound on finish',
			'settings.page.notifications.playSoundDesc' => 'Play a short chime when a turn finishes and the window is focused (on any tab or workspace).',
			'settings.page.shortcuts.notCustomizable' => 'Keyboard shortcuts are not customizable yet.',
			'settings.page.languages.sectionFormatting' => 'FORMATTING',
			'settings.page.languages.formatOnSaveTitle' => 'Format on save',
			'settings.page.languages.formatOnSaveDesc' => 'Format the file automatically when you save (⌘S).',
			'settings.page.languages.sectionLanguageServers' => 'LANGUAGE SERVERS',
			'settings.page.languages.footerNote' => 'Errors and formatting use each language\'s language server. Cockpit does not install servers — it uses what is already on your machine. ● responds · ○ not found or invalid command (install the server or adjust the command).',
			'settings.page.languages.serverCommandLabel' => 'Language server command',
			'settings.page.languages.formatterCommandLabel' => 'Formatter command (optional)',
			'settings.page.languages.formatterHint' => 'External formatter with %FILE% placeholder. Takes precedence over the LSP formatter when set.',
			'settings.page.languages.resetToDefault' => 'Reset to default',
			'settings.page.languages.saveAndRestart' => 'Save & restart',
			'settings.page.languages.statusResponds' => 'Server responds',
			'settings.page.languages.statusNotFound' => 'Server not found or command invalid',
			'settings.page.connectivity.sectionRelay' => 'Relay',
			'settings.page.connectivity.sectionPairedDevices' => 'Paired devices',
			'settings.page.connectivity.reloadTooltip' => 'Reload',
			'settings.page.connectivity.failedToListDevices' => 'Failed to list devices.',
			'settings.page.connectivity.noPairedDevices' => 'No paired devices.',
			'settings.page.connectivity.relayAddressTitle' => 'Relay address',
			'settings.page.connectivity.relayAddressDesc' => 'Server that connects your agents to the phone. Applies to every agent with the relay enabled.',
			'settings.page.connectivity.saving' => 'Saving…',
			'settings.page.connectivity.check' => 'Check',
			'settings.page.connectivity.healthOnline' => 'Online',
			'settings.page.connectivity.healthNoResponse' => 'No response',
			'settings.page.connectivity.healthNotChecked' => 'Not checked',
			'settings.page.connectivity.deviceDefaultLabel' => 'Device',
			'settings.page.connectivity.revoke' => 'Revoke',
			'settings.page.connectivity.pairNewDevice' => 'Pair new device',
			'settings.page.connectivity.revokeDialogTitle' => 'Revoke device?',
			'settings.page.connectivity.revokeDialogContent' => ({required Object name}) => '"${name}" will lose access to your agents and will need to pair again.\n\nYou must be connected to the relay — the app will connect automatically to revoke.',
			'settings.page.schedules.sectionScheduledPrompts' => 'Scheduled prompts',
			'settings.page.schedules.createSchedule' => 'Create schedule',
			'settings.page.schedules.createDaemonFirst' => 'Create a Daemon Agent first.',
			'settings.page.schedules.supervisorOffline' => 'Supervisor offline. Schedules need pi-supervisord running (`remote-pi install`).',
			'settings.page.schedules.failedToListSchedules' => 'Failed to list schedules.',
			'settings.page.schedules.noSchedules' => 'No schedules. Create a recurring prompt for a daemon.',
			'settings.page.schedules.runNow' => 'Run now',
			'settings.page.schedules.viewLog' => 'View log',
			'settings.page.schedules.disabled' => 'disabled',
			'settings.page.schedules.nextRun' => ({required Object when}) => 'next ${when}',
			'settings.page.schedules.lastRun' => ({required Object label}) => 'last: ${label}',
			'settings.page.schedules.removeScheduleDialogTitle' => 'Remove schedule?',
			'settings.page.schedules.removeScheduleDialogContent' => ({required Object schedule, required Object daemon}) => 'The job "${schedule}" for ${daemon} is deleted. Its runs stop.',
			'settings.page.schedules.newScheduleTitle' => 'New schedule',
			'settings.page.schedules.daemonLabel' => 'Daemon',
			'settings.page.schedules.whenLabel' => 'When (cron expression)',
			'settings.page.schedules.previewPlaceholder' => 'Next run shows up here',
			'settings.page.schedules.previewComputed' => 'Next: computed on save',
			'settings.page.schedules.previewNext' => ({required Object when}) => 'Next: ${when}',
			'settings.page.schedules.exampleEveryDay9am' => 'every day 9am',
			'settings.page.schedules.exampleHourly' => 'hourly',
			'settings.page.schedules.exampleEvery15Min' => 'every 15 min',
			'settings.page.schedules.exampleWeekdays6pm' => 'weekdays 6pm',
			'settings.page.schedules.promptLabel' => 'Prompt',
			'settings.page.schedules.timezoneLabel' => 'Timezone (optional)',
			'settings.page.schedules.skipIfBusy' => 'Skip if the agent is busy',
			'settings.page.schedules.wakeIfStopped' => 'Wake the daemon if stopped',
			'settings.page.schedules.catchup' => 'Recover 1 missed run (catchup)',
			'settings.page.schedules.fillRequiredError' => 'Fill in the expression and the prompt.',
			'settings.page.schedules.creating' => 'Creating…',
			'settings.page.schedules.failedToCreateSchedule' => 'Failed to create the schedule.',
			'settings.page.schedules.historyTitle' => ({required Object schedule}) => 'History — ${schedule}',
			'settings.page.schedules.failedToReadLog' => 'Failed to read the log.',
			'settings.page.schedules.noRecordsYet' => 'No records yet.',
			'settings.page.schedules.cronDelivered' => 'delivered',
			'settings.page.schedules.cronWokeDelivered' => 'woke + delivered',
			'settings.page.schedules.cronFailed' => 'failed',
			'settings.page.schedules.cronSkippedBusy' => 'skipped (busy)',
			'settings.page.schedules.cronSkippedStopped' => 'skipped (stopped)',
			'settings.page.schedules.cronSkippedDisabled' => 'skipped (disabled)',
			'settings.page.daemons.sectionAlwaysOnAgents' => 'Always-on agents',
			'settings.page.daemons.createDaemon' => 'Create daemon',
			'settings.page.daemons.startAll' => 'Start all',
			'settings.page.daemons.stopAll' => 'Stop all',
			'settings.page.daemons.restartAll' => 'Restart all',
			'settings.page.daemons.restartSupervisor' => 'Restart supervisor',
			'settings.page.daemons.restartSupervisorDialogTitle' => 'Restart the supervisor?',
			'settings.page.daemons.restartSupervisorDialogContent' => 'Restarts the supervisor process (reloads the code). All daemons restart with it and go offline for a few seconds.',
			'settings.page.daemons.removeDaemonDialogTitle' => 'Remove daemon?',
			'settings.page.daemons.removeDaemonDialogContent' => ({required Object name}) => '"${name}" stops running and leaves the registry. The folder and its local config are kept — you can recreate it later.',
			'settings.page.daemons.supervisorOfflineTitle' => 'Supervisor offline',
			'settings.page.daemons.supervisorOfflineDesc' => 'pi-supervisord is not running. Install it with `remote-pi install` to manage 24/7 agents.',
			'settings.page.daemons.failedToListDaemons' => 'Failed to list daemons.',
			'settings.page.daemons.noRegisteredAgents' => 'No registered agents. Create one from a folder.',
			'settings.page.daemons.start' => 'Start',
			'settings.page.daemons.stop' => 'Stop',
			'settings.page.daemons.edit' => 'Edit',
			'settings.page.daemons.stateRunning' => 'running',
			'settings.page.daemons.stateStarting' => 'starting',
			'settings.page.daemons.stateStopped' => 'stopped',
			'settings.page.daemons.stateFailed' => 'failed',
			'settings.page.daemons.newDaemonTitle' => 'New daemon',
			'settings.page.daemons.editDaemonTitle' => 'Edit daemon',
			'settings.page.daemons.nameLabel' => 'Name',
			'settings.page.daemons.namePlaceholder' => 'e.g. PC, Server, Home',
			'settings.page.daemons.nameRequiredError' => 'Enter a name.',
			'settings.page.daemons.nameDuplicateError' => 'An agent with this name already exists.',
			'settings.page.daemons.folderLabel' => 'Folder',
			'settings.page.daemons.noFolderChosen' => 'No folder chosen',
			'settings.page.daemons.choose' => 'Choose',
			'settings.page.daemons.changeFolder' => 'Change',
			'settings.page.daemons.folderCannotBeChanged' => 'The folder cannot be changed.',
			'settings.page.daemons.folderRequiredError' => 'Choose a folder.',
			'settings.page.daemons.folderDuplicateError' => 'An agent already exists in this folder.',
			'settings.page.daemons.pickFolderDialogTitle' => 'Choose the Daemon Agent folder',
			_ => null,
		};
	}
}
