import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/conversation_tool_lifecycle_status.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_tool_entry_projection_service.dart';
import 'package:novel_agent_app/shared/services/runtime_exposure_policy_service.dart';

void main() {
  group('ConversationToolEntryProjectionService', () {
    test('advanced tier keeps structured arguments and result evidence', () {
      final service = ConversationToolEntryProjectionService(
        exposureTier: RuntimeExposureTier.advanced,
      );

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
      expect(entries.first.detailTitle, '运行证据');
      expect(entries.first.detailSummary, 'drafts/ch01.md');
      expect(entries.first.detailBody, contains('参数'));
      expect(entries.first.detailBody, contains('结果'));
      expect(entries.first.detailBody, contains('drafts/ch01.md'));
    });

    test('standard tier hides raw json and internal runtime fields', () {
      final service = ConversationToolEntryProjectionService();

      final entries = service.build(<Object?>[
        <String, Object?>{
          'id': 'tool_delivery_1',
          'name': 'submit_chapter_delivery',
          'ok': true,
          'prompt_block_id': 'prompt.delivery.writer',
          'tool_profile_id': 'chapter_writer',
          'arguments': <String, Object?>{
            'relative_path': 'drafts/ch01.md',
            'execution_constraint': <String, Object?>{'mode': 'strict'},
          },
          'result': <String, Object?>{
            'relative_path': 'drafts/ch01.md',
            'sub_session_id': 'sub_run_1',
          },
        },
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.title, '章节交付');
      expect(entries.first.body, '已交付章节');
      expect(entries.first.detailTitle, '执行依据');
      expect(entries.first.detailBody, contains('相关对象：drafts/ch01.md'));
      expect(
        entries.first.detailBody,
        isNot(contains('prompt.delivery.writer')),
      );
      expect(entries.first.detailBody, isNot(contains('chapter_writer')));
      expect(entries.first.detailBody, isNot(contains('sub_run_1')));
      expect(entries.first.detailBody, isNot(contains('execution_constraint')));
      expect(entries.first.detailBody, isNot(contains('原始事件 JSON')));
    });

    test('diagnostic tier keeps internal runtime evidence and raw json', () {
      final service = ConversationToolEntryProjectionService(
        exposureTier: RuntimeExposureTier.diagnostic,
      );

      final entries = service.build(<Object?>[
        <String, Object?>{
          'id': 'tool_delivery_1',
          'name': 'submit_chapter_delivery',
          'ok': true,
          'prompt_block_id': 'prompt.delivery.writer',
          'tool_profile_id': 'chapter_writer',
          'arguments': <String, Object?>{
            'relative_path': 'drafts/ch01.md',
            'execution_constraint': <String, Object?>{'mode': 'strict'},
          },
          'result': <String, Object?>{
            'relative_path': 'drafts/ch01.md',
            'sub_session_id': 'sub_run_1',
          },
        },
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.title, 'submit_chapter_delivery');
      expect(entries.first.detailTitle, '工具细节');
      expect(
        entries.first.detailBody,
        contains('Prompt Block：prompt.delivery.writer'),
      );
      expect(entries.first.detailBody, contains('Tool Profile：chapter_writer'));
      expect(entries.first.detailBody, contains('子任务会话：sub_run_1'));
      expect(entries.first.detailBody, contains('原始事件 JSON'));
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

    test('projects information summary from stable tool result contract', () {
      final service = ConversationToolEntryProjectionService();

      final entries = service.build(<Object?>[
        <String, Object?>{
          'id': 'tool_info_1',
          'name': 'propose_knowledge_card',
          'ok': true,
          'result': <String, Object?>{
            'changed_paths': <Object?>[
              '.novel_agent/information/knowledge_cards/knowledge_card_1.json',
              'knowledge/项目知识摘要.md',
            ],
            'checkpoint_review': <String, Object?>{
              'review': <String, Object?>{
                'information_summary': 'information 改动 2 项',
              },
            },
          },
        },
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.body, '已更新资料');
      expect(entries.first.detailSummary, 'information 改动 2 项');
      expect(entries.first.detailBody, contains('信息摘要'));
      expect(entries.first.detailBody, contains('资料状态：已更新资料'));
      expect(entries.first.detailBody, contains('information 改动 2 项'));
      expect(entries.first.detailBody, contains('资料投影：knowledge/项目知识摘要.md'));
    });

    test('maps clarification-style tool results to confirmation wording', () {
      final service = ConversationToolEntryProjectionService();

      final entries = service.build(<Object?>[
        <String, Object?>{
          'id': 'tool_confirm_1',
          'name': 'present_user_options',
          'ok': true,
          'result': <String, Object?>{'question': '这一章要不要切到第二人称？'},
        },
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.body, '需要确认');
      expect(entries.first.detailSummary, '这一章要不要切到第二人称？');
      expect(
        entries.first.toolLifecycleStatus,
        ConversationToolLifecycleStatus.completed,
      );
    });

    test('distinguishes planning file writes from chapter writes', () {
      final service = ConversationToolEntryProjectionService();

      final entries = service.build(<Object?>[
        <String, Object?>{
          'id': 'tool_write_1',
          'name': 'write_project_file',
          'ok': true,
          'arguments': <String, Object?>{
            'relative_path': 'premise/project_brief.md',
          },
          'result': <String, Object?>{
            'relative_path': 'premise/project_brief.md',
          },
        },
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.title, '文件写入');
      expect(entries.first.body, '已更新开局资料');
    });

    test('projects pending tool calls as running lifecycle entries', () {
      final service = ConversationToolEntryProjectionService();

      final entries = service.buildPendingCallEntries(<Object?>[
        <String, Object?>{
          'id': 'pending_1',
          'name': 'read_project_file',
          'arguments': <String, Object?>{'relative_path': 'outline/opening.md'},
        },
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.body, '已发起，正在读取 outline/opening.md');
      expect(
        entries.first.toolLifecycleStatus,
        ConversationToolLifecycleStatus.running,
      );
    });

    test(
      'marks not executed tool results as pending confirmation lifecycle',
      () {
        final service = ConversationToolEntryProjectionService();

        final entries = service.build(<Object?>[
          <String, Object?>{
            'id': 'tool_pending_1',
            'name': 'present_user_options',
            'ok': true,
            'not_executed': true,
            'result': <String, Object?>{'question': '是否继续推进？'},
          },
        ]);

        expect(entries, hasLength(1));
        expect(entries.first.body, '需要确认');
        expect(
          entries.first.toolLifecycleStatus,
          ConversationToolLifecycleStatus.pendingConfirmation,
        );
      },
    );

    test('marks failed tool results as failed lifecycle entries', () {
      final service = ConversationToolEntryProjectionService();

      final entries = service.build(<Object?>[
        <String, Object?>{
          'id': 'tool_failed_1',
          'name': 'write_project_file',
          'ok': false,
          'arguments': <String, Object?>{'relative_path': 'chapters/第01章.md'},
          'result': const <String, Object?>{},
        },
      ]);

      expect(entries, hasLength(1));
      expect(entries.first.body, '需要处理');
      expect(entries.first.isError, isTrue);
      expect(
        entries.first.toolLifecycleStatus,
        ConversationToolLifecycleStatus.failed,
      );
    });
  });
}
