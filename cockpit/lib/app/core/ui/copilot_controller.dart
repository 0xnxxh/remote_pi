import 'dart:async';
import 'dart:io';

import 'package:cockpit/app/core/domain/contracts/copilot_gateway.dart';
import 'package:cockpit/app/core/domain/entities/copilot.dart';
import 'package:cockpit/app/core/domain/exceptions/copilot_error.dart';
import 'package:cockpit/app/core/domain/result.dart';
import 'package:flutter/foundation.dart';

/// Estado app-scoped da integração. Settings e Source Control observam a mesma
/// instância; futuramente o editor poderá reutilizá-la para inline suggestions.
class CopilotController extends ChangeNotifier {
  CopilotController(this._gateway) : _status = _gateway.currentStatus {
    _subscription = _gateway.status.listen((value) {
      _status = value;
      // O servidor pode restaurar uma sessão autenticada logo depois de uma
      // tentativa de device flow responder sem código. Nesse caso o status
      // Connected é a fonte de verdade e qualquer erro/autenticação pendente
      // da tentativa anterior ficou obsoleto.
      if (value.isConnected) {
        _authentication = null;
        _errorMessage = null;
      }
      notifyListeners();
    });
  }

  final CopilotGateway _gateway;
  late final StreamSubscription<CopilotStatus> _subscription;
  CopilotStatus _status;
  CopilotAuthentication? _authentication;
  String? _errorMessage;
  bool _completingAuthentication = false;
  Future<void>? _startingGateway;

  CopilotStatus get status => _status;
  CopilotAuthentication? get authentication => _authentication;
  String? get errorMessage => _errorMessage;
  bool get completingAuthentication => _completingAuthentication;

  String get _defaultWorkspace =>
      Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      Directory.current.path;

  /// Inicia o language server no boot para que ele restaure silenciosamente a
  /// sessão persistida. Isso não abre device flow: se não houver credencial, o
  /// estado simplesmente permanece desconectado e Settings oferece Connect.
  Future<Result<void, CopilotError>> initialize({String? workspacePath}) async {
    try {
      await _ensureGatewayStarted(workspacePath ?? _defaultWorkspace);
      final current = _gateway.currentStatus;
      _status = current;
      if (current.isConnected) {
        _authentication = null;
        _errorMessage = null;
      }
      notifyListeners();
      return const Success(null);
    } on CopilotError catch (error) {
      _status = _gateway.currentStatus;
      _errorMessage = error.message;
      notifyListeners();
      return Failure(error);
    }
  }

  Future<void> _ensureGatewayStarted(String workspacePath) {
    final pending = _startingGateway;
    if (pending != null) {
      // Depois do start em andamento, uma segunda chamada ainda registra seu
      // workspace no gateway já vivo (start é idempotente nesse estado).
      return pending.then((_) => _gateway.start(workspacePath: workspacePath));
    }
    late final Future<void> operation;
    operation = _gateway.start(workspacePath: workspacePath).whenComplete(() {
      if (identical(_startingGateway, operation)) _startingGateway = null;
    });
    _startingGateway = operation;
    return operation;
  }

  Future<Result<CopilotAuthentication, CopilotError>> connect({
    String? workspacePath,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _ensureGatewayStarted(workspacePath ?? _defaultWorkspace);
      final current = _gateway.currentStatus;
      if (current.isConnected) {
        return const Failure(
          CopilotError(
            CopilotErrorKind.authentication,
            'GitHub Copilot is already connected.',
          ),
        );
      }
      if (current.state != CopilotState.disconnected &&
          current.state != CopilotState.authenticationFailed) {
        throw CopilotError(CopilotErrorKind.unavailable, current.message);
      }
      final authentication = await _gateway.beginAuthentication();
      _authentication = authentication;
      notifyListeners();
      return Success(authentication);
    } on CopilotError catch (error) {
      // `didChangeStatus: Normal` pode chegar enquanto `signIn` ainda está
      // respondendo. Não publique um erro de device code depois que o próprio
      // servidor já confirmou que a conta está conectada.
      final current = _gateway.currentStatus;
      if (current.isConnected) {
        _status = current;
        _authentication = null;
        _errorMessage = null;
      } else {
        _errorMessage = error.message;
      }
      notifyListeners();
      return Failure(error);
    }
  }

  Future<Result<void, CopilotError>> completeAuthentication() async {
    final authentication = _authentication;
    if (authentication == null) {
      return const Failure(
        CopilotError(
          CopilotErrorKind.authentication,
          'Start GitHub authentication first.',
        ),
      );
    }
    _errorMessage = null;
    _completingAuthentication = true;
    notifyListeners();
    try {
      await _gateway.completeAuthentication(authentication);
      _authentication = null;
      return const Success(null);
    } on CopilotError catch (error) {
      _authentication = null;
      final current = _gateway.currentStatus;
      if (current.isConnected) {
        _status = current;
        _errorMessage = null;
      } else {
        _errorMessage = error.message;
      }
      return Failure(error);
    } finally {
      _completingAuthentication = false;
      notifyListeners();
    }
  }

  Future<Result<void, CopilotError>> disconnect() async {
    try {
      await _gateway.disconnect();
      _authentication = null;
      _errorMessage = null;
      notifyListeners();
      return const Success(null);
    } on CopilotError catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return Failure(error);
    }
  }

  Future<Result<String, CopilotError>> generateCommitMessage({
    required String repositoryPath,
    required String diff,
    required List<String> recentCommitSubjects,
  }) async {
    try {
      final message = await _gateway.generateCommitMessage(
        repositoryPath: repositoryPath,
        diff: diff,
        recentCommitSubjects: recentCommitSubjects,
      );
      return Success(message);
    } on CopilotError catch (error) {
      return Failure(error);
    }
  }

  Future<void> cancelGeneration() => _gateway.cancelGeneration();

  @override
  void dispose() {
    _subscription.cancel();
    unawaited(_gateway.close());
    super.dispose();
  }
}
