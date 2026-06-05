import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SubAgentExecutionService', () {
    test('injects selected child agent into load_agent_skill calls', () async {
      final port = _RecordingToolExecutionPort();
      final service = SubAgentExecutionService(
        llmGateway: _SequencedGateway(<JsonMap>[
          <String, Object?>{
            'ok': true,
            'tool_calls': <Object?>[
              <String, Object?>{
                'id': 'call_1',
                'name': 'load_agent_skill',
                'arguments': <String, Object?>{'skill_id': 'review_only_skill'},
              },
            ],
          },
          <String, Object?>{
            'ok': true,
            'content': 'done',
            'tool_calls': const <Object?>[],
          },
        ]),
        toolExecutionPort: port,
        loadAvailableAgents: (_) async => <JsonMap>[
          _writerAgent,
          _reviewerAgent,
        ],
        loadAvailableGroups: (_) async => <JsonMap>[
          <String, Object?>{
            'id': 'optional_review_room',
            'name': '审稿室',
            'agents': <String>['reviewer'],
          },
        ],
      );

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
          projectType: 'novel',
        ),
        parentAgent: _writerAgent,
        toolCall: const <String, Object?>{
          'name': 'call_sub_agent',
          'arguments': <String, Object?>{
            'agent_id': 'reviewer',
            'task': '请审稿，并读取相关技能。',
          },
        },
        modelId: 'probe-model',
        mainContext: const <String, Object?>{
          'intent': 'draft',
          'sub_agent_max_tool_rounds': 1,
        },
      );

      expect(result['agent_id'], 'reviewer');
      expect(port.recordedCalls, hasLength(1));
      expect(port.recordedCalls.single.name, 'load_agent_skill');
      expect(port.recordedCalls.single.agentId, 'reviewer');
      final toolCalls = ValueReaders.mapList(result['tool_calls']);
      final executedTool = ValueReaders.mapValue(toolCalls.single);
      expect(
        ValueReaders.boolValue(
          ValueReaders.mapValue(executedTool['result'])['ok'],
        ),
        isTrue,
      );
    });

    test(
      'keeps sub-agent skill scope aligned with the injected child agent',
      () async {
        final port = _RecordingToolExecutionPort();
        final service = SubAgentExecutionService(
          llmGateway: _SequencedGateway(<JsonMap>[
            <String, Object?>{
              'ok': true,
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_1',
                  'name': 'load_agent_skill',
                  'arguments': <String, Object?>{
                    'skill_id': 'writer_only_skill',
                  },
                },
              ],
            },
            <String, Object?>{
              'ok': true,
              'content': 'done',
              'tool_calls': const <Object?>[],
            },
          ]),
          toolExecutionPort: port,
          loadAvailableAgents: (_) async => <JsonMap>[
            _writerAgent,
            _reviewerAgent,
          ],
          loadAvailableGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'optional_review_room',
              'name': '审稿室',
              'agents': <String>['reviewer'],
            },
          ],
        );

        final result = await service.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
            projectType: 'novel',
          ),
          parentAgent: _writerAgent,
          toolCall: const <String, Object?>{
            'name': 'call_sub_agent',
            'arguments': <String, Object?>{
              'agent_id': 'reviewer',
              'task': '请审稿，并读取相关技能。',
            },
          },
          modelId: 'probe-model',
          mainContext: const <String, Object?>{
            'intent': 'draft',
            'sub_agent_max_tool_rounds': 1,
          },
        );

        expect(port.recordedCalls.single.agentId, 'reviewer');
        final toolCalls = ValueReaders.mapList(result['tool_calls']);
        final executedTool = ValueReaders.mapValue(toolCalls.single);
        final toolResult = ValueReaders.mapValue(executedTool['result']);
        expect(ValueReaders.boolValue(toolResult['not_executed']), isTrue);
        expect(
          ValueReaders.stringValue(toolResult['error']),
          contains('当前智能体不可读取该技能'),
        );
      },
    );

    test(
      'blocks formal chapter delivery tool for child agent by default',
      () async {
        final service = SubAgentExecutionService(
          llmGateway: _SequencedGateway(<JsonMap>[
            <String, Object?>{
              'ok': true,
              'tool_calls': <Object?>[
                <String, Object?>{
                  'id': 'call_delivery_1',
                  'name': 'submit_chapter_delivery',
                  'arguments': <String, Object?>{
                    'chapter_path': 'chapters/ch01.md',
                    'chapter_content': '# 第01章\n\n正文。',
                  },
                },
              ],
            },
            <String, Object?>{
              'ok': true,
              'content': '我只能先返回建议，不能直接正式交付。',
              'tool_calls': const <Object?>[],
            },
          ]),
          toolExecutionPort: _RecordingToolExecutionPort(),
          loadAvailableAgents: (_) async => <JsonMap>[
            _writerAgent,
            _reviewerAgent,
          ],
          loadAvailableGroups: (_) async => <JsonMap>[
            <String, Object?>{
              'id': 'optional_review_room',
              'name': '审稿室',
              'agents': <String>['reviewer'],
            },
          ],
        );

        final result = await service.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
            projectType: 'novel',
          ),
          parentAgent: _writerAgent,
          toolCall: const <String, Object?>{
            'name': 'call_sub_agent',
            'arguments': <String, Object?>{
              'agent_id': 'reviewer',
              'task': '请直接提交第一章交付。',
            },
          },
          modelId: 'probe-model',
          mainContext: const <String, Object?>{
            'intent': 'draft',
            'sub_agent_max_tool_rounds': 1,
          },
        );

        final toolCalls = ValueReaders.mapList(result['tool_calls']);
        final executedTool = ValueReaders.mapValue(toolCalls.single);
        final toolResult = ValueReaders.mapValue(executedTool['result']);
        expect(ValueReaders.boolValue(result['ok']), isTrue);
        expect(ValueReaders.boolValue(toolResult['ok']), isFalse);
        expect(
          ValueReaders.stringValue(toolResult['error']),
          contains('Blocked sub-agent tool: submit_chapter_delivery'),
        );
        expect(
          ValueReaders.mapValue(
            result['collaboration_result_package'],
          )['merge_contract'],
          isNotEmpty,
        );
      },
    );

    test(
      'applies child-specific model and tool policies for writer reviewer and researcher',
      () async {
        final writerScenario = await _runPolicyScenario(
          agent: _policyWriterAgent,
          task: '请起草正文片段。',
        );
        final reviewerScenario = await _runPolicyScenario(
          agent: _policyReviewerAgent,
          task: '请审稿。',
        );
        final researcherScenario = await _runPolicyScenario(
          agent: _policyResearcherAgent,
          task: '请补充资料。',
        );

        expect(
          writerScenario.gateway.requests.single.modelId,
          'writer-child-model',
        );
        expect(
          reviewerScenario.gateway.requests.single.modelId,
          'reviewer-child-model',
        );
        expect(
          researcherScenario.gateway.requests.single.modelId,
          'researcher-child-model',
        );
        expect(
          writerScenario.gateway.requests.single.toolNames,
          containsAll(<String>['write_project_file', 'read_project_file']),
        );
        expect(
          writerScenario.gateway.requests.single.toolNames,
          isNot(contains('submit_semantic_review')),
        );
        expect(
          reviewerScenario.gateway.requests.single.toolNames,
          containsAll(<String>['submit_semantic_review', 'read_project_file']),
        );
        expect(
          reviewerScenario.gateway.requests.single.toolNames,
          isNot(contains('write_project_file')),
        );
        expect(
          researcherScenario.gateway.requests.single.toolNames,
          containsAll(<String>[
            'request_external_research',
            'submit_research_note',
          ]),
        );
        expect(
          researcherScenario.gateway.requests.single.toolNames,
          isNot(contains('write_project_file')),
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              writerScenario.result['effective_execution_profile'],
            )['model_id'],
          ),
          'writer-child-model',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              reviewerScenario.result['effective_execution_profile'],
            )['model_id'],
          ),
          'reviewer-child-model',
        );
        expect(
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              researcherScenario.result['effective_execution_profile'],
            )['model_id'],
          ),
          'researcher-child-model',
        );
      },
    );

    test(
      'blocks recursive delegation user questioning and long task start for child agent',
      () async {
        for (final toolName in const <String>[
          'call_sub_agent',
          'present_user_options',
          'start_long_task_run',
        ]) {
          final service = SubAgentExecutionService(
            llmGateway: _SequencedGateway(<JsonMap>[
              <String, Object?>{
                'ok': true,
                'tool_calls': <Object?>[
                  <String, Object?>{
                    'id': 'call_blocked_$toolName',
                    'name': toolName,
                    'arguments': const <String, Object?>{},
                  },
                ],
              },
            ]),
            toolExecutionPort: _RecordingToolExecutionPort(),
            loadAvailableAgents: (_) async => <JsonMap>[_writerAgent],
            loadAvailableGroups: (_) async => <JsonMap>[
              <String, Object?>{
                'id': 'writer_room',
                'name': '作者组',
                'agents': <String>['writer'],
              },
            ],
          );

          final result = await service.execute(
            project: const ProjectDescriptor(
              id: 'demo',
              name: '示例项目',
              rootPath: 'D:/demo',
              projectType: 'long_novel',
            ),
            parentAgent: _writerAgent,
            toolCall: const <String, Object?>{
              'name': 'call_sub_agent',
              'arguments': <String, Object?>{
                'agent_id': 'writer',
                'task': '请继续。',
              },
            },
            modelId: 'probe-model',
            mainContext: const <String, Object?>{
              'intent': 'draft',
              'sub_agent_max_tool_rounds': 1,
            },
          );

          final toolCalls = ValueReaders.mapList(result['tool_calls']);
          final executedTool = ValueReaders.mapValue(toolCalls.single);
          final toolResult = ValueReaders.mapValue(executedTool['result']);
          expect(ValueReaders.boolValue(toolResult['ok']), isFalse);
          expect(
            ValueReaders.stringValue(toolResult['error']),
            contains('Blocked sub-agent tool: $toolName'),
          );
        }
      },
    );

    test('retries child on timeout within retry budget', () async {
      final gateway = _DelayedSequencedGateway(<_DelayedResponse>[
        const _DelayedResponse(
          delay: Duration(seconds: 2),
          response: <String, Object?>{'ok': true, 'content': 'late'},
        ),
        const _DelayedResponse(
          delay: Duration.zero,
          response: <String, Object?>{'ok': true, 'content': 'recovered'},
        ),
      ]);
      final service = SubAgentExecutionService(
        llmGateway: gateway,
        toolExecutionPort: _RecordingToolExecutionPort(),
        loadAvailableAgents: (_) async => <JsonMap>[_writerAgent],
        loadAvailableGroups: (_) async => <JsonMap>[
          const <String, Object?>{
            'id': 'writer_room',
            'name': '作者组',
            'agents': <String>['writer'],
          },
        ],
      );

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
          projectType: 'long_novel',
        ),
        parentAgent: _writerAgent,
        toolCall: const <String, Object?>{
          'name': 'call_sub_agent',
          'arguments': <String, Object?>{'agent_id': 'writer', 'task': '请补充。'},
        },
        modelId: 'probe-model',
        mainContext: const <String, Object?>{
          'intent': 'draft',
          'sub_agent_timeout_seconds': 1,
          'sub_agent_retry_budget': 1,
        },
      );

      expect(ValueReaders.boolValue(result['ok']), isTrue);
      expect(ValueReaders.intValue(result['attempt_count']), 2);
      expect(ValueReaders.stringValue(result['result_markdown']), 'recovered');
      expect(gateway.requests, hasLength(2));
    });

    test('retries child on empty response within retry budget', () async {
      final gateway = _SequencedGateway(<JsonMap>[
        const <String, Object?>{
          'ok': true,
          'content': '',
          'tool_calls': <Object?>[],
        },
        const <String, Object?>{
          'ok': true,
          'content': 'second-pass answer',
          'tool_calls': <Object?>[],
        },
      ]);
      final service = SubAgentExecutionService(
        llmGateway: gateway,
        toolExecutionPort: _RecordingToolExecutionPort(),
        loadAvailableAgents: (_) async => <JsonMap>[_writerAgent],
        loadAvailableGroups: (_) async => <JsonMap>[
          const <String, Object?>{
            'id': 'writer_room',
            'name': '作者组',
            'agents': <String>['writer'],
          },
        ],
      );

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
          projectType: 'long_novel',
        ),
        parentAgent: _writerAgent,
        toolCall: const <String, Object?>{
          'name': 'call_sub_agent',
          'arguments': <String, Object?>{'agent_id': 'writer', 'task': '请补充。'},
        },
        modelId: 'probe-model',
        mainContext: const <String, Object?>{
          'intent': 'draft',
          'sub_agent_retry_budget': 1,
        },
      );

      expect(ValueReaders.boolValue(result['ok']), isTrue);
      expect(ValueReaders.intValue(result['attempt_count']), 2);
      expect(gateway.requests, hasLength(2));
    });

    test('returns skip-child disposition on hard tool error', () async {
      final service = SubAgentExecutionService(
        llmGateway: _SequencedGateway(<JsonMap>[
          <String, Object?>{
            'ok': true,
            'tool_calls': <Object?>[
              <String, Object?>{
                'id': 'call_write_1',
                'name': 'write_project_file',
                'arguments': <String, Object?>{'path': 'chapters/ch01.md'},
              },
            ],
          },
        ]),
        toolExecutionPort: _HardErrorToolExecutionPort(),
        loadAvailableAgents: (_) async => <JsonMap>[_writerAgent],
        loadAvailableGroups: (_) async => <JsonMap>[
          const <String, Object?>{
            'id': 'writer_room',
            'name': '作者组',
            'agents': <String>['writer'],
          },
        ],
      );

      final result = await service.execute(
        project: const ProjectDescriptor(
          id: 'demo',
          name: '示例项目',
          rootPath: 'D:/demo',
          projectType: 'long_novel',
        ),
        parentAgent: _writerAgent,
        toolCall: const <String, Object?>{
          'name': 'call_sub_agent',
          'arguments': <String, Object?>{'agent_id': 'writer', 'task': '请写入。'},
        },
        modelId: 'probe-model',
        mainContext: const <String, Object?>{'intent': 'draft'},
      );

      expect(ValueReaders.boolValue(result['ok']), isFalse);
      expect(
        ValueReaders.stringValue(result['failure_disposition']),
        ChildFailureDispositions.skipChild,
      );
      expect(
        ValueReaders.stringValue(result['failure_category']),
        'tool_error',
      );
    });

    test(
      'degrades to single-main fallback when child token budget is exhausted',
      () async {
        final service = SubAgentExecutionService(
          llmGateway: _SequencedGateway(<JsonMap>[
            const <String, Object?>{
              'ok': true,
              'content': 'token-heavy answer',
              'tool_calls': <Object?>[],
              'usage': <String, Object?>{'total_tokens': 120},
            },
          ]),
          toolExecutionPort: _RecordingToolExecutionPort(),
          loadAvailableAgents: (_) async => <JsonMap>[_writerAgent],
          loadAvailableGroups: (_) async => <JsonMap>[
            const <String, Object?>{
              'id': 'writer_room',
              'name': '作者组',
              'agents': <String>['writer'],
            },
          ],
        );

        final result = await service.execute(
          project: const ProjectDescriptor(
            id: 'demo',
            name: '示例项目',
            rootPath: 'D:/demo',
            projectType: 'long_novel',
          ),
          parentAgent: _writerAgent,
          toolCall: const <String, Object?>{
            'name': 'call_sub_agent',
            'arguments': <String, Object?>{
              'agent_id': 'writer',
              'task': '请补充。',
            },
          },
          modelId: 'probe-model',
          mainContext: const <String, Object?>{
            'intent': 'draft',
            'sub_agent_token_budget': 80,
          },
        );

        expect(ValueReaders.boolValue(result['ok']), isFalse);
        expect(
          ValueReaders.stringValue(result['failure_disposition']),
          ChildFailureDispositions.fallbackSingleMain,
        );
        expect(
          ValueReaders.stringValue(result['failure_category']),
          'budget_exhausted',
        );
      },
    );
  });
}

const JsonMap _writerAgent = <String, Object?>{
  'id': 'writer',
  'name': '正文智能体',
  'skills': <String>['writer_only_skill'],
};

const JsonMap _reviewerAgent = <String, Object?>{
  'id': 'reviewer',
  'name': '审阅智能体',
  'skills': <String>['review_only_skill'],
};

const JsonMap _policyWriterAgent = <String, Object?>{
  'id': 'writer',
  'name': '正文智能体',
  'model_id': 'writer-child-model',
  'temperature': 0.91,
  'tool_policy': <String, Object?>{
    'allowed_tools': <String>[
      'list_project_files',
      'read_project_file',
      'write_project_file',
      'load_agent_skill',
    ],
  },
};

const JsonMap _policyReviewerAgent = <String, Object?>{
  'id': 'reviewer',
  'name': '审稿智能体',
  'model_id': 'reviewer-child-model',
  'temperature': 0.43,
  'tool_policy': <String, Object?>{
    'allowed_tools': <String>[
      'list_project_files',
      'read_project_file',
      'submit_semantic_review',
    ],
  },
};

const JsonMap _policyResearcherAgent = <String, Object?>{
  'id': 'researcher',
  'name': '资料智能体',
  'model_id': 'researcher-child-model',
  'temperature': 0.37,
  'tool_policy': <String, Object?>{
    'allowed_tools': <String>[
      'list_project_files',
      'read_project_file',
      'request_external_research',
      'submit_research_note',
    ],
  },
};

AppSettings _subAgentTestSettings() {
  return const AppSettings(
    defaultProviderId: 'test-provider',
    defaultAgentId: '',
    defaultModelId: 'parent-model',
    defaultProjectPath: '',
    autoSaveDrafts: false,
    providers: <ProviderEndpointSettings>[
      ProviderEndpointSettings(
        id: 'test-provider',
        title: 'Test Provider',
        protocol: 'openai',
        baseUrl: 'https://example.invalid',
        apiKey: 'test-key',
        modelId: 'parent-model',
        description: 'test provider',
      ),
    ],
  );
}

Future<_PolicyScenarioResult> _runPolicyScenario({
  required JsonMap agent,
  required String task,
}) async {
  final gateway = _SequencedGateway(<JsonMap>[
    <String, Object?>{
      'ok': true,
      'content': 'done',
      'tool_calls': const <Object?>[],
    },
  ]);
  final service = SubAgentExecutionService(
    llmGateway: gateway,
    toolExecutionPort: _RecordingToolExecutionPort(),
    loadAvailableAgents: (_) async => <JsonMap>[agent],
    loadAvailableGroups: (_) async => <JsonMap>[
      <String, Object?>{
        'id': ValueReaders.stringValue(agent['id']) == 'reviewer'
            ? 'optional_review_room'
            : 'optional_editorial_room',
        'name': '策略测试组',
        'agents': <String>[ValueReaders.stringValue(agent['id'])],
      },
    ],
  );
  final result = await service.execute(
    project: const ProjectDescriptor(
      id: 'demo',
      name: '示例项目',
      rootPath: 'D:/demo',
      projectType: 'long_novel',
    ),
    parentAgent: _writerAgent,
    toolCall: <String, Object?>{
      'name': 'call_sub_agent',
      'arguments': <String, Object?>{
        'agent_id': ValueReaders.stringValue(agent['id']),
        'task': task,
      },
    },
    modelId: 'parent-model',
    mainContext: <String, Object?>{
      'intent': 'draft',
      'sub_agent_max_tool_rounds': 1,
      'sub_agent_runtime_settings': _subAgentTestSettings(),
    },
  );
  return _PolicyScenarioResult(gateway: gateway, result: result);
}

class _RecordingToolExecutionPort implements ToolExecutionPort {
  final List<_RecordedToolCall> recordedCalls = <_RecordedToolCall>[];

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    final arguments = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(toolCall['arguments']),
    );
    final agent = ValueReaders.mapValue(arguments['_agent']);
    recordedCalls.add(
      _RecordedToolCall(
        name: ValueReaders.stringValue(toolCall['name']),
        agentId: ValueReaders.stringValue(agent['id']),
      ),
    );
    final skillId = ValueReaders.stringValue(arguments['skill_id']);
    final allowedSkillIds = ValueReaders.stringList(agent['skills']);
    if (allowedSkillIds.contains(skillId)) {
      return <String, Object?>{
        'ok': true,
        'skill_id': skillId,
        'available_skills': allowedSkillIds
            .map((id) => <String, Object?>{'id': id})
            .toList(growable: false),
        'changed_paths': const <Object?>[],
      };
    }
    return <String, Object?>{
      'ok': false,
      'not_executed': true,
      'error': '当前智能体不可读取该技能：$skillId',
      'available_skills': allowedSkillIds
          .map((id) => <String, Object?>{'id': id})
          .toList(growable: false),
      'changed_paths': const <Object?>[],
    };
  }
}

class _HardErrorToolExecutionPort implements ToolExecutionPort {
  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    return <String, Object?>{
      'ok': false,
      'error': 'disk write failed',
      'not_executed': false,
    };
  }
}

class _RecordedToolCall {
  const _RecordedToolCall({required this.name, required this.agentId});

  final String name;
  final String agentId;
}

class _SequencedGateway implements LlmGateway {
  _SequencedGateway(this._responses);

  final List<JsonMap> _responses;
  final List<_RecordedLlmRequest> requests = <_RecordedLlmRequest>[];
  int _index = 0;

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    requests.add(
      _RecordedLlmRequest(
        modelId: request.modelId,
        toolNames: request.tools
            .map(
              (schema) => ValueReaders.stringValue(
                ValueReaders.mapValue(schema['function'])['name'],
              ),
            )
            .where((name) => name.trim().isNotEmpty)
            .toList(growable: false),
      ),
    );
    if (_index >= _responses.length) {
      return <String, Object?>{
        'ok': true,
        'content': '',
        'tool_calls': const <Object?>[],
      };
    }
    return ValueReaders.deepCopyMap(_responses[_index++]);
  }

  @override
  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    return requestChat(
      request: ChatRequest.fromLegacy(
        messages: messages,
        modelId: modelId,
        tools: tools,
        options: options,
        attachments: attachments,
      ),
      cancellationToken: cancellationToken,
      onStreamUpdate: onStreamUpdate,
    );
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async {
    final result = await requestChat(
      request: ChatRequest.textPrompt(prompt: prompt, modelId: modelId),
    );
    return ValueReaders.stringValue(result['content']);
  }
}

class _DelayedSequencedGateway implements LlmGateway {
  _DelayedSequencedGateway(this._responses);

  final List<_DelayedResponse> _responses;
  final List<_RecordedLlmRequest> requests = <_RecordedLlmRequest>[];
  int _index = 0;

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
    requests.add(
      _RecordedLlmRequest(
        modelId: request.modelId,
        toolNames: request.tools
            .map(
              (schema) => ValueReaders.stringValue(
                ValueReaders.mapValue(schema['function'])['name'],
              ),
            )
            .where((name) => name.trim().isNotEmpty)
            .toList(growable: false),
      ),
    );
    if (_index >= _responses.length) {
      return <String, Object?>{
        'ok': true,
        'content': '',
        'tool_calls': const <Object?>[],
      };
    }
    final current = _responses[_index++];
    await Future<void>.delayed(current.delay);
    return ValueReaders.deepCopyMap(current.response);
  }

  @override
  Future<JsonMap> requestChatLegacy({
    required List<JsonMap> messages,
    required String modelId,
    List<JsonMap> tools = const <JsonMap>[],
    JsonMap options = const <String, Object?>{},
    List<ChatInputAttachment> attachments = const <ChatInputAttachment>[],
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) {
    return requestChat(
      request: ChatRequest.fromLegacy(
        messages: messages,
        modelId: modelId,
        tools: tools,
        options: options,
        attachments: attachments,
      ),
      cancellationToken: cancellationToken,
      onStreamUpdate: onStreamUpdate,
    );
  }

  @override
  Future<String> requestText({
    required String prompt,
    required String modelId,
  }) async {
    final result = await requestChat(
      request: ChatRequest.textPrompt(prompt: prompt, modelId: modelId),
    );
    return ValueReaders.stringValue(result['content']);
  }
}

class _DelayedResponse {
  const _DelayedResponse({required this.delay, required this.response});

  final Duration delay;
  final JsonMap response;
}

class _RecordedLlmRequest {
  const _RecordedLlmRequest({required this.modelId, required this.toolNames});

  final String modelId;
  final List<String> toolNames;
}

class _PolicyScenarioResult {
  const _PolicyScenarioResult({required this.gateway, required this.result});

  final _SequencedGateway gateway;
  final JsonMap result;
}
