import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/gui_conversation_command_backend.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

/// GUI 命令后端是纯算法（在传入 sessionRecord 上操作，不持久化），可直接单元测试。
void main() {
  const record = <String, Object?>{
    'id': 'session_a',
    'title': '会话',
    'mode': SessionRecordConstants.modeSmartOpening,
    'workflow_stage': 'draft',
    'public_status': '智能开局',
    'needs_goal_selection': false,
    'is_creative': false,
    'working_context_messages': <Object?>[
      <String, Object?>{'role': 'user', 'content': '第一轮'},
    ],
    'created_at': '2026-06-25T00:00:00.000Z',
    'updated_at': '2026-06-25T00:00:00.000Z',
  };

  group('GuiConversationCommandBackend', () {
    test('setGoalText writes conversation goal and marks persist', () async {
      final backend = GuiConversationCommandBackend();
      final outcome = await backend.setGoalText(record, '收束第三章伏笔');
      expect(outcome.persist, isTrue);
      expect(
        ValueReaders.stringValue(
          outcome.updatedSessionRecord[SessionRecordConstants.conversationGoalField],
        ),
        '收束第三章伏笔',
      );
    });

    test('setMode switches mode via mutation and marks persist', () async {
      final backend = GuiConversationCommandBackend();
      final outcome = await backend.setMode(
        record,
        SessionRecordConstants.modeContinueWriting,
      );
      expect(outcome.persist, isTrue);
      expect(
        ValueReaders.stringValue(outcome.updatedSessionRecord['mode']),
        SessionRecordConstants.modeContinueWriting,
      );
    });

    test('clearContext empties working context and marks persist', () async {
      final backend = GuiConversationCommandBackend();
      final outcome = await backend.clearContext(record);
      expect(outcome.persist, isTrue);
      expect(
        ValueReaders.objectList(
          outcome.updatedSessionRecord[SessionRecordConstants.workingContextMessagesField],
        ),
        isEmpty,
      );
    });

    test('stats is read-only and surfaces pressure snapshot', () async {
      final backend = GuiConversationCommandBackend();
      final outcome = await backend.stats(record);
      expect(outcome.persist, isFalse);
      expect(
        outcome.detail?['pressure_snapshot'],
        isA<Map<String, Object?>>(),
      );
      expect(
        ValueReaders.stringValue(outcome.detail?['public_summary']),
        contains('压力'),
      );
    });

    test('compact persists and carries compaction decision', () async {
      final backend = GuiConversationCommandBackend();
      final outcome = await backend.compact(record);
      expect(outcome.persist, isTrue);
      expect(
        outcome.detail?['compaction_decision'],
        isA<Map<String, Object?>>(),
      );
    });

    test('exitSession signals exit without changing record', () async {
      final backend = GuiConversationCommandBackend();
      final outcome = await backend.exitSession(record);
      expect(outcome.exitSession, isTrue);
      expect(outcome.persist, isFalse);
      expect(
        ValueReaders.stringValue(outcome.updatedSessionRecord['mode']),
        SessionRecordConstants.modeSmartOpening,
      );
    });
  });
}
