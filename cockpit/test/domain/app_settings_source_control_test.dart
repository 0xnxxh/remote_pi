import 'package:cockpit/app/core/domain/contracts/settings_store.dart';
import 'package:cockpit/app/core/domain/entities/app_settings.dart';
import 'package:cockpit/app/core/domain/entities/automation.dart';
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

  test(
    'automation selection persists defaults and resets them per harness',
    () {
      const settings = AppSettings(
        automationHarnessId: AutomationHarnessId.codex,
        automationModelId: 'gpt-5.4-mini',
      );
      final restored = AppSettings.fromJson(settings.toJson());
      expect(restored.automationHarnessId, AutomationHarnessId.codex);
      expect(restored.automationModelId, 'gpt-5.4-mini');

      final migratedClaude = AppSettings.fromJson(const <String, dynamic>{
        'automation.harnessId': 'claude',
      });
      expect(migratedClaude.selectedAutomationModelId, 'sonnet');

      final store = _Store()..value = settings;
      final controller = SettingsController(store);
      controller.setAutomationHarness(AutomationHarnessId.codex);
      expect(controller.settings.selectedAutomationModelId, 'gpt-5.6-terra');

      controller.setAutomationHarness(AutomationHarnessId.pi);
      expect(controller.settings.automationHarnessId, AutomationHarnessId.pi);
      expect(controller.settings.selectedAutomationModelId, isNull);

      controller.setAutomationModel('anthropic/claude-sonnet-4');
      expect(
        controller.settings.selectedAutomationModelId,
        'anthropic/claude-sonnet-4',
      );
      controller.setAutomationModel(null);
      final cliDefault = AppSettings.fromJson(controller.settings.toJson());
      expect(cliDefault.selectedAutomationModelId, isNull);

      controller.setAutomationHarness(null);
      expect(controller.settings.automationSelection, isNull);
      expect(controller.settings.automationModelId, isNull);
    },
  );
}
