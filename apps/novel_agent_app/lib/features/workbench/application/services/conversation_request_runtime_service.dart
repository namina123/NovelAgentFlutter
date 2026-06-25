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
    Duration idleWatchdogTimeout = const Duration(seconds: 180),
  }) : _progressCoalescerService =
           progressCoalescerService ??
           const ConversationProgressCoalescerService(),
       _idleWatchdogTimeout = idleWatchdogTimeout;

  final ConversationProgressCoalescerService _progressCoalescerService;

  // 中文注释: 网关流可能建连后静默挂起（不发数据也不关连接），超过这个时长没有任何 progress 就自动取消，
  // 避免请求永久卡住导致整条会话 isGenerating 一直 true、pending 工具条目一直停在 running。
  final Duration _idleWatchdogTimeout;

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
    // 中文注释: 每收到一帧 progress 就重置看门狗；超时仍无任何进展则触发取消，复用用户手动停止的同一条链路
    // （cancellationScope 会 client.close(force:true) 强制中断挂起的 stream），让 useCase 终止、UI 收口。
    Timer? idleWatchdog;
    void resetIdleWatchdog() {
      idleWatchdog?.cancel();
      if (handle.isTerminal) {
        return;
      }
      idleWatchdog = Timer(_idleWatchdogTimeout, () {
        handle.requestCancellation();
      });
    }
    resetIdleWatchdog();
    try {
      final result = await execute(
        onProgress: (progress) {
          if (handle.cancellationToken.isCancellationRequested) {
            return;
          }
          resetIdleWatchdog();
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
      idleWatchdog?.cancel();
      progressCoalescer.dispose();
    }
  }
}
