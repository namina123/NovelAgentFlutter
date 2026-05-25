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
                'relative_path': 'drafts/chapter_01.md',
                'changed_paths': <Object?>['drafts/chapter_01.md'],
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
                'relative_path': 'drafts/chapter_01.md',
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
        expect(result.changedPaths, contains('drafts/chapter_01.md'));
        expect(result.writtenPaths, contains('drafts/chapter_01.md'));
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
  });
}

class _FakeToolExecutionPort implements ToolExecutionPort {
  _FakeToolExecutionPort({required Map<String, JsonMap> resultByToolName})
    : _resultByToolName = resultByToolName;

  final Map<String, JsonMap> _resultByToolName;
  JsonMap lastCallArguments = const <String, Object?>{};

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    // 中文注释: 测试替身按工具名返回预设结果，帮助聚焦轮执行服务的聚合逻辑。
    lastCallArguments = ValueReaders.mapValue(toolCall['arguments']);
    return _resultByToolName[toolCall['name']] ??
        <String, Object?>{'ok': true, 'changed_paths': const <Object?>[]};
  }
}
