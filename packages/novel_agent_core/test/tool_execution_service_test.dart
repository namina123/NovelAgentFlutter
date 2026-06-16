import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolExecutionService', () {
    test(
      'collects changed paths, written paths and transcript messages',
      () async {
        // 中文注释: 这里验证工具轮执行服务会统一回收一轮工具调用产生的状态与消息。
        final service = ToolExecutionService(
          toolExecutionPort: _FakeToolExecutionPort(
            resultByToolName: <String, JsonMap>{
              'write_project_file': <String, Object?>{
                'ok': true,
                'relative_path': 'chapters/chapter_01.md',
                'changed_paths': <Object?>['chapters/chapter_01.md'],
              },
              'present_user_options': <String, Object?>{
                'ok': true,
                'waiting_for_user_choice': true,
                'changed_paths': const <Object?>[],
              },
            },
          ),
        );

        final result = await service.executeRound(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          assistantMessage: const <String, Object?>{
            'role': 'assistant',
            'content': '',
          },
          toolCalls: const <Object?>[
            <String, Object?>{
              'id': 'call_1',
              'name': 'write_project_file',
              'arguments': <String, Object?>{
                'relative_path': 'chapters/chapter_01.md',
                'content': '# 第一章',
              },
            },
            <String, Object?>{
              'id': 'call_2',
              'name': 'present_user_options',
              'arguments': <String, Object?>{'question': '下一步？'},
            },
          ],
        );

        expect(result.executedTools, hasLength(2));
        expect(result.changedPaths, contains('chapters/chapter_01.md'));
        expect(result.writtenPaths, contains('chapters/chapter_01.md'));
        expect(result.waitingForUserChoice, isTrue);
        expect(result.transcriptMessages, hasLength(3));
      },
    );

    test(
      'fills read tool relative_path from active document context when missing',
      () async {
        // 中文注释: 这里验证模型把读取参数丢成空对象时，核心层可以用当前打开文件路径做最小兜底。
        final port = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'read_project_file': <String, Object?>{
              'ok': true,
              'relative_path': 'specs/project_brief.md',
              'content': '# 项目简介',
              'changed_paths': const <Object?>[],
            },
          },
        );
        final service = ToolExecutionService(toolExecutionPort: port);

        await service.executeRound(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          assistantMessage: const <String, Object?>{
            'role': 'assistant',
            'content': '',
          },
          toolCalls: const <Object?>[
            <String, Object?>{
              'id': 'call_1',
              'name': 'read_project_file',
              'arguments': <String, Object?>{},
            },
          ],
          mainContext: const <String, Object?>{
            'active_document_path': 'specs/project_brief.md',
          },
        );

        expect(
          port.lastCallArguments['relative_path'],
          'specs/project_brief.md',
        );
      },
    );

    test(
      'injects workflow task context into set_agent_tasks arguments',
      () async {
        final port = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'set_agent_tasks': <String, Object?>{
              'ok': true,
              'changed_paths': const <Object?>[],
            },
          },
        );
        final service = ToolExecutionService(toolExecutionPort: port);

        await service.executeRound(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          assistantMessage: const <String, Object?>{
            'role': 'assistant',
            'content': '',
          },
          toolCalls: const <Object?>[
            <String, Object?>{
              'id': 'call_1',
              'name': 'set_agent_tasks',
              'arguments': <String, Object?>{
                'goal': '补齐规划产物',
                'tasks': <Object?>[
                  <String, Object?>{'id': 'write_spec', 'title': '写入项目规格'},
                ],
              },
            },
          ],
          mainContext: const <String, Object?>{
            'workflow_task_context': <String, Object?>{
              'id': 'planning_seed_001',
              'mode': 'seed_to_full_novel',
              'metadata': <String, Object?>{
                'plan_id': 'plan_seed_001',
                'runtime_baseline_id': 'continuous_autonomous',
              },
            },
          },
        );

        final injected = ValueReaders.mapValue(
          port.lastCallArguments['_workflow_task_context'],
        );
        expect(ValueReaders.stringValue(injected['id']), 'planning_seed_001');
        expect(
          ValueReaders.stringValue(injected['mode']),
          'seed_to_full_novel',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(injected['metadata'])['plan_id'],
          ),
          'plan_seed_001',
        );
      },
    );

    test(
      'injects chapter length metadata into submit_chapter_delivery when runtime constraints exist',
      () async {
        final port = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            NarrativeDomainToolNames.submitChapterDelivery: <String, Object?>{
              'ok': true,
              'changed_paths': const <Object?>[],
            },
          },
        );
        final service = ToolExecutionService(toolExecutionPort: port);

        await service.executeRound(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          assistantMessage: const <String, Object?>{
            'role': 'assistant',
            'content': '',
          },
          toolCalls: const <Object?>[
            <String, Object?>{
              'id': 'call_1',
              'name': NarrativeDomainToolNames.submitChapterDelivery,
              'arguments': <String, Object?>{
                'chapter_path': 'chapters/第03章.md',
                'chapter_content': '# 第03章\n\n正文',
                'title': '第03章',
              },
            },
          ],
          mainContext: const <String, Object?>{
            'writing_execution_constraints': <String, Object?>{
              'chapter_length_metadata': <String, Object?>{
                'chapter_length_profile': <String, Object?>{
                  'enabled': true,
                  'target_length': 2200,
                  'preferred_min': 1800,
                  'preferred_max': 2600,
                },
              },
            },
          },
        );

        final chapterLengthProfile = ValueReaders.mapValue(
          ValueReaders.mapValue(
            ValueReaders.mapValue(
              port.lastCallArguments['metadata'],
            )['chapter_length_metadata'],
          )['chapter_length_profile'],
        );
        expect(
          ValueReaders.intValue(chapterLengthProfile['target_length']),
          2200,
        );
        expect(
          ValueReaders.intValue(chapterLengthProfile['preferred_min']),
          1800,
        );
        expect(
          ValueReaders.intValue(chapterLengthProfile['preferred_max']),
          2600,
        );
      },
    );

    test('deduplicates repeated load_agent_skill calls in one run', () async {
      // 中文注释: 这里验证同一任务中重复读取同一技能会被执行层直接拦下，不再重复打到宿主工具端口。
      final port = _FakeToolExecutionPort(
        resultByToolName: <String, JsonMap>{
          'load_agent_skill': <String, Object?>{
            'ok': true,
            'skill_id': 'chapter_drafting_method',
            'detail_level': 'summary',
            'content': '摘要',
            'changed_paths': const <Object?>[],
          },
        },
      );
      final service = ToolExecutionService(toolExecutionPort: port);
      final memory = SkillLoadMemory();

      await service.executeRound(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        assistantMessage: const <String, Object?>{
          'role': 'assistant',
          'content': '',
        },
        toolCalls: const <Object?>[
          <String, Object?>{
            'id': 'call_1',
            'name': 'load_agent_skill',
            'arguments': <String, Object?>{
              'skill_id': 'chapter_drafting_method',
              'detail_level': 'summary',
            },
          },
        ],
        skillLoadMemory: memory,
      );
      final secondRound = await service.executeRound(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        assistantMessage: const <String, Object?>{
          'role': 'assistant',
          'content': '',
        },
        toolCalls: const <Object?>[
          <String, Object?>{
            'id': 'call_2',
            'name': 'load_agent_skill',
            'arguments': <String, Object?>{
              'skill_id': 'chapter_drafting_method',
              'detail_level': 'summary',
            },
          },
        ],
        skillLoadMemory: memory,
      );

      expect(
        port.executedToolNames.where((name) => name == 'load_agent_skill'),
        hasLength(1),
      );
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(
            secondRound.executedTools.single,
          )['not_executed'],
        ),
        isTrue,
      );
    });

    test(
      'blocks call_sub_agent behind host tool permission confirmation flow',
      () async {
        final port = _FakeToolExecutionPort(
          resultByToolName: const <String, JsonMap>{},
        );
        final service = ToolExecutionService(
          toolExecutionPort: port,
          hostToolPermissionContext: const HostToolPermissionContext(
            allowSubAgents: false,
            permissionMode: HostToolPermissionModes.safe,
            confirmationMode:
                HostToolConfirmationModes.userConfirmationRequired,
            source: 'tool_execution_service_test',
          ),
        );

        final result = await service.executeRound(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          assistantMessage: const <String, Object?>{
            'role': 'assistant',
            'content': '',
          },
          toolCalls: const <Object?>[
            <String, Object?>{
              'id': 'call_sub_1',
              'name': 'call_sub_agent',
              'arguments': <String, Object?>{
                'agent_id': 'reviewer',
                'task': '检查上一段。',
              },
            },
          ],
        );

        expect(port.executedToolNames, isEmpty);
        expect(result.waitingForUserChoice, isTrue);
        final toolResult = ValueReaders.mapValue(
          ValueReaders.mapValue(result.executedTools.single)['result'],
        );
        expect(ValueReaders.boolValue(toolResult['not_executed']), isTrue);
        expect(
          ValueReaders.boolValue(toolResult['waiting_for_user_choice']),
          isTrue,
        );
        expect(ValueReaders.objectList(toolResult['options']), isNotEmpty);
      },
    );
  });
}

class _FakeToolExecutionPort implements ToolExecutionPort {
  _FakeToolExecutionPort({required Map<String, JsonMap> resultByToolName})
    : _resultByToolName = resultByToolName;

  final Map<String, JsonMap> _resultByToolName;
  final List<String> executedToolNames = <String>[];
  JsonMap lastCallArguments = const <String, Object?>{};

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    // 中文注释: 测试替身按工具名返回预设结果，帮助聚焦轮执行服务的聚合逻辑。
    executedToolNames.add(ValueReaders.stringValue(toolCall['name']));
    lastCallArguments = ValueReaders.mapValue(toolCall['arguments']);
    return _resultByToolName[toolCall['name']] ??
        <String, Object?>{'ok': true, 'changed_paths': const <Object?>[]};
  }
}
