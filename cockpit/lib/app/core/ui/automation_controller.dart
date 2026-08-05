import 'dart:async';

import 'package:cockpit/app/core/domain/contracts/automation_gateway.dart';
import 'package:cockpit/app/core/domain/entities/automation.dart';
import 'package:cockpit/app/core/domain/exceptions/automation_error.dart';
import 'package:cockpit/app/core/domain/result.dart';
import 'package:flutter/foundation.dart';

class AutomationController extends ChangeNotifier {
  AutomationController(this._gateway);

  final AutomationGateway _gateway;
  List<AutomationHarness> _harnesses = const <AutomationHarness>[];
  bool _initialized = false;
  bool _discovering = false;
  bool _generating = false;
  String? _errorMessage;

  List<AutomationHarness> get harnesses => _harnesses;
  bool get initialized => _initialized;
  bool get discovering => _discovering;
  bool get generating => _generating;
  String? get errorMessage => _errorMessage;

  AutomationHarness? harnessFor(AutomationHarnessId? id) {
    if (id == null) return null;
    for (final harness in _harnesses) {
      if (harness.id == id) return harness;
    }
    return null;
  }

  /// Descobre harnesses na primeira necessidade (Settings ou geração).
  Future<void> ensureInitialized() async {
    if (_initialized || _discovering) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_discovering) return;
    _discovering = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _harnesses = await _gateway.discover();
    } catch (error) {
      _errorMessage = 'Could not discover installed automation harnesses.';
      debugPrint('[automation] discovery failed: $error');
    } finally {
      _initialized = true;
      _discovering = false;
      notifyListeners();
    }
  }

  /// Limpa um modelId que sumiu da lista descoberta e avisa o usuário.
  /// Retorna a mensagem de aviso, ou `null` se nada mudou.
  String? reconcileStaleModel({
    required AutomationHarnessId? harnessId,
    required String? modelId,
    required void Function() clearToCliDefault,
  }) {
    if (harnessId == null) return null;
    final trimmed = modelId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final harness = harnessFor(harnessId);
    if (harness == null || harness.models.isEmpty) return null;
    if (harness.models.any((model) => model.id == trimmed)) return null;
    clearToCliDefault();
    final warning =
        'Model "$trimmed" is no longer available for ${harness.label}. '
        'Using the CLI default — pick another model in Settings if needed.';
    _errorMessage = warning;
    notifyListeners();
    return warning;
  }

  Future<Result<GeneratedCommitMessage, AutomationError>> generate({
    required AutomationSelection selection,
    required AutomationRequest request,
  }) async {
    if (_generating) {
      return const Failure(
        AutomationError(
          AutomationErrorKind.process,
          'Another commit message is already being generated.',
        ),
      );
    }
    await ensureInitialized();
    final harness = harnessFor(selection.harnessId);
    if (harness == null) {
      return Failure(
        AutomationError(
          AutomationErrorKind.unavailable,
          '${selection.harnessId.label} is not installed or is no longer available.',
        ),
      );
    }
    final modelId = selection.modelId?.trim();
    if (modelId != null &&
        modelId.isNotEmpty &&
        harness.models.isNotEmpty &&
        !harness.models.any((model) => model.id == modelId)) {
      return Failure(
        AutomationError(
          AutomationErrorKind.unavailable,
          'Model "$modelId" is not available for ${harness.label}. '
          'Choose another model in Settings.',
        ),
      );
    }
    _generating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return Success(
        await _gateway.generate(selection: selection, request: request),
      );
    } on AutomationError catch (error) {
      _errorMessage = error.message;
      return Failure(error);
    } catch (error) {
      const failure = AutomationError(
        AutomationErrorKind.process,
        'The automation could not generate a commit message.',
      );
      _errorMessage = failure.message;
      debugPrint('[automation] generation failed: $error');
      return const Failure(failure);
    } finally {
      _generating = false;
      notifyListeners();
    }
  }

  Future<void> cancelGeneration() => _gateway.cancel();

  @override
  void dispose() {
    unawaited(_gateway.close());
    super.dispose();
  }
}
