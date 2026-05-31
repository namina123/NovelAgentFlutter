import 'dart:async';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/conversation_request_cancellation_token.dart';
import '../models/conversation_request_handle.dart';
import 'conversation_progress_coalescer_service.dart';

typedef ConversationRequestExecution =
    Future<DraftGenerationResult> Function({
      required void Function(DraftGenerationProgress progress) onProgress,
      required ConversationRequestCancellationToken cancellationToken,
    });

class ConversationRequestRuntimeService {
  ConversationRequestRuntimeService({
    ConversationProgressCoalescerService? progressCoalescerService,
  }) : _progressCoalescerService =
           progressCoalescerService ??
           const ConversationProgressCoalescerService();

  final ConversationProgressCoalescerService _progressCoalescerService;

  int _requestSequence = 0;

  ConversationRequestHandle start({
    required ConversationRequestExecution execute,
    required void Function(DraftGenerationProgress progress) onProgress,
  }) {
    // 中文注释: 先返回正式句柄，再在微任务里起跑，避免同步 progress 提前击穿 controller 边界。
    final handle = ConversationRequestHandle.create(
      requestId: _nextRequestId(),
    );
    unawaited(
      Future<void>.microtask(
        () => _runRequest(handle, execute: execute, onProgress: onProgress),
      ),
    );
    return handle;
  }

  String _nextRequestId() {
    _requestSequence += 1;
    return 'conversation_request_$_requestSequence';
  }

  Future<void> _runRequest(
    ConversationRequestHandle handle, {
    required ConversationRequestExecution execute,
    required void Function(DraftGenerationProgress progress) onProgress,
  }) async {
    final progressCoalescer = _progressCoalescerService.bind(onProgress);
    try {
      final result = await execute(
        onProgress: (progress) {
          if (handle.cancellationToken.isCancellationRequested) {
            return;
          }
          progressCoalescer.schedule(progress);
        },
        cancellationToken: handle.cancellationToken,
      );
      if (handle.cancellationToken.isCancellationRequested) {
        progressCoalescer.dispose();
      } else {
        progressCoalescer.flushNow();
      }
      if (result.cancelledByUser) {
        handle.markCancelled(result);
      } else {
        handle.markSucceeded(result);
      }
    } catch (error, stackTrace) {
      progressCoalescer.dispose();
      handle.markFailed(error, stackTrace);
    } finally {
      progressCoalescer.dispose();
    }
  }
}
