import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Draft generation use cases', () {
    test('generate draft assembles context and invokes gateway', () async {
      // 中文注释: 这里验证新的共享草稿生成入口会读取项目文件、组装上下文并调用模型网关。
      final workspacePort = _FakeProjectWorkspacePort(
        entries: [
          <String, Object?>{
            'relative_path': 'specs/project.md',
            'is_dir': false,
          },
          <String, Object?>{
            'relative_path': 'styles/main_style.md',
            'is_dir': false,
          },
        ],
        files: const {
          'specs/project.md': '# 项目规格\n主角不能太早知道真相。',
          'styles/main_style.md': '# 风格\n保持冷静克制。',
        },
      );
      final gateway = _FakeLlmGateway();
      final useCase = GenerateDraftUseCase(
        projectWorkspacePort: workspacePort,
        llmGateway: gateway,
        toolExecutionPort: _FakeToolExecutionPort(),
        contextAssemblerService: ContextAssemblerService(
          budgetService: ContextBudgetService(),
          staticSectionService: ContextStaticSectionService(
            projectPromptContract: ProjectPromptContract(),
          ),
          projectFileSectionService: ContextProjectFileSectionService(),
        ),
        projectPromptContract: ProjectPromptContract(),
      );

      final result = await useCase.execute(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        userPrompt: '写第一章开场',
        modelId: 'test-model',
        title: '第一章 开场',
        requestOptions: const <String, Object?>{
          'temperature': 0.55,
          'stream': false,
        },
      );

      expect(result.draftMarkdown, contains('模型返回的草稿'));
      expect(result.selectedPaths, contains('specs/project.md'));
      expect(gateway.lastModelId, 'test-model');
      expect(gateway.lastPrompt, contains('保持冷静克制'));
      expect(gateway.lastOptions['temperature'], 0.55);
      expect(gateway.lastOptions['stream'], isFalse);
    });

    test('save draft writes into drafts directory by default', () async {
      // 中文注释: 这里验证草稿保存用例会复用 core 路径规则，而不是让宿主层自己拼接 drafts 路径。
      final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
      final useCase = SaveDraftUseCase(
        projectWorkspacePort: workspacePort,
        draftFilePathService: DraftFilePathService(),
      );

      final savedPath = await useCase.execute(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        content: '# 草稿\n内容',
        title: '第一章 开场',
      );

      expect(savedPath, startsWith('drafts/'));
      expect(workspacePort.writtenFiles[savedPath], '# 草稿\n内容');
    });

    test(
      'generate draft executes tool calls and keeps written paths',
      () async {
        // 中文注释: 这里验证共享生成入口会执行模型返回的 tool_call，并把写入路径回收给上层。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_1',
                  'name': 'write_project_file',
                  'arguments': <String, Object?>{
                    'content_type': 'draft',
                    'title': '第一章 开场',
                    'content': '# 第一章\n\n正文',
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '草稿已经写入项目。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '草稿已经写入项目。',
              },
            },
          ],
        );
        final toolExecutionPort = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'write_project_file': <String, Object?>{
              'ok': true,
              'relative_path': 'drafts/chapter_01.md',
              'changed_paths': <Object?>['drafts/chapter_01.md'],
            },
          },
        );
        final useCase = GenerateDraftUseCase(
          projectWorkspacePort: workspacePort,
          llmGateway: gateway,
          toolExecutionPort: toolExecutionPort,
          contextAssemblerService: ContextAssemblerService(
            budgetService: ContextBudgetService(),
            staticSectionService: ContextStaticSectionService(
              projectPromptContract: ProjectPromptContract(),
            ),
            projectFileSectionService: ContextProjectFileSectionService(),
          ),
          projectPromptContract: ProjectPromptContract(),
        );

        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '写第一章开场',
          modelId: 'test-model',
          title: '第一章 开场',
        );

        expect(result.executedTools, hasLength(1));
        expect(result.writtenPaths, contains('drafts/chapter_01.md'));
        expect(result.draftMarkdown, contains('草稿已经写入项目'));
        expect(
          toolExecutionPort.executedToolNames,
          contains('write_project_file'),
        );
      },
    );
  });
}

class _FakeProjectWorkspacePort implements ProjectWorkspacePort {
  _FakeProjectWorkspacePort({
    required List<JsonMap> entries,
    required Map<String, String> files,
  }) : _entries = entries,
       _files = files;

  final List<JsonMap> _entries;
  final Map<String, String> _files;
  final Map<String, String> writtenFiles = <String, String>{};

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async {
    // 中文注释: 测试替身直接返回预置目录快照，用来验证 core 选择和组装逻辑。
    return _entries;
  }

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async {
    // 中文注释: 测试替身只从内存字典读取文本，避免把文件系统变量带进单元测试。
    return _files[relativePath];
  }

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {
    // 中文注释: 目录创建在这个测试替身里不影响断言，因此保持空实现即可。
  }

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {
    // 中文注释: 写入结果记录到内存，供断言保存路径与内容是否符合预期。
    writtenFiles[relativePath] = content;
  }
}

class _FakeLlmGateway implements LlmGateway {
  _FakeLlmGateway({List<JsonMap> scriptedResults = const <JsonMap>[]})
    : _scriptedResults = List<JsonMap>.from(scriptedResults);

  String lastPrompt = '';
  String lastModelId = '';
  JsonMap lastOptions = const <String, Object?>{};
  final List<JsonMap> _scriptedResults;

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async {
    // 中文注释: 旧接口也保持可用，便于其他轻量测试继续直接复用这个替身。
    final result = await requestChat(
      messages: const <JsonMap>[],
      modelId: modelId,
      options: <String, Object?>{'prompt': prompt},
    );
    return result['content']?.toString() ?? '';
  }

  @override
  Future<JsonMap> requestChat({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
  }) async {
    // 中文注释: 模型网关替身记录本轮用户提示，验证用例是否把上下文正确送入模型层。
    final promptMessage = messages.lastWhere(
      (message) => message['role'] == 'user',
      orElse: () => <String, Object?>{'content': options['prompt'] ?? ''},
    );
    lastPrompt = promptMessage['content']?.toString() ?? '';
    lastModelId = modelId;
    lastOptions = ValueReaders.deepCopyMap(options);
    if (_scriptedResults.isNotEmpty) {
      return _scriptedResults.removeAt(0);
    }
    return <String, Object?>{
      'ok': true,
      'content': '# 模型返回的草稿\n\n这是一个测试草稿。',
      'tool_calls': const <Object?>[],
      'message': const <String, Object?>{
        'role': 'assistant',
        'content': '# 模型返回的草稿\n\n这是一个测试草稿。',
      },
    };
  }
}

class _FakeToolExecutionPort implements ToolExecutionPort {
  _FakeToolExecutionPort({
    Map<String, JsonMap> resultByToolName = const <String, JsonMap>{},
  }) : _resultByToolName = resultByToolName;

  final Map<String, JsonMap> _resultByToolName;
  final List<String> executedToolNames = <String>[];

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    // 中文注释: 测试替身记录执行过的工具名，方便断言工具循环是否真实发生。
    final toolName = toolCall['name']?.toString() ?? '';
    executedToolNames.add(toolName);
    return _resultByToolName[toolName] ??
        <String, Object?>{'ok': true, 'changed_paths': const <Object?>[]};
  }
}
