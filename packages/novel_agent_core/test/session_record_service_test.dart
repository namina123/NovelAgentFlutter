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
      modeService: modeService,
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

    test('updates progress and compresses when messages exceed threshold', () {
      // 中文注释: 这里验证新增消息后会推进创作阶段，并在超阈值时自动把前文压缩进摘要。
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
      expect(session['compression_count'], greaterThan(0));
      expect((session['compressed_context'] as String), contains('压缩片段'));
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

      expect(markdown, contains('【最近对话】'));
      expect((window['messages'] as List<Object?>).length, 1);
      expect(window['has_omitted_history'], isTrue);
    });
  });
}
