import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_tool_entry_projection_service.dart';

void main() {
  group('ConversationToolEntryProjectionService', () {
    test('builds tool detail body from arguments and result', () {
      final service = ConversationToolEntryProjectionService();

      final entries = service.build(<Object?>[
        <String, Object?>{
          'id': 'tool_1',
          'name': 'read_project_file',
          'ok': true,
          'arguments': <String, Object?>{'relative_path': 'drafts/ch01.md'},
          'result': <String, Object?>{
            'relative_path': 'drafts/ch01.md',
            'content': '...',
          },
        },
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.detailTitle, '工具细节');
      expect(entries.first.detailSummary, 'drafts/ch01.md');
      expect(entries.first.detailBody, contains('参数'));
      expect(entries.first.detailBody, contains('结果'));
      expect(entries.first.detailBody, contains('drafts/ch01.md'));
    });

    test('preserves detail fields when compressing repeated tool entries', () {
      final service = ConversationToolEntryProjectionService();

      final entries = service.build(<Object?>[
        <String, Object?>{
          'id': 'tool_1',
          'name': 'read_project_file',
          'ok': true,
          'arguments': <String, Object?>{'relative_path': 'outline/main.md'},
          'result': <String, Object?>{'relative_path': 'outline/main.md'},
        },
        <String, Object?>{
          'id': 'tool_2',
          'name': 'read_project_file',
          'ok': true,
          'arguments': <String, Object?>{'relative_path': 'outline/main.md'},
          'result': <String, Object?>{'relative_path': 'outline/main.md'},
        },
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.title, contains('×2'));
      expect(entries.first.detailBody, contains('outline/main.md'));
    });

    test('suppresses call_sub_agent raw timeline entry', () {
      final service = ConversationToolEntryProjectionService();

      final entries = service.build(<Object?>[
        <String, Object?>{
          'id': 'tool_sub_1',
          'name': 'call_sub_agent',
          'ok': true,
          'arguments': <String, Object?>{'task': '补完第二章贸易细节'},
          'result': <String, Object?>{
            'sub_agent_run_id': 'sub_run_1',
            'agent_name': '资料考据员',
          },
        },
      ]);

      expect(entries, isEmpty);
    });
  });
}
