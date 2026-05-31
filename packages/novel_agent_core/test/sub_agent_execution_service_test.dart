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

class _RecordedToolCall {
  const _RecordedToolCall({required this.name, required this.agentId});

  final String name;
  final String agentId;
}

class _SequencedGateway implements LlmGateway {
  _SequencedGateway(this._responses);

  final List<JsonMap> _responses;
  int _index = 0;

  @override
  Future<JsonMap> requestChat({
    required ChatRequest request,
    DraftGenerationCancellationToken? cancellationToken,
    void Function(LlmStreamUpdate update)? onStreamUpdate,
  }) async {
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
