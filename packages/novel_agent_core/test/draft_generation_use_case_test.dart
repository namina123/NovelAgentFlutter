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

    test(
      'generate draft sends prior conversation as real history messages',
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
          sessionPromptContext: const SessionPromptContext(
            contextMarkdown: '【压缩归档】\n- 已确认主角说话克制。',
            historyMessages: <JsonMap>[
              <String, Object?>{'role': 'user', 'content': '主角这一章要继续保持沉默寡言。'},
              <String, Object?>{
                'role': 'assistant',
                'content': '收到，我会沿用克制冷静的说话方式。',
              },
            ],
          ),
        );

        expect(
          gateway.lastMessages
              .take(3)
              .map((message) => ValueReaders.stringValue(message['role']))
              .toList(growable: false),
          <String>['system', 'user', 'assistant'],
        );
        expect(
          ValueReaders.stringValue(gateway.lastMessages[1]['content']),
          contains('主角这一章要继续保持沉默寡言'),
        );
        expect(
          ValueReaders.stringValue(gateway.lastMessages[2]['content']),
          contains('沿用克制冷静的说话方式'),
        );
        expect(
          ValueReaders.stringValue(gateway.lastMessages.last['role']),
          'user',
        );
        expect(gateway.lastPrompt, contains('【压缩归档】'));
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
      'generate draft continues after read-only tool round if the next reply is empty',
      () async {
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
                  'arguments': <String, Object?>{
                    'relative_path': 'knowledge/项目知识摘要.md',
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
              'content': '',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            <String, Object?>{
              'ok': true,
              'content':
                  '借用的原作事实包括哈利住在楼梯下储物间、海格会在十一岁生日节点出现。新增偏移是主角与哈利更早建立友谊。下面给出开局方案与试写片段。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content':
                    '借用的原作事实包括哈利住在楼梯下储物间、海格会在十一岁生日节点出现。新增偏移是主角与哈利更早建立友谊。下面给出开局方案与试写片段。',
              },
            },
          ],
        );
        final toolExecutionPort = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'read_project_file': <String, Object?>{
              'ok': true,
              'relative_path': 'knowledge/项目知识摘要.md',
              'content': '# 项目知识摘要\n哈利住在楼梯下储物间；海格会在十一岁生日到来。',
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
          ),
          userPrompt: '请说明借用哪些原作事实、哪些地方会产生剧情偏移，并给出开局方案和试写。',
          modelId: 'test-model',
          intent: 'draft',
        );

        expect(result.draftMarkdown, contains('借用的原作事实'));
        expect(gateway.requestCount, 3);
        expect(gateway.promptHistory.last, contains('直接给出本轮实质结果'));
        expect(
          toolExecutionPort.executedToolNames,
          contains('read_project_file'),
        );
      },
    );

    test(
      'generate draft forces present_user_options for option selection turns',
      () async {
        // 中文注释: 这里 mock“让用户先选方向”的真实入口，验证请求级约束会把模型压到选项工具而不是普通正文列表。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_option_1',
                  'name': 'present_user_options',
                  'arguments': <String, Object?>{
                    'question': '你想先走哪个方向？',
                    'options': <Object?>[
                      <String, Object?>{'label': '都市悬疑', 'value': 'urban'},
                      <String, Object?>{'label': '仙侠成长', 'value': 'xianxia'},
                      <String, Object?>{'label': '校园群像', 'value': 'school'},
                    ],
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
          ],
        );
        final toolExecutionPort = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'present_user_options': <String, Object?>{
              'ok': true,
              'waiting_for_user_choice': true,
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
          toolStrategyService: _ForceOptionToolStrategyService(),
        );

        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '先给我三个开局方向让我选，不要直接写正文。',
          modelId: 'test-model',
          intent: 'user_options',
        );

        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                gateway.lastOptions['tool_choice'],
              )['function'],
            )['name'],
          ),
          'present_user_options',
        );
        expect(gateway.lastSystemPrompt, contains('必须调用 present_user_options'));
        expect(result.waitingForUserChoice, isTrue);
        expect(
          result.executedTools
              .map(ValueReaders.mapValue)
              .map((tool) => ValueReaders.stringValue(tool['name'])),
          contains('present_user_options'),
        );
      },
    );

    test(
      'generate draft keeps ordinary chapter writing turns on chapter delivery contract instead of option forcing',
      () async {
        // 中文注释: 这里 mock“正式写章节”的轮次，验证它拿到的是章节交付合同，而不是被误压到选项工具或退回低层写入提示。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_write_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/chapter_01.md',
                    'chapter_content': '# 第一章\n\n正文',
                    'title': '第一章 开场',
                    'submission': <String, Object?>{
                      'submission_id': 'delivery-1',
                      'chapter_ref': <String, Object?>{
                        'ref_type': 'chapter',
                        'ref_id': 'chapters/chapter_01.md',
                        'relative_path': 'chapters/chapter_01.md',
                      },
                    },
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
              'content': '章节已保存。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '章节已保存。',
              },
            },
          ],
        );
        final toolExecutionPort = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'submit_chapter_delivery': <String, Object?>{
              'ok': true,
              'changed_paths': <Object?>[
                'chapters/chapter_01.md',
                '.novel_agent/continuity/deliveries/delivery-1.json',
              ],
              'domain_outcome_status': 'accepted',
              'domain_outcome': <String, Object?>{
                'outcome_status': 'accepted',
                'outcome_payload': <String, Object?>{
                  'delivery_id': 'delivery-1',
                  'chapter_path': 'chapters/chapter_01.md',
                  'delivery_state': 'delivered',
                  'chapter_body_state': 'delivered',
                  'sidecar_state': 'accepted',
                  'state_result': <String, Object?>{
                    'chapter_body_delivered': true,
                    'submission_accepted': true,
                  },
                },
              },
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
          userPrompt: '直接写第一章，约两千字。',
          modelId: 'test-model',
          title: '第一章 开场',
          intent: 'draft',
        );

        expect(gateway.lastOptions.containsKey('tool_choice'), isFalse);
        expect(
          gateway.lastSystemPrompt,
          contains('完成后应优先调用 submit_chapter_delivery'),
        );
        expect(
          gateway.lastSystemPrompt,
          contains('不要只靠 write_project_file 冒充正式章节交付'),
        );
        expect(gateway.lastSystemPrompt, contains('propose_design_element'));
        expect(
          gateway.lastSystemPrompt,
          contains('外部资料、网页摘录、检索结论和来源说明不能直接冒充长期设定'),
        );
        expect(
          gateway.lastSystemPrompt,
          contains('knowledge/、research/、references/ 下的信息摘要是只读 projection 入口'),
        );
        expect(gateway.lastSystemPrompt, isNot(contains('知识库写入 knowledge/')));
        expect(
          result.executedTools
              .map(ValueReaders.mapValue)
              .map((tool) => ValueReaders.stringValue(tool['name'])),
          contains('submit_chapter_delivery'),
        );
        expect(
          result.changedPaths,
          contains('.novel_agent/continuity/deliveries/delivery-1.json'),
        );
        expect(
          toolExecutionPort.executedToolNames,
          contains('submit_chapter_delivery'),
        );
      },
    );

    test(
      'generate draft keeps formal chapter delivery primary even when research tools stay exposed',
      () async {
        // 中文注释: 研究工具可以继续暴露，但普通分章如果已足够写作，模型仍应直接完成正式交付。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/chapter_01.md',
                    'chapter_content': '# 第一章\n\n正文',
                    'title': '第一章',
                    'submission': <String, Object?>{
                      'submission_id': 'delivery-1',
                      'chapter_ref': <String, Object?>{
                        'ref_type': 'chapter',
                        'ref_id': 'chapters/chapter_01.md',
                        'relative_path': 'chapters/chapter_01.md',
                      },
                    },
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
              'content': '章节已交付。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '章节已交付。',
              },
            },
          ],
        );
        final toolExecutionPort = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'request_external_research': <String, Object?>{
              'ok': true,
              'changed_paths': <Object?>[
                '.novel_agent/information/research_requests/request-1.json',
                'research/资料研究摘要.md',
              ],
            },
            'submit_chapter_delivery': <String, Object?>{
              'ok': true,
              'changed_paths': <Object?>[
                'chapters/chapter_01.md',
                '.novel_agent/continuity/deliveries/delivery-1.json',
              ],
              'domain_outcome_status': 'accepted',
              'domain_outcome': <String, Object?>{
                'outcome_status': 'accepted',
                'outcome_payload': <String, Object?>{
                  'delivery_id': 'delivery-1',
                  'chapter_path': 'chapters/chapter_01.md',
                  'delivery_state': 'delivered',
                  'chapter_body_state': 'delivered',
                  'sidecar_state': 'accepted',
                  'state_result': <String, Object?>{
                    'chapter_body_delivered': true,
                    'submission_accepted': true,
                  },
                },
              },
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
          userPrompt: '请写第一章，涉及真实历史背景时先收集资料。',
          modelId: 'test-model',
          title: '第一章',
          exposedToolIds: const <String>[
            'submit_chapter_delivery',
            'request_external_research',
            'submit_research_note',
            'read_project_file',
          ],
        );

        expect(gateway.requestCount, 2);
        expect(
          gateway.toolNameHistory.first,
          contains('submit_chapter_delivery'),
        );
        expect(
          gateway.promptHistory,
          contains(contains('submit_chapter_delivery')),
        );
        expect(
          toolExecutionPort.executedToolNames,
          orderedEquals(const <String>['submit_chapter_delivery']),
        );
        expect(result.changedPaths, contains('chapters/chapter_01.md'));
        expect(result.draftMarkdown, contains('章节已交付'));
      },
    );

    test(
      'generate draft recovers formal delivery after mergeable sub-agent failure',
      () async {
        // 中文注释: 子智能体空返/失败是协作信号，主智能体仍必须回到正式章节交付合同。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_sub_1',
                  'name': 'call_sub_agent',
                  'arguments': <String, Object?>{
                    'agent_id': 'reviewer',
                    'task': '请先审稿，再返回结构化建议。',
                  },
                },
              ],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
            },
            const <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[],
            },
            const <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[],
            },
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/chapter_01.md',
                    'chapter_content': '# 第一章\n\n正文',
                    'title': '第一章',
                    'submission': <String, Object?>{
                      'submission_id': 'delivery-1',
                      'chapter_ref': <String, Object?>{
                        'ref_type': 'chapter',
                        'ref_id': 'chapters/chapter_01.md',
                        'relative_path': 'chapters/chapter_01.md',
                      },
                    },
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
              'content': '已由主智能体兜底完成章节交付。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已由主智能体兜底完成章节交付。',
              },
            },
          ],
        );
        final toolExecutionPort = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'submit_chapter_delivery': <String, Object?>{
              'ok': true,
              'changed_paths': <Object?>[
                'chapters/chapter_01.md',
                '.novel_agent/continuity/deliveries/delivery-1.json',
              ],
              'domain_outcome_status': 'accepted',
              'domain_outcome': <String, Object?>{
                'outcome_status': 'accepted',
                'outcome_payload': <String, Object?>{
                  'delivery_id': 'delivery-1',
                  'chapter_path': 'chapters/chapter_01.md',
                  'delivery_state': 'delivered',
                  'chapter_body_state': 'delivered',
                  'sidecar_state': 'accepted',
                  'state_result': <String, Object?>{
                    'chapter_body_delivered': true,
                    'submission_accepted': true,
                  },
                },
              },
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
          loadAvailableAgents: (_) async => <JsonMap>[
            const <String, Object?>{
              'id': 'reviewer',
              'name': '审稿智能体',
              'role': '负责审稿',
            },
          ],
          loadAvailableAgentGroups: (_) async => <JsonMap>[
            const <String, Object?>{
              'id': 'optional_review_room',
              'name': '审稿组',
              'agents': <String>['reviewer'],
            },
          ],
        );

        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '请写第一章，可先让审稿智能体检查，但最终必须交付正文。',
          modelId: 'test-model',
          title: '第一章',
          exposedToolIds: const <String>[
            'submit_chapter_delivery',
            'call_sub_agent',
            'read_project_file',
          ],
        );

        final toolNames = result.executedTools
            .map(ValueReaders.mapValue)
            .map((tool) => ValueReaders.stringValue(tool['name']))
            .toList(growable: false);
        final subAgentTool = result.executedTools
            .map(ValueReaders.mapValue)
            .firstWhere(
              (tool) =>
                  ValueReaders.stringValue(tool['name']) == 'call_sub_agent',
            );
        final subAgentResult = ValueReaders.mapValue(subAgentTool['result']);
        expect(ValueReaders.boolValue(subAgentResult['ok']), isFalse);
        expect(
          ValueReaders.stringValue(subAgentResult['failure_disposition']),
          ChildFailureDispositions.retryChild,
        );
        expect(result.stoppedByToolError, isFalse);
        expect(
          toolNames,
          containsAll(<String>['call_sub_agent', 'submit_chapter_delivery']),
        );
        expect(gateway.promptHistory, contains(contains('子智能体')));
        expect(
          gateway.toolNameHistory.any(
            (names) =>
                names.length == 1 && names.single == 'submit_chapter_delivery',
          ),
          isTrue,
        );
        expect(result.changedPaths, contains('chapters/chapter_01.md'));
        expect(result.draftMarkdown, contains('兜底完成章节交付'));
      },
    );

    test(
      'generate draft retries failed submit_chapter_delivery in restricted recovery round',
      () async {
        // 中文注释: 分章正文首轮交付被 continuity/length gate 拦下时，核心必须给出只允许正式交付的纠偏回合。
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_invalid_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/chapter_03.md',
                    'chapter_content': '# 第三章\n\n王保正刚把话说完，门外的人又把同一句话重复了一遍。',
                    'title': '第三章',
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
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_retry_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/chapter_03.md',
                    'chapter_content':
                        '# 第三章\n\n王保正的话音一落，门外的人没有再重复上一句，而是直接接过话头迈进屋里。',
                    'title': '第三章',
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
              'content': '章节已交付。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '章节已交付。',
              },
            },
          ],
        );
        final toolExecutionPort = _FakeToolExecutionPort(
          queuedResultsByToolName: <String, List<JsonMap>>{
            'submit_chapter_delivery': <JsonMap>[
              <String, Object?>{
                'ok': false,
                'error': '章节开篇疑似回退重演上一章末尾已完成动作，没有直接承接下一章入口。',
                'domain_outcome_status': 'invalid_payload',
                'domain_outcome': <String, Object?>{
                  'outcome_status': 'invalid_payload',
                  'outcome_payload': <String, Object?>{
                    'chapter_path': 'chapters/chapter_03.md',
                    'delivery_state': 'delivered',
                    'chapter_body_state': 'delivered',
                    'sidecar_state': 'missing',
                    'state_result': <String, Object?>{
                      'chapter_body_delivered': true,
                      'submission_accepted': false,
                    },
                  },
                },
              },
              <String, Object?>{
                'ok': true,
                'changed_paths': <Object?>[
                  'chapters/chapter_03.md',
                  '.novel_agent/continuity/deliveries/delivery-3.json',
                ],
                'domain_outcome_status': 'accepted',
                'domain_outcome': <String, Object?>{
                  'outcome_status': 'accepted',
                  'outcome_payload': <String, Object?>{
                    'delivery_id': 'delivery-3',
                    'chapter_path': 'chapters/chapter_03.md',
                    'delivery_state': 'delivered',
                    'chapter_body_state': 'delivered',
                    'sidecar_state': 'accepted',
                    'state_result': <String, Object?>{
                      'chapter_body_delivered': true,
                      'submission_accepted': true,
                    },
                  },
                },
              },
            ],
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
          userPrompt: '直接续写第三章。',
          modelId: 'test-model',
          title: '第三章',
          exposedToolIds: const <String>[
            NarrativeDomainToolNames.submitChapterDelivery,
            'read_project_file',
            'request_external_research',
          ],
          modelProfile: const <String, Object?>{'supports_tool_choice': true},
        );

        expect(toolExecutionPort.executedToolNames, <String>[
          'submit_chapter_delivery',
          'submit_chapter_delivery',
        ]);
        expect(
          gateway.toolNameHistory[1],
          orderedEquals(const <String>['submit_chapter_delivery']),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(
                gateway.optionsHistory[1]['tool_choice'],
              )['function'],
            )['name'],
          ),
          NarrativeDomainToolNames.submitChapterDelivery,
        );
        expect(result.stoppedByToolError, isFalse);
        expect(result.toolErrorSummary, isEmpty);
        expect(result.changedPaths, contains('chapters/chapter_03.md'));
        expect(result.draftMarkdown, contains('章节已交付'));
      },
    );

    test(
      'generate draft keeps read-only context tools available while chapter flow still avoids unnecessary research calls',
      () async {
        // 中文注释: 章节主链可以先读上下文再交付，但没必要时不应额外触发研究工具。
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
                  'arguments': <String, Object?>{
                    'relative_path': 'research/待研究问题.md',
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
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/chapter_01.md',
                    'chapter_content': '# 第一章\n\n正文',
                    'title': '第一章',
                    'submission': <String, Object?>{
                      'submission_id': 'delivery-1',
                      'chapter_ref': <String, Object?>{
                        'ref_type': 'chapter',
                        'ref_id': 'chapters/chapter_01.md',
                        'relative_path': 'chapters/chapter_01.md',
                      },
                    },
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
              'content': '章节已交付。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '章节已交付。',
              },
            },
          ],
        );
        final toolExecutionPort = _FakeToolExecutionPort(
          resultByToolName: <String, JsonMap>{
            'read_project_file': <String, Object?>{
              'ok': true,
              'content': '本章需要确认明代家内称谓。',
              'changed_paths': const <Object?>[],
            },
            'submit_chapter_delivery': <String, Object?>{
              'ok': true,
              'changed_paths': <Object?>[
                'chapters/chapter_01.md',
                '.novel_agent/continuity/deliveries/delivery-1.json',
              ],
              'domain_outcome_status': 'accepted',
              'domain_outcome': <String, Object?>{
                'outcome_status': 'accepted',
                'outcome_payload': <String, Object?>{
                  'delivery_id': 'delivery-1',
                  'chapter_path': 'chapters/chapter_01.md',
                  'delivery_state': 'delivered',
                  'chapter_body_state': 'delivered',
                  'sidecar_state': 'accepted',
                  'state_result': <String, Object?>{
                    'chapter_body_delivered': true,
                    'submission_accepted': true,
                  },
                },
              },
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
          userPrompt: '请写第一章，必须先确认一个真实历史称谓。',
          modelId: 'test-model',
          title: '第一章',
          exposedToolIds: const <String>[
            'submit_chapter_delivery',
            'request_external_research',
            'submit_research_note',
            'read_project_file',
          ],
        );

        expect(
          toolExecutionPort.executedToolNames,
          containsAllInOrder(<String>[
            'read_project_file',
            'submit_chapter_delivery',
          ]),
        );
        expect(
          toolExecutionPort.executedToolNames,
          isNot(contains('request_external_research')),
        );
        expect(
          gateway.toolNameHistory[1],
          containsAll(<String>['read_project_file', 'submit_chapter_delivery']),
        );
        expect(result.draftMarkdown, contains('章节已交付'));
        expect(result.changedPaths, contains('chapters/chapter_01.md'));
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

    test(
      'generate draft respects explicit tool exposure and skips skill preload when load_agent_skill is not exposed',
      () async {
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: [
            <String, Object?>{
              'ok': true,
              'content': '直接进入正文。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '直接进入正文。',
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
          userPrompt: '请直接写正文，不要再读技能。',
          modelId: 'test-model',
          intent: 'workflow_task',
          skillRoutingContext: const <String, Object?>{
            'task_type': 'chapter',
            'mode': 'seed_to_full_novel',
          },
          exposedToolIds: const <String>[
            NarrativeDomainToolNames.submitChapterDelivery,
          ],
        );

        expect(
          toolExecutionPort.executedToolNames,
          isNot(contains('load_agent_skill')),
        );
        expect(
          result.executedTools
              .map(ValueReaders.mapValue)
              .map((tool) => ValueReaders.stringValue(tool['name'])),
          isNot(contains('load_agent_skill')),
        );
        expect(result.draftMarkdown, contains('直接进入正文'));
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

    test(
      'generate draft prefers the selected collaboration group for child run packages',
      () async {
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '',
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_sub_1',
                  'name': 'call_sub_agent',
                  'arguments': <String, Object?>{
                    'agent_id': 'reviewer',
                    'task': '请先审稿，再返回结构化建议。',
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
              'content': '建议先强化第一段冲突。',
              'tool_calls': const <Object?>[],
            },
            <String, Object?>{
              'ok': true,
              'content': '已收到审稿建议。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已收到审稿建议。',
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
          loadAvailableAgents: (_) async => <JsonMap>[
            const <String, Object?>{
              'id': 'writer',
              'name': '正文智能体',
              'role': '负责主写',
            },
            const <String, Object?>{
              'id': 'reviewer',
              'name': '审稿智能体',
              'role': '负责审稿',
            },
          ],
          loadAvailableAgentGroups: (_) async => <JsonMap>[
            const <String, Object?>{
              'id': 'optional_review_room',
              'name': '审稿组',
              'agents': <String>['reviewer'],
            },
            const <String, Object?>{
              'id': 'starter_story_room',
              'name': '正文协作组',
              'agents': <String>['writer', 'reviewer'],
              'primary_agent_id': 'writer',
            },
          ],
        );

        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '继续写',
          modelId: 'test-model',
          agent: const <String, Object?>{
            'id': 'writer',
            'name': '正文智能体',
            'role': '负责主写',
          },
          selectedCollaborationGroup: const <String, Object?>{
            'id': 'starter_story_room',
            'name': '正文协作组',
            'agents': <String>['writer', 'reviewer'],
            'primary_agent_id': 'writer',
          },
        );

        final subAgentTool = result.executedTools
            .map(ValueReaders.mapValue)
            .firstWhere(
              (tool) =>
                  ValueReaders.stringValue(tool['name']) == 'call_sub_agent',
            );
        final subAgentResult = ValueReaders.mapValue(subAgentTool['result']);
        expect(
          ValueReaders.stringValue(subAgentResult['group_id']),
          'starter_story_room',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              subAgentResult['child_run_package'],
            )['group_id'],
          ),
          'starter_story_room',
        );
      },
    );

    test(
      'generate draft derives a single-member collaboration group when no groups are available',
      () async {
        final workspacePort = _FakeProjectWorkspacePort(entries: [], files: {});
        final gateway = _FakeLlmGateway(
          scriptedResults: <JsonMap>[
            <String, Object?>{
              'ok': true,
              'content': '已按单主智能体直接完成本轮处理。',
              'tool_calls': const <Object?>[],
              'message': const <String, Object?>{
                'role': 'assistant',
                'content': '已按单主智能体直接完成本轮处理。',
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
          loadAvailableAgents: (_) async => <JsonMap>[
            const <String, Object?>{
              'id': 'writer',
              'name': '正文智能体',
              'role': '负责主写',
            },
          ],
          loadAvailableAgentGroups: (_) async => const <JsonMap>[],
        );

        final result = await useCase.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
          ),
          userPrompt: '继续写',
          modelId: 'test-model',
          agent: const <String, Object?>{
            'id': 'writer',
            'name': '正文智能体',
            'role': '负责主写',
          },
        );

        expect(gateway.lastToolNames, isNot(contains('call_sub_agent')));
        expect(gateway.lastSystemPrompt, contains('当前按单主智能体运行'));
        expect(
          gateway.lastSystemPrompt,
          isNot(contains('调用 call_sub_agent 时必须传 agent_id 和 task')),
        );
        expect(
          result.executedTools
              .map(ValueReaders.mapValue)
              .where(
                (tool) =>
                    ValueReaders.stringValue(tool['name']) == 'call_sub_agent',
              ),
          isEmpty,
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
  String lastSystemPrompt = '';
  String lastModelId = '';
  JsonMap lastOptions = const <String, Object?>{};
  List<JsonMap> lastMessages = const <JsonMap>[];
  List<String> lastToolNames = const <String>[];
  int requestCount = 0;
  final List<String> promptHistory = <String>[];
  final List<List<String>> toolNameHistory = <List<String>>[];
  final List<JsonMap> optionsHistory = <JsonMap>[];
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
    requestCount += 1;
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    final promptMessage = request.messages.lastWhere(
      (message) => message['role'] == 'user',
      orElse: () => const <String, Object?>{'content': ''},
    );
    final systemMessage = request.messages.firstWhere(
      (message) => message['role'] == 'system',
      orElse: () => const <String, Object?>{'content': ''},
    );
    lastPrompt = promptMessage['content']?.toString() ?? '';
    lastSystemPrompt = systemMessage['content']?.toString() ?? '';
    lastModelId = request.modelId;
    lastOptions = ValueReaders.deepCopyMap(request.options);
    lastMessages = request.messages
        .map(ValueReaders.deepCopyMap)
        .toList(growable: false);
    optionsHistory.add(lastOptions);
    promptHistory.add(lastPrompt);
    lastToolNames = request.tools
        .map(ValueReaders.mapValue)
        .map(
          (tool) => ValueReaders.stringValue(
            ValueReaders.mapValue(tool['function'])['name'],
          ),
        )
        .where((name) => name.trim().isNotEmpty)
        .toList(growable: false);
    toolNameHistory.add(lastToolNames);
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

class _ForceOptionToolStrategyService extends ToolStrategyService {
  @override
  JsonMap defaultSettings() {
    return super.defaultSettings()
      ..['force_tool_choice'] = true
      ..['auto_present_options'] = true;
  }
}

class _FakeToolExecutionPort implements ToolExecutionPort {
  _FakeToolExecutionPort({
    Map<String, JsonMap> resultByToolName = const <String, JsonMap>{},
    Map<String, List<JsonMap>> queuedResultsByToolName =
        const <String, List<JsonMap>>{},
  }) : _resultByToolName = resultByToolName,
       _queuedResultsByToolName = queuedResultsByToolName.map(
         (key, value) => MapEntry(key, List<JsonMap>.from(value)),
       );

  final Map<String, JsonMap> _resultByToolName;
  final Map<String, List<JsonMap>> _queuedResultsByToolName;
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
    final queuedResults = _queuedResultsByToolName[toolName];
    if (queuedResults != null && queuedResults.isNotEmpty) {
      return queuedResults.removeAt(0);
    }
    return _resultByToolName[toolName] ??
        <String, Object?>{'ok': true, 'changed_paths': const <Object?>[]};
  }
}
