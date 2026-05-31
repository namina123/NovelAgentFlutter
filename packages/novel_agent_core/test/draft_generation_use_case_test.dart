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
      expect(gateway.lastToolNames, isNot(contains('request_gateway_tool')));
    });

    test(
      'generate draft honors planned sections and injected memory sections',
      () async {
        // 中文注释: 这里验证显式执行计划与模式长期约束会真正进入共享生成链，而不是只停留在准备记录里。
        final workspacePort = _FakeProjectWorkspacePort(
          entries: [
            <String, Object?>{
              'relative_path': 'outline/总纲.md',
              'is_dir': false,
            },
          ],
          files: const {'outline/总纲.md': '# 总纲\n第一卷回京。'},
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
          userPrompt: '继续写第一章',
          modelId: 'test-model',
          memorySections: const <Object?>[
            <String, Object?>{
              'id': 'mode_style_1',
              'title': '风格锚点',
              'priority': 97,
              'content': '保持干净利落，每章必须有钩子。',
            },
          ],
          projectFileSectionPlan: const <Object?>[
            <String, Object?>{
              'id': 'planned_outline',
              'title': '任务指定来源',
              'source': 'source_paths',
              'priority': 88,
              'paths': <Object?>['outline/总纲.md'],
            },
          ],
          projectFileContents: const <String, Object?>{
            'outline/总纲.md': '# 总纲\n第一卷回京。',
          },
        );

        expect(gateway.lastPrompt, contains('风格锚点'));
        expect(gateway.lastPrompt, contains('每章必须有钩子'));
        expect(gateway.lastPrompt, contains('第一卷回京'));
        expect(result.selectedPaths, contains('outline/总纲.md'));
      },
    );

    test(
      'generate draft injects expression constraint sections for creative turns',
      () async {
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
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

        await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '继续写这一章。',
          modelId: 'test-model',
          expressionConstraintProfiles: const <Object?>[
            <String, Object?>{
              'id': 'de_ai',
              'display_name': '去 AI 风',
              'summary': '降低模板化表达和解释腔。',
              'kind': 'natural_expression',
              'rules': <Object?>['减少工整排比和空心总结。'],
            },
          ],
          projectExpressionConstraintBindings: const <Object?>[
            <String, Object?>{
              'profile_id': 'de_ai',
              'default_for_project': true,
            },
          ],
        );

        expect(gateway.lastPrompt, contains('表达限制规范'));
        expect(gateway.lastPrompt, contains('减少工整排比和空心总结'));
      },
    );

    test('save draft writes into chapters directory by default', () async {
      // 中文注释: 这里验证草稿保存用例会复用 core 的正式章节目录规则，不会回落到旧 drafts 语义。
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

      expect(savedPath, startsWith('chapters/'));
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
              'relative_path': 'chapters/chapter_01.md',
              'changed_paths': <Object?>['chapters/chapter_01.md'],
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

        expect(
          result.executedTools
              .map(ValueReaders.mapValue)
              .map((tool) => ValueReaders.stringValue(tool['name'])),
          contains('write_project_file'),
        );
        expect(result.writtenPaths, contains('chapters/chapter_01.md'));
        expect(result.draftMarkdown, contains('草稿已经写入项目'));
        expect(
          toolExecutionPort.executedToolNames,
          contains('write_project_file'),
        );
      },
    );

    test(
      'generate draft preloads routed skills before model response',
      () async {
        // 中文注释: 这里验证长任务阶段会先按策略读取技能摘要，而不是完全等模型自己想起来。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '已按策略继续生成。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已按策略继续生成。',
              },
            },
          ],
        );
        final toolExecutionPort = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'load_agent_skill': <String, Object?>{
              'ok': true,
              'skill_id': 'chapter_drafting_method',
              'detail_level': 'summary',
              'content': '章节起草摘要',
              'changed_paths': const <Object?>[],
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
            projectType: 'novel',
          ),
          userPrompt: '请继续当前章节写作。',
          modelId: 'test-model',
          intent: 'workflow_task',
          skillRoutingContext: const <String, Object?>{
            'task_type': 'chapter',
            'mode': 'seed_to_full_novel',
          },
        );

        expect(toolExecutionPort.executedToolNames.first, 'load_agent_skill');
        expect(gateway.lastPrompt, contains('请继续当前章节写作'));
        expect(
          result.executedTools
              .map(ValueReaders.mapValue)
              .map((tool) => ValueReaders.stringValue(tool['name'])),
          contains('load_agent_skill'),
        );
      },
    );

    test('generate draft forwards streaming progress snapshots', () async {
      // 中文注释: 这里验证 core 用例会把网关流式增量和阶段进度继续往上冒，供 GUI/CLI 共用。
      final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
      final gateway = _FakeLlmGateway(
        scriptedResults: [
          <String, Object?>{
            'ok': true,
            'content': '最终正文',
            'reasoning_content': '最终思考',
            'tool_calls': const <Object?>[],
            'message': const <String, Object?>{
              'role': 'assistant',
              'content': '最终正文',
            },
          },
        ],
      );
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
      final progressEvents = <DraftGenerationProgress>[];

      await useCase.execute(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
        ),
        userPrompt: '继续写',
        modelId: 'test-model',
        onProgress: progressEvents.add,
      );

      expect(progressEvents, isNotEmpty);
      expect(progressEvents.first.draftMarkdown, isNotEmpty);
      expect(
        progressEvents.map((event) => event.phase),
        contains('llm_completed'),
      );
    });

    test(
      'generate draft returns cancelled result after cooperative stop',
      () async {
        // 中文注释: 这里验证合作式取消不会伪装成异常，而是返回正式 cancelled result。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final cancellationToken = DraftGenerationCancellationToken();
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '最终正文',
              'reasoning_content': '最终思考',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '最终正文',
              },
            },
          ],
          beforeReturningResult: (onStreamUpdate) {
            onStreamUpdate?.call(
              const LlmStreamUpdate(
                content: '流式正文片段',
                reasoningContent: '流式思考',
              ),
            );
            cancellationToken.cancel();
          },
        );
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
        final progressEvents = <DraftGenerationProgress>[];

        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '继续写',
          modelId: 'test-model',
          cancellationToken: cancellationToken,
          onProgress: progressEvents.add,
        );

        expect(result.cancelledByUser, isTrue);
        expect(result.stopPhase, DraftGenerationStopPhase.llmRound);
        expect(result.partialContentAccepted, isTrue);
        expect(result.draftMarkdown, '流式正文片段');
        expect(progressEvents.last.phase, 'cancelled');
        expect(progressEvents.last.cancelledByUser, isTrue);
      },
    );

    test('generate draft can cancel before first llm round', () async {
      // 中文注释: 这里验证在真正请求模型前的取消会被 core 接住，并返回空的正式取消结果。
      final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
      final cancellationToken = DraftGenerationCancellationToken()..cancel();
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
        userPrompt: '继续写',
        modelId: 'test-model',
        cancellationToken: cancellationToken,
      );

      expect(result.cancelledByUser, isTrue);
      expect(result.stopPhase, DraftGenerationStopPhase.preparingContext);
      expect(result.partialContentAccepted, isFalse);
      expect(gateway.lastModelId, isEmpty);
    });

    test(
      'generate draft failure still throws instead of becoming cancelled',
      () async {
        // 中文注释: 这里验证失败与取消继续分流，合作式取消合同不会吞掉真实异常。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(errorToThrow: StateError('boom'));
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

        await expectLater(
          useCase.execute(
            project: const ProjectDescriptor(
              id: 'demo',
              name: '示例项目',
              rootPath: 'D:/demo',
            ),
            userPrompt: '继续写',
            modelId: 'test-model',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'generate draft forwards active document path into tool fallback context',
      () async {
        // 中文注释: 这里验证空 relative_path 的读取工具能拿到当前打开文件路径，不再因为宿主漏传上下文而空转。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_read_1',
                  'name': 'read_project_file',
                  'arguments': <String, Object?>{},
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content': '已读取当前文档。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已读取当前文档。',
              },
            },
          ],
        );
        final toolExecutionPort = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'read_project_file': <String, Object?>{
              'ok': true,
              'relative_path': 'specs/project_brief.md',
              'content': '# 项目简介',
              'changed_paths': const <Object?>[],
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

        await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '继续',
          modelId: 'test-model',
          activeDocumentPath: 'specs/project_brief.md',
          activeDocumentBody: '# 项目简介',
        );

        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              toolExecutionPort.lastToolCall['arguments'],
            )['relative_path'],
          ),
          'specs/project_brief.md',
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

class _FakeLlmGateway extends LlmGateway {
  _FakeLlmGateway({
    List<JsonMap> scriptedResults = const <JsonMap>[],
    this.beforeReturningResult,
    this.errorToThrow,
  }) : _scriptedResults = List<JsonMap>.from(scriptedResults);

  String lastPrompt = '';
  String lastModelId = '';
  JsonMap lastOptions = const <String, Object?>{};
  List<String> lastToolNames = const <String>[];
  final List<JsonMap> _scriptedResults;
  final void Function(void Function(LlmStreamUpdate update)? onStreamUpdate)?
  beforeReturningResult;
  final Object? errorToThrow;

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async {
    // 中文注释: 旧接口也保持可用，便于其他轻量测试继续直接复用这个替身。
    final result = await requestChat(
      request: ChatRequest.textPrompt(prompt: prompt, modelId: modelId),
    );
    return result['content']?.toString() ?? '';
  }

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    // 中文注释: 模型网关替身记录本轮用户提示，验证用例是否把上下文正确送入模型层。
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    final promptMessage = request.messages.lastWhere(
      (message) => message['role'] == 'user',
      orElse: () => const <String, Object?>{'content': ''},
    );
    lastPrompt = promptMessage['content']?.toString() ?? '';
    lastModelId = request.modelId;
    lastOptions = ValueReaders.deepCopyMap(request.options);
    lastToolNames = request.tools
        .map(ValueReaders.mapValue)
        .map(
          (tool) => ValueReaders.stringValue(
            ValueReaders.mapValue(tool['function'])['name'],
          ),
        )
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
    if (_scriptedResults.isNotEmpty) {
      if (beforeReturningResult != null) {
        beforeReturningResult!(onStreamUpdate);
      } else if (onStreamUpdate != null) {
        onStreamUpdate(
          const LlmStreamUpdate(content: '流式正文', reasoningContent: '流式思考'),
        );
      }
      return _scriptedResults.removeAt(0);
    }
    onStreamUpdate?.call(
      const LlmStreamUpdate(
        content: '# 模型返回的草稿\n\n这是一个测试草稿。',
        reasoningContent: '先读取上下文，再给出结果。',
        isCompleted: true,
      ),
    );
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
  JsonMap lastToolCall = const <String, Object?>{};

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    // 中文注释: 测试替身记录执行过的工具名，方便断言工具循环是否真实发生。
    final toolName = toolCall['name']?.toString() ?? '';
    executedToolNames.add(toolName);
    lastToolCall = ValueReaders.deepCopyMap(toolCall);
    return _resultByToolName[toolName] ??
        <String, Object?>{'ok': true, 'changed_paths': const <Object?>[]};
  }
}
