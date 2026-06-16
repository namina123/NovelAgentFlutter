import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SessionRecordNormalizerService', () {
    final modeService = SessionModeService();
    final messageService = SessionMessageService();
    final normalizer = SessionRecordNormalizerService(
      modeService: modeService,
      messageService: messageService,
    );

    test('creates split record fields for a new session', () {
      // 中文注释: 新会话骨架必须直接带上 transcript / working / archive 三分字段，方便后续主链只认正式合同。
      final session = normalizer.makeSessionRecord(
        mode: SessionRecordConstants.modeSmartOpening,
        title: '新会话',
        sessionId: 'session-1',
        createdAt: '2026-06-14T00:00:00Z',
        defaultThresholdChars: 24000,
      );

      expect(session[SessionRecordConstants.transcriptMessagesField], isEmpty);
      expect(
        session[SessionRecordConstants.workingContextMessagesField],
        isEmpty,
      );
      expect(session[SessionRecordConstants.compactionSegmentsField], isEmpty);
      expect(session[SessionRecordConstants.pinnedContextRefsField], isEmpty);
      expect(
        session[SessionRecordConstants.legacyContextMessagesField],
        isEmpty,
      );
      expect(session[SessionRecordConstants.legacyCompressedContextField], '');
      expect(session[SessionRecordConstants.transcriptContextCharsField], 0);
      expect(session[SessionRecordConstants.workingContextCharsField], 0);
      expect(session[SessionRecordConstants.compactionArchiveCharsField], 0);
    });

    test(
      'normalizes legacy context and archive fields into split structure',
      () {
        // 中文注释: 旧记录只有 context_messages / compressed_context 时，归一化后仍应补出三分合同。
        final session = <String, Object?>{
          'id': 'legacy-session',
          'mode': SessionRecordConstants.modeChapterDraft,
          'workflow_stage': 'draft',
          'context_messages': <Object?>[
            <String, Object?>{'role': 'user', 'content': '第一条正文'},
            <String, Object?>{'role': 'assistant', 'content': '第二条正文'},
          ],
          'compressed_context': '压缩片段 1（自动）：\n更早历史摘要',
          'compression_count': 2,
          'compression_threshold_chars': 1000,
          'created_at': '2026-06-14T00:00:00Z',
          'updated_at': '2026-06-14T00:00:00Z',
        };

        final normalized = normalizer.normalizeSessionRecord(
          session,
          defaultThresholdChars: 24000,
        );

        expect(
          normalized[SessionRecordConstants.transcriptMessagesField],
          hasLength(2),
        );
        expect(
          normalized[SessionRecordConstants.workingContextMessagesField],
          hasLength(2),
        );
        expect(
          normalized[SessionRecordConstants.compactionSegmentsField],
          hasLength(1),
        );
        expect(
          normalized[SessionRecordConstants.pinnedContextRefsField],
          isEmpty,
        );
        expect(
          normalized[SessionRecordConstants.legacyContextMessagesField],
          hasLength(2),
        );
        expect(
          normalized[SessionRecordConstants.legacyCompressedContextField],
          contains('更早历史摘要'),
        );
        expect(normalized[SessionRecordConstants.compressionCountField], 2);
        expect(
          normalized[SessionRecordConstants.transcriptContextCharsField],
          greaterThan(0),
        );
        expect(
          normalized[SessionRecordConstants.workingContextCharsField],
          greaterThan(0),
        );
        expect(
          normalized[SessionRecordConstants.compactionArchiveCharsField],
          greaterThan(0),
        );
      },
    );

    test('preserves pinned context refs as string references', () {
      // 中文注释: pinned refs 是稳定字符串引用，不应该在归一化时被当成 map 丢掉。
      final session = <String, Object?>{
        'id': 'pinned-session',
        'mode': SessionRecordConstants.modeChapterDraft,
        'workflow_stage': 'draft',
        'working_context_messages': <Object?>[
          <String, Object?>{'role': 'user', 'content': '正文一'},
        ],
        'pinned_context_refs': <Object?>['scene.anchor', 'timeline.anchor'],
      };

      final normalized = normalizer.normalizeSessionRecord(
        session,
        defaultThresholdChars: 24000,
      );

      expect(
        normalized[SessionRecordConstants.pinnedContextRefsField],
        <String>['scene.anchor', 'timeline.anchor'],
      );
    });

    test('keeps stopped sessions in a visible closed status', () {
      // 中文注释: stopped 需要变成明确的公开状态，后续 CLI stop 命令才能把会话收束得可见可查。
      final session = <String, Object?>{
        'id': 'stopped-session',
        'mode': SessionRecordConstants.modeContinueWriting,
        'workflow_stage': 'stopped',
        'working_context_messages': <Object?>[
          <String, Object?>{'role': 'user', 'content': '最后一轮正文'},
        ],
      };

      final normalized = normalizer.normalizeSessionRecord(
        session,
        defaultThresholdChars: 24000,
      );

      expect(normalized['workflow_stage'], 'stopped');
      expect(normalized['public_status'], '已停止');
    });

    test('keeps an explicitly empty working context empty', () {
      // 中文注释: 这条回归确保 clearWorkingContext 后的显式空工作窗口不会又回退成 transcript。
      final session = <String, Object?>{
        'id': 'empty-working-session',
        'mode': SessionRecordConstants.modeChapterDraft,
        'workflow_stage': 'draft',
        'transcript_messages': <Object?>[
          <String, Object?>{'role': 'user', 'content': '完整历史 1'},
          <String, Object?>{'role': 'assistant', 'content': '完整历史 2'},
        ],
        'working_context_messages': <Object?>[],
      };

      final normalized = normalizer.normalizeSessionRecord(
        session,
        defaultThresholdChars: 24000,
      );

      expect(
        normalized[SessionRecordConstants.transcriptMessagesField],
        hasLength(2),
      );
      expect(
        normalized[SessionRecordConstants.workingContextMessagesField],
        isEmpty,
      );
      expect(
        normalized[SessionRecordConstants.legacyContextMessagesField],
        isEmpty,
      );
    });
  });
}
