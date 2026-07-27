import 'package:cockpit/app/core/domain/contracts/settings_store.dart';
import 'package:cockpit/app/core/domain/entities/app_settings.dart';
import 'package:cockpit/app/core/ui/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements SettingsStore {
  AppSettings value = const AppSettings();
  AppSettings? saved;

  @override
  Future<AppSettings> load() async => value;

  @override
  Future<void> save(AppSettings settings) async => saved = settings;
}

void main() {
  test('source control defaults to list for legacy and new settings', () {
    expect(
      const AppSettings().sourceControlViewMode,
      SourceControlViewMode.list,
    );
    expect(
      AppSettings.fromJson(const <String, dynamic>{}).sourceControlViewMode,
      SourceControlViewMode.list,
    );
    expect(
      AppSettings.fromJson(const <String, dynamic>{
        'sourceControl.viewMode': 'unsupported',
      }).sourceControlViewMode,
      SourceControlViewMode.list,
    );
  });

  test('source control view mode round-trips and is persisted globally', () {
    const settings = AppSettings(
      sourceControlViewMode: SourceControlViewMode.tree,
    );
    expect(
      AppSettings.fromJson(settings.toJson()).sourceControlViewMode,
      SourceControlViewMode.tree,
    );

    final store = _Store();
    final controller = SettingsController(store);
    controller.setSourceControlViewMode(SourceControlViewMode.tree);

    expect(
      controller.settings.sourceControlViewMode,
      SourceControlViewMode.tree,
    );
    expect(store.saved?.sourceControlViewMode, SourceControlViewMode.tree);
  });
}
