import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_session_state.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_session_context_projection_service.dart';

void main() {
  group('ConversationSessionContextProjectionService', () {
    test(
      'projects pressure, transcript counts and archive segments from session state',
      () {
        final service = ConversationSessionContextProjectionService();
        final state = ConversationSessionState(
          sessionRecord: <String, Object?>{
            'id': 'session_1',
            SessionRecordConstants.transcriptMessagesField: [
              <String, Object?>{'role': 'user', 'content': '开场。'},
              <String, Object?>{'role': 'assistant', 'content': '继续。'},
              <String, Object?>{'role': 'assistant', 'content': '补充。'},
            ],
            SessionRecordConstants.workingContextMessagesField: [
              <String, Object?>{'role': 'user', 'content': '开场。'},
              <String, Object?>{'role': 'assistant', 'content': '继续。'},
            ],
            SessionRecordConstants.compactionSegmentsField: [
              <String, Object?>{
                'title': '发送前压缩',
                'summary': '已压缩保存更早历史',
                'source_message_count': 3,
                'source_message_roles': ['user', 'assistant'],
                'created_at': '2026-06-14T00:00:00.000Z',
              },
            ],
          },
          entries: const [],
          pendingOptions: const [],
          subAgentRuns: const [],
          attachmentDrafts: const [],
          retryRequest: null,
        );

        final projection = service.build(
          state: state,
          runtimeProfile: const <String, Object?>{
            'context_length': 1000,
            'max_output_tokens': 100,
          },
        );

        expect(projection.transcriptMessageCount, 3);
        expect(projection.workingContextMessageCount, 2);
        expect(projection.compactionSegments, hasLength(1));
        expect(projection.archiveSummary, '1 段 / 3 条');
        expect(projection.fullHistorySummary, '3 条');
        expect(projection.workingWindowSummary, '2 条');
        expect(
          projection.pressureSnapshot.settings.modelContextWindowTokens,
          1000,
        );
        expect(projection.pressureSnapshot.inputBudgetTokens, 900);
        expect(projection.headlineSummary, contains('完整历史 3 条'));
        expect(projection.headlineSummary, contains('工作窗口 2 条'));
        expect(projection.archiveDetail, contains('来源 3 条消息'));
      },
    );
  });
}
