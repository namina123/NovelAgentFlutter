import 'dart:async';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'conversation_request_cancellation_token.dart';

enum ConversationRequestLifecycleStatus {
  running,
  cancellationRequested,
  cancelled,
  succeeded,
  failed,
}

class ConversationRequestHandle {
  ConversationRequestHandle._({
    required this.requestId,
    required ConversationRequestCancellationToken cancellationToken,
    required Completer<DraftGenerationResult> completionCompleter,
  }) : _cancellationToken = cancellationToken,
       _completionCompleter = completionCompleter;

  factory ConversationRequestHandle.create({required String requestId}) {
    return ConversationRequestHandle._(
      requestId: requestId,
      cancellationToken: ConversationRequestCancellationToken(),
      completionCompleter: Completer<DraftGenerationResult>(),
    );
  }

  final String requestId;
  final ConversationRequestCancellationToken _cancellationToken;
  final Completer<DraftGenerationResult> _completionCompleter;

  ConversationRequestLifecycleStatus _status =
      ConversationRequestLifecycleStatus.running;

  ConversationRequestCancellationToken get cancellationToken =>
      _cancellationToken;

  Future<DraftGenerationResult> get completion => _completionCompleter.future;

  ConversationRequestLifecycleStatus get status => _status;

  bool get isTerminal =>
      _status == ConversationRequestLifecycleStatus.cancelled ||
      _status == ConversationRequestLifecycleStatus.succeeded ||
      _status == ConversationRequestLifecycleStatus.failed;

  bool requestCancellation() {
    // 中文注释: 句柄只负责记录取消意图，真正中断由后续链路继续接通。
    if (isTerminal) {
      return false;
    }
    final didCancel = _cancellationToken.cancel();
    if (didCancel) {
      _status = ConversationRequestLifecycleStatus.cancellationRequested;
    }
    return didCancel;
  }

  bool markSucceeded(DraftGenerationResult result) {
    // 中文注释: 运行时服务在请求收尾时统一封口，避免 controller 手动操作 completer。
    if (_completionCompleter.isCompleted) {
      return false;
    }
    _status = ConversationRequestLifecycleStatus.succeeded;
    _completionCompleter.complete(result);
    return true;
  }

  bool markCancelled(DraftGenerationResult result) {
    if (_completionCompleter.isCompleted) {
      return false;
    }
    _status = ConversationRequestLifecycleStatus.cancelled;
    _completionCompleter.complete(result);
    return true;
  }

  bool markFailed(Object error, StackTrace stackTrace) {
    if (_completionCompleter.isCompleted) {
      return false;
    }
    _status = ConversationRequestLifecycleStatus.failed;
    _completionCompleter.completeError(error, stackTrace);
    return true;
  }
}
