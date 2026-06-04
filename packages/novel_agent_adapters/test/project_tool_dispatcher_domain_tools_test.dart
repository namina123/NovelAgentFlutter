import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectToolDispatcher domain tools', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectToolDispatcher dispatcher;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-dispatcher-domain-',
      );
      final workspacePort = LocalProjectWorkspacePort();
      final hostPort = ProjectWorkspaceToolHostAdapter(
        workspacePort: workspacePort,
        fileMutationAdapter: LocalProjectFileMutationAdapter(),
      );
      project = ProjectDescriptor(
        id: 'demo',
        name: '示例项目',
        rootPath: tempDirectory.path,
      );
      dispatcher = ProjectToolDispatcher(hostPort: hostPort);
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'routes submit_chapter_delivery as domain tool and keeps outcome separate from transcript summary',
      () async {
        final result = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'delivery-call-1',
            'name': 'submit_chapter_delivery',
            'source_type': NarrativeSourceTypes.writer,
            'tool_round_evidence': <String, Object?>{
              'tool_round_ref': <String, Object?>{
                'ref_type': NarrativeRefTypes.toolRound,
                'ref_id': 'round-1',
              },
              'tool_call_ids': <Object?>['delivery-call-1'],
            },
            'arguments': <String, Object?>{
              'chapter_path': 'chapters/chapter_01.md',
              'chapter_content': '# 第一章\n\n雨水打在旧窗框上。',
              'title': '第一章',
              'submission': <String, Object?>{
                'submission_id': 'delivery-1',
                'summary': '完成本章',
              },
            },
          },
        );

        expect(result['ok'], isTrue);
        expect(result['tool_layer'], 'domain');
        expect(result['interaction_type'], 'domain_tool');
        expect(
          ValueReaders.mapValue(result['tool_capability'])['capability_kind'],
          'narrative_domain_tool',
        );
        expect(result['domain_tool_name'], 'submit_chapter_delivery');
        expect(result['domain_outcome_status'], 'accepted');
        expect(
          ValueReaders.stringList(result['changed_paths']),
          contains('chapters/chapter_01.md'),
        );
        expect(
          ValueReaders.stringValue(result['tool_result_summary']),
          contains('已执行领域工具'),
        );
        expect(result.containsKey('tool_round_evidence'), isFalse);

        final domainOutcome = ValueReaders.mapValue(result['domain_outcome']);
        expect(
          ValueReaders.stringValue(domainOutcome['outcome_status']),
          'accepted',
        );
        expect(
          ValueReaders.mapValue(domainOutcome['tool_round_evidence']),
          isNotEmpty,
        );
      },
    );

    test(
      'routes request_profile_clarification into waiting-user domain result',
      () async {
        final result = await dispatcher.execute(
          project: project,
          toolCall: <String, Object?>{
            'id': 'clarification-call-1',
            'name': 'request_profile_clarification',
            'arguments': <String, Object?>{
              'question': '该规则是只限本章还是长期生效？',
              'options': <Object?>[
                <String, Object?>{'label': '只限本章'},
                <String, Object?>{'label': '长期生效'},
              ],
              'blocking': true,
            },
          },
        );

        expect(result['ok'], isTrue);
        expect(result['tool_layer'], 'domain');
        expect(result['waiting_for_user_choice'], isTrue);
        expect(result['domain_outcome_status'], 'needs_user_confirmation');
        expect(
          ValueReaders.stringList(result['changed_paths']),
          contains(
            '.novel_agent/continuity/clarifications/clarification_clarification-call-1.json',
          ),
        );
      },
    );

    test(
      'returns structured parse issues for malformed domain tool payloads',
      () async {
        final result = await dispatcher.execute(
          project: project,
          toolCall: const <String, Object?>{
            'id': 'claims-call-1',
            'name': 'submit_narrative_state_claims',
            'arguments': <String, Object?>{'claims': 'not-an-array'},
          },
        );

        expect(result['ok'], isFalse);
        expect(result['tool_layer'], 'domain');
        expect(result['interaction_type'], 'domain_tool');
        expect(
          ValueReaders.objectList(result['domain_parse_issues']),
          isNotEmpty,
        );
        expect(result.containsKey('domain_outcome'), isFalse);
      },
    );

    test('keeps write_project_file as low-level tool', () async {
      final result = await dispatcher.execute(
        project: project,
        toolCall: const <String, Object?>{
          'name': 'write_project_file',
          'arguments': <String, Object?>{
            'content_type': 'chapter',
            'title': '第二章',
            'relative_path': 'chapters/chapter_02.md',
            'content': '# 第二章\n\n正文',
            'overwrite': true,
          },
        },
      );

      expect(result['ok'], isTrue);
      expect(result['tool_layer'], 'low_level');
      expect(
        ValueReaders.mapValue(result['tool_capability'])['capability_kind'],
        'project_low_level_tool',
      );
      expect(result['relative_path'], 'chapters/chapter_02.md');
      expect(result.containsKey('domain_outcome'), isFalse);
    });
  });
}
