import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_request_handle.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_progress_coalescer_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_request_runtime_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ConversationRequestRuntimeService', () {
    test(
      'returns a formal handle and completes with flushed progress',
      () async {
        final emitted = <DraftGenerationProgress>[];
        final service = ConversationRequestRuntimeService(
          progressCoalescerService: const ConversationProgressCoalescerService(
            interval: Duration(milliseconds: 1),
          ),
        );

        final handle = service.start(
          onProgress: emitted.add,
          execute: ({required onProgress, required cancellationToken}) async {
            onProgress(_progress('初稿'));
            return _result(draftMarkdown: '最终正文');
          },
        );

        expect(handle.requestId, 'conversation_request_1');
        expect(handle.status, ConversationRequestLifecycleStatus.running);

        final result = await handle.completion;

        expect(result.draftMarkdown, '最终正文');
        expect(handle.status, ConversationRequestLifecycleStatus.succeeded);
        expect(emitted, hasLength(1));
        expect(emitted.single.draftMarkdown, '初稿');
      },
    );

    test('ignores progress after cancellation is requested', () async {
      final emitted = <DraftGenerationProgress>[];
      final service = ConversationRequestRuntimeService(
        progressCoalescerService: const ConversationProgressCoalescerService(
          interval: Duration(milliseconds: 1),
        ),
      );

      final handle = service.start(
        onProgress: emitted.add,
        execute: ({required onProgress, required cancellationToken}) async {
          await Future<void>.delayed(const Duration(milliseconds: 5));
          onProgress(_progress('被丢弃的进度'));
          return _result(
            draftMarkdown: '仍然成功返回',
            cancelledByUser: true,
            partialContentAccepted: true,
          );
        },
      );

      expect(handle.requestCancellation(), isTrue);

      final result = await handle.completion;

      expect(result.draftMarkdown, '仍然成功返回');
      expect(handle.status, ConversationRequestLifecycleStatus.cancelled);
      expect(handle.cancellationToken.isCancellationRequested, isTrue);
      expect(emitted, isEmpty);
    });

    test('marks handle as failed when execution throws', () async {
      final service = ConversationRequestRuntimeService();
      final handle = service.start(
        onProgress: (_) {},
        execute: ({required onProgress, required cancellationToken}) async {
          throw StateError('boom');
        },
      );

      await expectLater(handle.completion, throwsA(isA<StateError>()));
      expect(handle.status, ConversationRequestLifecycleStatus.failed);
    });

    test('idle watchdog cancels a request that stops sending progress', () async {
      // 中文注释: 模拟网关流静默挂起：execute 永不主动返回，除非被取消。看门狗超时应触发取消，复用和手动停止一样的链路。
      final service = ConversationRequestRuntimeService(
        idleWatchdogTimeout: const Duration(milliseconds: 50),
      );
      final handle = service.start(
        onProgress: (_) {},
        execute: ({required onProgress, required cancellationToken}) {
          final pending = Completer<DraftGenerationResult>();
          cancellationToken.addListener(() {
            if (!pending.isCompleted) {
              pending.complete(
                _result(draftMarkdown: '', cancelledByUser: true),
              );
            }
          });
          return pending.future;
        },
      );

      final result = await handle.completion;

      expect(
        handle.status,
        ConversationRequestLifecycleStatus.cancelled,
      );
      expect(handle.cancellationToken.isCancellationRequested, isTrue);
      expect(result.cancelledByUser, isTrue);
    });

    test('idle watchdog does not fire while progress keeps arriving', () async {
      // 中文注释: 持续以小于看门狗阈值的间隔发 progress，看门狗应被反复重置，请求正常完成而不被误取消。
      final service = ConversationRequestRuntimeService(
        idleWatchdogTimeout: const Duration(milliseconds: 80),
      );
      final handle = service.start(
        onProgress: (_) {},
        execute: ({required onProgress, required cancellationToken}) async {
          for (var i = 0; i < 6; i += 1) {
            await Future<void>.delayed(const Duration(milliseconds: 20));
            onProgress(_progress('chunk $i'));
          }
          return _result(draftMarkdown: '完成');
        },
      );

      final result = await handle.completion;

      expect(handle.status, ConversationRequestLifecycleStatus.succeeded);
      expect(handle.cancellationToken.isCancellationRequested, isFalse);
      expect(result.draftMarkdown, '完成');
    });
  });
}

DraftGenerationProgress _progress(String draftMarkdown) {
  return DraftGenerationProgress(
    phase: 'stream',
    roundIndex: 1,
    draftMarkdown: draftMarkdown,
  );
}

DraftGenerationResult _result({
  required String draftMarkdown,
  bool cancelledByUser = false,
  bool partialContentAccepted = false,
}) {
  return DraftGenerationResult(
    project: const ProjectDescriptor(
      id: 'p1',
      name: 'Project',
      rootPath: 'D:/workspace/project',
    ),
    projectInfo: const <String, Object?>{'id': 'p1'},
    userPrompt: '写一段',
    prompt: '写一段',
    modelId: 'test-model',
    draftMarkdown: draftMarkdown,
    contextPack: const <String, Object?>{'summary': '摘要'},
    selectedPaths: const <String>[],
    executedTools: const <Object?>[],
    writtenPaths: const <String>[],
    changedPaths: const <String>[],
    transcriptMessages: const <JsonMap>[],
    waitingForUserChoice: false,
    reasoningContent: '',
    stoppedByToolError: false,
    toolErrorSummary: '',
    cancelledByUser: cancelledByUser,
    stopPhase: cancelledByUser
        ? DraftGenerationStopPhase.llmRound
        : DraftGenerationStopPhase.none,
    partialContentAccepted: partialContentAccepted,
  );
}
