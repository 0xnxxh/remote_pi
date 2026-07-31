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

  Future<Result<String, AutomationError>> generate({
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
    if (harnessFor(selection.harnessId) == null) {
      return Failure(
        AutomationError(
          AutomationErrorKind.unavailable,
          '${selection.harnessId.label} is not installed or is no longer available.',
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
