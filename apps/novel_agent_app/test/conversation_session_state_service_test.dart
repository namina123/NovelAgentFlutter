import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'package:novel_agent_app/features/workbench/application/models/conversation_attachment_draft.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_retry_request.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_session_state_service.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_streaming_state_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';

void main() {
  group('ConversationSessionStateService', () {
    test('user prompt clears staged attachments for the current round', () {
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's_attachment_round',
        needsGoalSelection: false,
      );
      final staged = service.stateWithAttachmentDrafts(created, const [
        ConversationAttachmentDraft(
          id: 'a1',
          fileName: 'brief.md',
          localPath: 'D:/demo/brief.md',
          mediaKind: AttachmentMediaKind.file,
          mimeType: 'text/markdown',
          sizeBytes: 128,
          isReady: true,
        ),
      ]);

      expect(staged.attachmentDrafts, hasLength(1));

      final next = service.stateWithUserPrompt(staged, '继续写这一章');

      expect(next.attachmentDrafts, isEmpty);
    });

    test(
      'failed assistant message stays out of session context by default',
      () {
        // 中文注释: 这里验证失败提示只进入时间线展示，不会污染后续发给模型的会话上下文。
        final service = ConversationSessionStateService();
        final created = service.createSession(
          sessionId: 's1',
          needsGoalSelection: false,
        );
        final userState = service.stateWithUserPrompt(created, '先写开场');
        final failedState = service.stateWithAssistantFailure(
          userState,
          '生成失败：网络异常',
        );

        final markdown = service.sessionContextMarkdown(failedState);
        expect(markdown, contains('user: 先写开场'));
        expect(markdown, isNot(contains('网络异常')));
        expect(failedState.entries.last.isError, isTrue);
      },
    );

    test(
      'retry cleanup removes retryable failure entry without removing user turn',
      () {
        // 中文注释: 重试应复用上一轮用户请求，只清掉失败展示和重试态，不制造重复用户消息。
        final service = ConversationSessionStateService();
        final created = service.createSession(
          sessionId: 's_retry',
          needsGoalSelection: false,
        );
        final userState = service.stateWithUserPrompt(created, '继续写开局');
        final failedState = service.stateWithAssistantFailure(
          userState,
          '生成失败：网络超时',
          retryRequest: const ConversationRetryRequest(
            prompt: '继续写开局',
            visibleText: '继续写开局',
            errorMessage: '生成失败：网络超时',
          ),
        );

        final retriedBase = service.stateAfterRetryCleanup(failedState);
        expect(retriedBase.retryRequest, isNull);
        expect(retriedBase.entries, hasLength(1));
        expect(retriedBase.entries.single.kind, ConversationEntryKind.user);
        expect(
          service.sessionContextMarkdown(
            retriedBase,
            excludeLatestUserContent: '继续写开局',
          ),
          isNot(contains('网络超时')),
        );
      },
    );

    test(
      'user prompt can use dedicated visible text without changing context payload',
      () {
        // 中文注释: 用户可见文本与真实上下文消息应拆开，避免工作流入口把内部 prompt 暴露给用户。
        final service = ConversationSessionStateService();
        final created = service.createSession(
          sessionId: 's_visible',
          needsGoalSelection: false,
        );
        final next = service.stateWithUserPrompt(
          created,
          '这是送给模型的长提示词',
          displayContent: '我选择了“智能开局”',
        );

        expect(next.entries.single.body, '我选择了“智能开局”');
        expect(service.sessionContextMarkdown(next), contains('这是送给模型的长提示词'));
      },
    );

    test('assistant result exposes reasoning as collapsed detail payload', () {
      // 中文注释: 助手正文与思考信息需要分栏投影，便于 UI 做折叠展示。
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's2',
        needsGoalSelection: false,
      );
      final result = DraftGenerationResult(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        projectInfo: const <String, Object?>{},
        userPrompt: '写正文',
        prompt: 'prompt',
        modelId: 'test-model',
        draftMarkdown: '这是正文。',
        contextPack: const <String, Object?>{},
        selectedPaths: const <String>[],
        executedTools: const <Object?>[],
        writtenPaths: const <String>[],
        changedPaths: const <String>[],
        transcriptMessages: const <JsonMap>[],
        waitingForUserChoice: false,
        reasoningContent: '先检查设定，再写出开场冲突。',
        stoppedByToolError: false,
        toolErrorSummary: '',
      );

      final next = service.stateWithAssistantResult(created, result);
      final entry = next.entries.single;
      expect(entry.body, '这是正文。');
      expect(entry.detailTitle, '思考');
      expect(entry.detailBody, contains('开场冲突'));
      expect(entry.detailSummary, isNotEmpty);
    });

    test('assistant result keeps reasoning entry even when body is empty', () {
      // 中文注释: 纯工具回合也要保留助手思考条目，否则用户会看到一串工具而完全不知道智能体在想什么。
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's_reasoning_only',
        needsGoalSelection: false,
      );
      final result = DraftGenerationResult(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        projectInfo: const <String, Object?>{},
        userPrompt: '智能开局',
        prompt: 'prompt',
        modelId: 'test-model',
        draftMarkdown: '',
        contextPack: const <String, Object?>{},
        selectedPaths: const <String>[],
        executedTools: const <Object?>[],
        writtenPaths: const <String>[],
        changedPaths: const <String>[],
        transcriptMessages: const <JsonMap>[],
        waitingForUserChoice: false,
        reasoningContent: '先检查项目目录，再决定下一步。',
        stoppedByToolError: false,
        toolErrorSummary: '',
      );

      final next = service.stateWithAssistantResult(created, result);
      expect(next.entries.single.kind, ConversationEntryKind.assistant);
      expect(next.entries.single.detailTitle, '思考');
      expect(next.entries.single.body, isEmpty);
    });

    test('recoverable tool result does not become error entry', () {
      // 中文注释: 工具缺少路径这类可自纠正问题不应在界面里显示成红色错误。
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's_recoverable_tool',
        needsGoalSelection: false,
      );
      final result = DraftGenerationResult(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        projectInfo: const <String, Object?>{},
        userPrompt: '智能开局',
        prompt: 'prompt',
        modelId: 'test-model',
        draftMarkdown: '',
        contextPack: const <String, Object?>{},
        selectedPaths: const <String>[],
        executedTools: const <Object?>[
          <String, Object?>{
            'id': 'tool_1',
            'name': 'read_project_file',
            'ok': false,
            'not_executed': true,
            'arguments': <String, Object?>{},
            'result': <String, Object?>{
              'ok': false,
              'not_executed': true,
              'error': 'read_project_file 缺少 relative_path。',
              'suggested_tool': 'list_project_files',
            },
          },
        ],
        writtenPaths: const <String>[],
        changedPaths: const <String>[],
        transcriptMessages: const <JsonMap>[],
        waitingForUserChoice: false,
        reasoningContent: '',
        stoppedByToolError: false,
        toolErrorSummary: '',
      );

      final next = service.stateWithAssistantResult(created, result);
      expect(next.entries.single.kind, ConversationEntryKind.tool);
      expect(next.entries.single.isError, isFalse);
      expect(next.entries.single.body, contains('需要确认'));
    });

    test('pending options fallback to title and prompt aliases', () {
      // 中文注释: 这里验证 present_user_options 即使只给 title/value，也能正常长出按钮。
      final service = ConversationSessionStateService();
      final created = service.createSession(
        sessionId: 's_pending_alias',
        needsGoalSelection: false,
      );
      final result = DraftGenerationResult(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        projectInfo: const <String, Object?>{},
        userPrompt: '智能开局',
        prompt: 'prompt',
        modelId: 'test-model',
        draftMarkdown: '请先选一个方向。',
        contextPack: const <String, Object?>{},
        selectedPaths: const <String>[],
        executedTools: const <Object?>[
          <String, Object?>{
            'id': 'tool_1',
            'name': 'present_user_options',
            'ok': true,
            'arguments': <String, Object?>{},
            'result': <String, Object?>{
              'ok': true,
              'question': '先选一个方向',
              'options': <Object?>[
                <String, Object?>{
                  'id': 'a',
                  'title': '稳妥开局',
                  'value': '我选择稳妥开局',
                  'description': '先把基础盘稳住。',
                },
              ],
              'waiting_for_user_choice': true,
            },
          },
        ],
        writtenPaths: const <String>[],
        changedPaths: const <String>[],
        transcriptMessages: const <JsonMap>[],
        waitingForUserChoice: true,
        reasoningContent: '',
        stoppedByToolError: false,
        toolErrorSummary: '',
      );

      final next = service.stateWithAssistantResult(created, result);
      expect(next.pendingOptions, hasLength(1));
      expect(next.pendingOptions.first.label, '稳妥开局');
      expect(next.pendingOptions.first.prompt, '我选择稳妥开局');
    });

    test(
      'streaming progress keeps live assistant visible during tool phase',
      () {
        // 中文注释: 工具调用期间即使当前分片没有正文增量，也要保住已经出现的出字内容。
        final sessionService = ConversationSessionStateService();
        final streamingService = ConversationStreamingStateService(
          sessionStateService: sessionService,
        );
        final created = sessionService.createSession(
          sessionId: 's_streaming',
          needsGoalSelection: false,
        );
        final userState = sessionService.stateWithUserPrompt(created, '继续写');

        final first = streamingService.stateWithProgress(
          userState,
          const DraftGenerationProgress(
            phase: 'llm_streaming',
            roundIndex: 0,
            draftMarkdown: '正在出现的正文',
            reasoningContent: '先看规格',
            pendingToolCalls: <JsonMap>[
              <String, Object?>{
                'id': 'tool_1',
                'name': 'read_project_file',
                'arguments': <String, Object?>{
                  'relative_path': 'specs/project_brief.md',
                },
              },
            ],
          ),
        );

        final second = streamingService.stateWithProgress(
          first,
          const DraftGenerationProgress(
            phase: 'tool_calls_ready',
            roundIndex: 0,
            draftMarkdown: '',
            reasoningContent: '',
            pendingToolCalls: <JsonMap>[
              <String, Object?>{
                'id': 'tool_1',
                'name': 'read_project_file',
                'arguments': <String, Object?>{
                  'relative_path': 'specs/project_brief.md',
                },
              },
            ],
          ),
        );

        expect(first.entries, hasLength(3));
        expect(first.entries.last.kind, ConversationEntryKind.assistant);
        expect(first.entries.last.body, contains('正在出现'));
        expect(second.entries, hasLength(3));
        expect(second.entries.last.kind, ConversationEntryKind.assistant);
        expect(second.entries.last.body, contains('正在出现'));
      },
    );

    test(
      'streaming progress does not duplicate current round tool entries',
      () {
        final sessionService = ConversationSessionStateService();
        final streamingService = ConversationStreamingStateService(
          sessionStateService: sessionService,
        );
        final created = sessionService.createSession(
          sessionId: 's_streaming_tools',
          needsGoalSelection: false,
        );
        final userState = sessionService.stateWithUserPrompt(created, '继续写');
        const executedTools = <Object?>[
          <String, Object?>{
            'id': 'tool_1',
            'name': 'read_project_file',
            'ok': true,
            'arguments': <String, Object?>{
              'relative_path': 'premise/project_brief.md',
            },
            'result': <String, Object?>{
              'ok': true,
              'relative_path': 'premise/project_brief.md',
            },
          },
        ];

        final first = streamingService.stateWithProgress(
          userState,
          const DraftGenerationProgress(
            phase: 'tool_round_completed',
            roundIndex: 0,
            draftMarkdown: '',
            reasoningContent: '',
            executedTools: executedTools,
          ),
        );
        final second = streamingService.stateWithProgress(
          first,
          const DraftGenerationProgress(
            phase: 'llm_completed',
            roundIndex: 0,
            draftMarkdown: '已经有了正文。',
            reasoningContent: '',
            executedTools: executedTools,
          ),
        );

        expect(
          first.entries.where(
            (entry) => entry.kind == ConversationEntryKind.tool,
          ),
          hasLength(1),
        );
        expect(
          second.entries.where(
            (entry) => entry.kind == ConversationEntryKind.tool,
          ),
          hasLength(1),
        );
      },
    );

    test(
      'cancelled result with partial content keeps assistant entry and adds runtime notice',
      () {
        final service = ConversationSessionStateService();
        final created = service.createSession(
          sessionId: 's_cancelled_partial',
          needsGoalSelection: false,
        );
        final userState = service.stateWithUserPrompt(created, '继续写这一段');
        final result = DraftGenerationResult(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          projectInfo: const <String, Object?>{},
          userPrompt: '继续写这一段',
          prompt: 'prompt',
          modelId: 'test-model',
          draftMarkdown: '保留下来的半段正文。',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>[],
          executedTools: const <Object?>[],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
          cancelledByUser: true,
          stopPhase: DraftGenerationStopPhase.llmRound,
          partialContentAccepted: true,
        );

        final next = service.stateWithAssistantResult(userState, result);

        expect(next.entries, hasLength(3));
        expect(next.entries[1].kind, ConversationEntryKind.assistant);
        expect(next.entries[1].body, '保留下来的半段正文。');
        expect(next.entries[2].kind, ConversationEntryKind.system);
        expect(next.entries[2].title, '本轮已停止');
        expect(next.entries[2].body, contains('保留已完成的阶段内容'));
        expect(next.retryRequest, isNull);
      },
    );

    test(
      'cancelled result without partial content offers retry without failure styling',
      () {
        final service = ConversationSessionStateService();
        final created = service.createSession(
          sessionId: 's_cancelled_empty',
          needsGoalSelection: false,
        );
        final userState = service.stateWithUserPrompt(
          created,
          '送给模型的真实提示词',
          displayContent: '用户看到的入口文案',
        );
        final result = DraftGenerationResult(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          projectInfo: const <String, Object?>{},
          userPrompt: '送给模型的真实提示词',
          prompt: 'prompt',
          modelId: 'test-model',
          draftMarkdown: '',
          contextPack: const <String, Object?>{},
          selectedPaths: const <String>[],
          executedTools: const <Object?>[],
          writtenPaths: const <String>[],
          changedPaths: const <String>[],
          transcriptMessages: const <JsonMap>[],
          waitingForUserChoice: false,
          reasoningContent: '',
          stoppedByToolError: false,
          toolErrorSummary: '',
          cancelledByUser: true,
          stopPhase: DraftGenerationStopPhase.preparingContext,
          partialContentAccepted: false,
        );

        final next = service.stateWithAssistantResult(userState, result);

        expect(next.entries, hasLength(2));
        expect(next.entries.last.kind, ConversationEntryKind.system);
        expect(next.entries.last.isError, isFalse);
        expect(next.retryRequest, isNotNull);
        expect(next.retryRequest!.label, '重试这次已停止请求');
        expect(next.retryRequest!.visibleText, '用户看到的入口文案');
        expect(next.retryRequest!.errorMessage, isEmpty);
      },
    );

    test(
      'restoreSession rebuilds visible entries from persisted session record',
      () {
        final service = ConversationSessionStateService();
        final restored = service.restoreSession(<String, Object?>{
          'id': 'restored_session',
          'title': '历史会话',
          'mode': SessionRecordConstants.modeContinueWriting,
          'workflow_stage': 'draft',
          'public_status': '继续写作',
          'needs_goal_selection': false,
          'is_creative': true,
          'context_messages': <Object?>[
            <String, Object?>{'role': 'user', 'content': '先看设定'},
            <String, Object?>{'role': 'assistant', 'content': '我先整理人物。'},
          ],
          'compressed_context': 'older summary',
          'compression_count': 1,
          'compression_threshold_chars': 12000,
          'total_context_chars': 20,
          'created_at': '2026-06-14T00:00:00.000Z',
          'updated_at': '2026-06-14T00:02:00.000Z',
        });

        expect(restored.entries, hasLength(3));
        expect(restored.entries.first.kind, ConversationEntryKind.system);
        expect(restored.entries.first.title, '更早历史');
        expect(restored.entries[1].kind, ConversationEntryKind.user);
        expect(restored.entries[1].body, '先看设定');
        expect(restored.entries[2].kind, ConversationEntryKind.assistant);
        expect(restored.entries[2].body, '我先整理人物。');
      },
    );

    test(
      'restoreSession restores archive folds and working window from split session record',
      () {
        // 中文注释: 新三分记录恢复后应先回放 archive fold，再回放完整 transcript，最后补一个工作窗口提示。
        final service = ConversationSessionStateService();
        final restored = service.restoreSession(<String, Object?>{
          'id': 'split_session',
          'title': '分层会话',
          'mode': SessionRecordConstants.modeContinueWriting,
          'workflow_stage': 'draft',
          'public_status': '继续写作',
          'needs_goal_selection': false,
          'is_creative': true,
          'transcript_messages': <Object?>[
            <String, Object?>{'role': 'user', 'content': '第一轮：先看前情'},
            <String, Object?>{'role': 'assistant', 'content': '我先整理前情。'},
            <String, Object?>{'role': 'user', 'content': '第二轮：继续推进'},
          ],
          'working_context_messages': <Object?>[
            <String, Object?>{'role': 'assistant', 'content': '我先整理前情。'},
            <String, Object?>{'role': 'user', 'content': '第二轮：继续推进'},
          ],
          'compaction_segments': <Object?>[
            <String, Object?>{
              'id': 'segment_1',
              'kind': 'preflight_compaction',
              'title': '更早历史',
              'summary': '压缩片段 1（自动）：\n更早历史摘要',
              'source_message_count': 2,
              'source_message_roles': <String>['user', 'assistant'],
              'created_at': '2026-06-14T00:00:00.000Z',
            },
          ],
          'pinned_context_refs': <Object?>['scene.anchor'],
          'compressed_context': '',
          'compression_count': 1,
          'compression_threshold_chars': 12000,
          'total_context_chars': 20,
          'created_at': '2026-06-14T00:00:00.000Z',
          'updated_at': '2026-06-14T00:05:00.000Z',
        });

        expect(restored.entries, hasLength(5));
        expect(restored.entries[0].kind, ConversationEntryKind.system);
        expect(restored.entries[0].title, '更早历史');
        expect(restored.entries[0].body, contains('更早历史摘要'));
        expect(restored.entries[1].kind, ConversationEntryKind.user);
        expect(restored.entries[1].body, '第一轮：先看前情');
        expect(restored.entries[3].kind, ConversationEntryKind.user);
        expect(restored.entries[3].body, '第二轮：继续推进');
        expect(restored.entries[4].kind, ConversationEntryKind.system);
        expect(restored.entries[4].title, '当前工作上下文');
        expect(restored.entries[4].body, contains('最近 2 条消息'));
        expect(restored.entries[4].detailBody, contains('assistant: 我先整理前情。'));
        expect(restored.sessionRecord['transcript_messages'], hasLength(3));
        expect(
          restored.sessionRecord['working_context_messages'],
          hasLength(2),
        );
      },
    );
  });
}
