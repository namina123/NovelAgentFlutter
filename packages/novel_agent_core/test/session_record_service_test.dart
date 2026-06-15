import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Session record services', () {
    final modeService = SessionModeService();
    final messageService = SessionMessageService();
    final normalizer = SessionRecordNormalizerService(
      modeService: modeService,
      messageService: messageService,
    );
    final mutationService = SessionRecordMutationService(
      normalizerService: normalizer,
      modeService: modeService,
      messageService: messageService,
    );
    final renderer = SessionContextRendererService(
      normalizerService: normalizer,
      messageService: messageService,
    );
    final history = SessionHistoryService(messageService: messageService);

    test('creates and normalizes session record', () {
      // 中文注释: 这里验证新会话骨架会被补齐默认模式、阶段和压缩阈值。
      final session = normalizer.makeSessionRecord(
        mode: '',
        title: '',
        sessionId: 's1',
        createdAt: '2026-05-23T00:00:00Z',
        defaultThresholdChars: 24000,
      );

      expect(session['mode'], SessionRecordConstants.modeUnselected);
      expect(session['workflow_stage'], 'pending_goal');
      expect(session['title'], '新会话');
    });

    test('updates progress and keeps append path free of auto compaction', () {
      // 中文注释: 这里验证新增消息后只会推进创作阶段与消息链，不会在 append 路径里偷偷压缩工作窗口。
      var session = normalizer.makeSessionRecord(
        mode: SessionRecordConstants.modeChapterDraft,
        title: '单章创作',
        sessionId: 's2',
        createdAt: '2026-05-23T00:00:00Z',
        defaultThresholdChars: 1000,
      );
      for (var index = 0; index < 4; index += 1) {
        session = mutationService.sessionWithMessage(
          session,
          'user',
          '正文内容${'x' * 400}',
          createdAt: '2026-05-23T00:00:0${index}Z',
        );
      }

      expect(session['workflow_stage'], 'draft');
      expect(session['compression_count'], 0);
      expect(session['compressed_context'], '');
      expect(session[SessionRecordConstants.compactionSegmentsField], isEmpty);
      expect(
        (session[SessionRecordConstants.transcriptMessagesField]
                as List<Object?>)
            .length,
        4,
      );
      expect(
        (session[SessionRecordConstants.workingContextMessagesField]
                as List<Object?>)
            .length,
        4,
      );
      expect(
        session[SessionRecordConstants.legacyContextMessagesField],
        same(session[SessionRecordConstants.workingContextMessagesField]),
      );
    });

    test('renders context markdown and history window', () {
      // 中文注释: 这里验证会话渲染和历史窗口都能基于同一份消息结构稳定工作。
      final session = <String, Object?>{
        'id': 's3',
        'title': '测试会话',
        'mode': SessionRecordConstants.modeSmartOpening,
        'workflow_stage': 'opening',
        'public_status': '正在开局探索',
        'context_messages': <Object?>[
          <String, Object?>{'role': 'user', 'content': '第一条'},
          <String, Object?>{'role': 'assistant', 'content': '第二条'},
        ],
      };

      final markdown = renderer.sessionContextMarkdown(session);
      final window = history.sessionHistoryWindow(
        session,
        maxMessages: 1,
        maxChars: 100,
      );

      expect(markdown, contains('【工作上下文】'));
      expect((window['messages'] as List<Object?>).length, 1);
      expect(window['has_omitted_history'], isTrue);
    });

    test(
      'history window prefers working context messages over legacy context',
      () {
        // 中文注释: 这里验证历史窗口已经开始消费 working context 主链，而不是继续把旧 context_messages 当成真相源。
        final session = <String, Object?>{
          'id': 's4',
          'title': '工作窗口会话',
          'working_context_messages': <Object?>[
            <String, Object?>{'role': 'user', 'content': '工作窗口第一条'},
            <String, Object?>{'role': 'assistant', 'content': '工作窗口第二条'},
          ],
          'context_messages': <Object?>[
            <String, Object?>{'role': 'user', 'content': '旧桥接内容'},
          ],
        };

        final window = history.sessionHistoryWindow(
          session,
          maxMessages: 10,
          maxChars: 100,
        );

        expect((window['messages'] as List<Object?>), hasLength(2));
        expect(
          (window['messages'] as List<Object?>).first,
          containsPair('content', '工作窗口第一条'),
        );
      },
    );
  });
}
