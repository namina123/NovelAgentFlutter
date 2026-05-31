import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_member_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_primary_agent_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_request_agent_resolver_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'AESP-07 probe verifies the current agent skill chain stays aligned',
    () async {
      final repoRoot = _resolveRepoRoot();
      final recorder = _ProbeRecorder();
      final harness = await _SkillProbeHarness.create();

      try {
        await recorder.capture(
          'request_agent_resolution_uses_selected_agent',
          () {
            final resolver = ConversationRequestAgentResolverService();
            final resolution = resolver.resolve(
              openingProjection: OpeningSessionProjection(
                projectTypeId: 'novel',
                currentGroupId: 'main_room',
                currentGroupDisplayName: '主协作组',
                groupSummaries: const <OpeningAgentGroupSummary>[
                  OpeningAgentGroupSummary(
                    groupId: 'main_room',
                    displayName: '主协作组',
                    description: '主工作组',
                    isSupported: true,
                    isDegraded: false,
                    isCurrent: true,
                    isStarterGroup: true,
                  ),
                ],
                orchestration: OpeningOrchestrationResult(
                  state: OpeningSessionState(
                    projectTypeId: 'novel',
                    status:
                        OpeningSessionState.statusReadyForInteractiveSession,
                    intent: const OpeningIntentSnapshot(
                      resolvedAgentGroupId: 'main_room',
                      availableAgentGroupIds: <String>['main_room'],
                      sessionGoalModeId:
                          SessionRecordConstants.modeContinueWriting,
                    ),
                    stageRecords: const <OpeningStageRecord>[],
                    createdAt: '2026-05-29T00:00:00.000',
                    updatedAt: '2026-05-29T00:00:00.000',
                  ),
                  readiness: const OpeningReadinessAssessment(
                    canStartLongTask: false,
                    canStartInteractiveSession: true,
                    missingRequirements: <OpeningMissingRequirement>[],
                  ),
                  suggestedActions: const <OpeningSuggestedAction>[],
                ),
                availableAgentSummaries: const <OpeningAgentMemberSummary>[
                  OpeningAgentMemberSummary(
                    agentId: 'writer',
                    displayName: '正文智能体',
                    role: '正文',
                    description: '负责正文推进。',
                    thinkingSupported: true,
                    isPrimary: true,
                  ),
                  OpeningAgentMemberSummary(
                    agentId: 'reviewer',
                    displayName: '审阅智能体',
                    role: '审阅',
                    description: '负责审阅与修订建议。',
                    thinkingSupported: true,
                    isPrimary: false,
                  ),
                ],
                currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
                  agentId: 'writer',
                  displayName: '正文智能体',
                  role: '正文',
                  thinkingSupported: true,
                ),
              ),
              preferredAgentId: 'reviewer',
              fallbackSelector: const ConversationAgentSelectorViewData(
                currentAgentLabel: '后备智能体',
                currentAgentId: 'fallback',
                currentAgentDescription: 'fallback',
                agentOptions: <SelectorOptionViewData>[],
                canSwitchAgent: false,
              ),
            );
            _ensure(resolution.agentId == 'reviewer', '会话请求解析没有命中当前选中的智能体。');
            return <String, Object?>{
              'agent_id': resolution.agentId,
              'agent_name': ValueReaders.stringValue(resolution.agent['name']),
            };
          },
        );

        await recorder.capture(
          'runtime_loadout_selection_stays_agent_scoped',
          () async {
            await harness.loadoutRepository.saveLoadouts(
              harness.project,
              const <AgentSkillLoadout>[
                AgentSkillLoadout(
                  agentId: 'writer',
                  source: AgentSkillLoadoutSource.projectSelection,
                  extraSkillIds: <String>['writer_only_skill'],
                ),
                AgentSkillLoadout(
                  agentId: 'reviewer',
                  source: AgentSkillLoadoutSource.projectSelection,
                  extraSkillIds: <String>['review_only_skill'],
                ),
              ],
            );
            final resolved = await harness.runtimeLoadoutService
                .resolveForAgent(
                  project: harness.project,
                  agent: harness.reviewerAgent,
                  availableSkillIds: const <String>[
                    'writer_only_skill',
                    'review_only_skill',
                  ],
                );
            _ensure(
              _sameStringList(resolved.finalSkillIds, const <String>[
                'review_only_skill',
              ]),
              'runtime loadout 命中了错误 agent 的技能。',
            );
            return <String, Object?>{
              'resolved_agent_id': resolved.agentId,
              'resolved_source': resolved.source.id,
              'final_skill_ids': resolved.finalSkillIds,
            };
          },
        );

        await recorder.capture(
          'executor_preview_and_enforcement_stay_consistent',
          () async {
            await harness.loadoutRepository.saveLoadouts(
              harness.project,
              const <AgentSkillLoadout>[
                AgentSkillLoadout(
                  agentId: 'reviewer',
                  source: AgentSkillLoadoutSource.projectSelection,
                  extraSkillIds: <String>['review_only_skill'],
                ),
              ],
            );
            final preview = await harness.executor.loadAgentSkill(
              harness.project,
              <String, Object?>{'_agent': harness.reviewerAgent},
            );
            final availableSkills = ValueReaders.objectList(
              preview['available_skills'],
            ).map(ValueReaders.mapValue).toList(growable: false);
            final allowedIds = availableSkills
                .map((item) => ValueReaders.stringValue(item['id']).trim())
                .where((id) => id.isNotEmpty)
                .toList(growable: false);
            final fullRead = await harness.executor.loadAgentSkill(
              harness.project,
              <String, Object?>{
                '_agent': harness.reviewerAgent,
                'skill_id': 'review_only_skill',
              },
            );
            final blockedRead = await harness.executor.loadAgentSkill(
              harness.project,
              <String, Object?>{
                '_agent': harness.reviewerAgent,
                'skill_id': 'writer_only_skill',
              },
            );
            _ensure(
              _sameStringList(allowedIds, const <String>['review_only_skill']),
              'preview 返回的 available_skills 与 reviewer 预期不一致。',
            );
            _ensure(
              ValueReaders.boolValue(fullRead['ok']),
              'preview 允许的技能在实际读取时没有通过。',
            );
            _ensure(
              ValueReaders.boolValue(blockedRead['not_executed']),
              'preview 未开放的技能在实际读取时没有被拦下。',
            );
            return <String, Object?>{
              'available_skills': allowedIds,
              'allowed_skill_ok': ValueReaders.boolValue(fullRead['ok']),
              'blocked_skill_error': ValueReaders.stringValue(
                blockedRead['error'],
              ),
            };
          },
        );

        await recorder.capture(
          'main_tool_execution_path_injects_agent_context',
          () async {
            harness.recordingPort.reset();
            final service = ToolExecutionService(
              toolExecutionPort: harness.recordingPort,
            );
            final round = await service.executeRound(
              project: harness.project,
              assistantMessage: const <String, Object?>{
                'role': 'assistant',
                'content': '',
              },
              toolCalls: const <Object?>[
                <String, Object?>{
                  'id': 'call_1',
                  'name': 'load_agent_skill',
                  'arguments': <String, Object?>{
                    'skill_id': 'review_only_skill',
                  },
                },
              ],
              agent: harness.reviewerAgent,
            );
            final recordedArguments =
                harness.recordingPort.recordedCalls.single.arguments;
            final injectedAgent = ValueReaders.mapValue(
              recordedArguments['_agent'],
            );
            final executedTool = ValueReaders.mapValue(
              round.executedTools.single,
            );
            final result = ValueReaders.mapValue(executedTool['result']);
            _ensure(
              ValueReaders.stringValue(injectedAgent['id']) == 'reviewer',
              '主执行链没有把当前 agent 注入 load_agent_skill。',
            );
            _ensure(
              ValueReaders.boolValue(result['ok']),
              '主执行链在注入 agent 后仍未成功读取技能。',
            );
            return <String, Object?>{
              'recorded_agent_id': ValueReaders.stringValue(
                injectedAgent['id'],
              ),
              'result_ok': ValueReaders.boolValue(result['ok']),
              'result_skill_id': ValueReaders.stringValue(result['skill_id']),
            };
          },
        );

        await recorder.capture(
          'sub_agent_execution_path_preserves_agent_context',
          () async {
            harness.recordingPort.reset();
            final gateway = _SequencedLlmGateway(<JsonMap>[
              <String, Object?>{
                'ok': true,
                'tool_calls': <Object?>[
                  <String, Object?>{
                    'id': 'call_1',
                    'name': 'load_agent_skill',
                    'arguments': <String, Object?>{
                      'skill_id': 'review_only_skill',
                    },
                  },
                ],
              },
              <String, Object?>{
                'ok': true,
                'content': '结束',
                'tool_calls': const <Object?>[],
              },
            ]);
            final subAgentService = SubAgentExecutionService(
              llmGateway: gateway,
              toolExecutionPort: harness.recordingPort,
              loadAvailableAgents: (_) async => <JsonMap>[
                harness.reviewerAgent,
              ],
              loadAvailableGroups: (_) async => <JsonMap>[
                <String, Object?>{
                  'id': 'optional_review_room',
                  'name': '审稿室',
                  'agents': <String>['reviewer'],
                },
              ],
            );
            final result = await subAgentService.execute(
              project: harness.project,
              parentAgent: harness.writerAgent,
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
            final recordedCall = harness.recordingPort.recordedCalls.single;
            final executedTools = ValueReaders.mapList(result['tool_calls']);
            final firstTool = executedTools.isEmpty
                ? const <String, Object?>{}
                : ValueReaders.mapValue(executedTools.first);
            final toolResult = ValueReaders.mapValue(firstTool['result']);
            final forwardedAgent = ValueReaders.mapValue(
              recordedCall.arguments['_agent'],
            );
            _ensure(
              ValueReaders.stringValue(result['agent_id']) == 'reviewer',
              '子智能体运行包没有选到 reviewer，probe 失真。',
            );
            _ensure(
              ValueReaders.stringValue(forwardedAgent['id']) == 'reviewer',
              '子智能体链没有把当前 reviewer 注入到 load_agent_skill。',
            );
            _ensure(
              ValueReaders.boolValue(toolResult['ok']),
              '子智能体链注入当前 agent 后仍未成功读取 reviewer 技能。',
            );
            return <String, Object?>{
              'selected_child_agent_id': ValueReaders.stringValue(
                result['agent_id'],
              ),
              'forwarded_arguments': recordedCall.arguments,
              'tool_result_ok': ValueReaders.boolValue(toolResult['ok']),
              'tool_result_skill_id': ValueReaders.stringValue(
                toolResult['skill_id'],
              ),
              'inference':
                  '子智能体执行链现在会把 reviewer 注入到 load_agent_skill，available_skills 与实际可读技能保持一致。',
            };
          },
        );

        final reportPath = await _writeReport(
          repoRoot,
          recorder,
          conclusions: <String, Object?>{
            'wrong_agent_loadout_selected': <String, Object?>{
              'confirmed': false,
              'evidence_step': 'runtime_loadout_selection_stays_agent_scoped',
            },
            'session_hint_pollution_after_agent_switch': <String, Object?>{
              'confirmed': false,
              'status': 'not_proven_in_this_probe',
              'note':
                  '这轮没有复现会话内切换 agent 后由 SkillLoadMemory 造成的污染；现有更强证据指向子智能体工具链丢失 _agent 上下文。',
            },
            'available_skills_preview_mismatch': <String, Object?>{
              'confirmed': false,
              'evidence_step':
                  'executor_preview_and_enforcement_stay_consistent',
            },
            'app_projection_runtime_projection_mismatch': <String, Object?>{
              'confirmed': false,
              'evidence_steps': <String>[
                'request_agent_resolution_uses_selected_agent',
                'main_tool_execution_path_injects_agent_context',
                'sub_agent_execution_path_preserves_agent_context',
              ],
            },
            'sub_agent_skill_context_alignment': <String, Object?>{
              'confirmed': true,
              'evidence_step':
                  'sub_agent_execution_path_preserves_agent_context',
              'summary':
                  '子智能体执行链执行 load_agent_skill 时会显式携带当前子智能体上下文，reviewer 只能读取 reviewer 可见技能，available_skills 与实际执行保持一致。',
            },
          },
        );
        if (recorder.failedCount > 0) {
          fail('AESP-06 probe failed. report: $reportPath');
        }
      } finally {
        await harness.dispose();
      }
    },
  );
}

class _SkillProbeHarness {
  _SkillProbeHarness({
    required this.tempRoot,
    required this.workspaceRoot,
    required this.project,
    required this.loadoutRepository,
    required this.runtimeLoadoutService,
    required this.executor,
    required this.recordingPort,
  });

  final Directory tempRoot;
  final Directory workspaceRoot;
  final ProjectDescriptor project;
  final ProjectAgentSkillLoadoutRepository loadoutRepository;
  final ProjectAgentSkillRuntimeLoadoutService runtimeLoadoutService;
  final ProjectAgentSkillToolExecutor executor;
  final _RecordingExecutorToolPort recordingPort;

  JsonMap get reviewerAgent => const <String, Object?>{
    'id': 'reviewer',
    'name': '审阅智能体',
    'role': '负责审阅与修订建议。',
    'skills': <String>['review_only_skill'],
  };

  JsonMap get writerAgent => const <String, Object?>{
    'id': 'writer',
    'name': '正文智能体',
    'role': '负责正文推进。',
    'skills': <String>['writer_only_skill'],
  };

  static Future<_SkillProbeHarness> create() async {
    final tempRoot = await Directory.systemTemp.createTemp(
      'aesp06_skill_probe_',
    );
    final workspaceRoot = Directory(
      '${tempRoot.path}${Platform.pathSeparator}workspace',
    )..createSync(recursive: true);
    final projectRoot = Directory(
      '${tempRoot.path}${Platform.pathSeparator}project',
    )..createSync(recursive: true);

    _writeSkillPackage(
      workspaceRoot.path,
      skillId: 'review_only_skill',
      name: 'review-only-skill',
      description: '只给审阅智能体使用的技能。',
    );
    _writeSkillPackage(
      workspaceRoot.path,
      skillId: 'writer_only_skill',
      name: 'writer-only-skill',
      description: '只给正文智能体使用的技能。',
    );

    final project = ProjectDescriptor(
      id: 'probe_project',
      name: 'AESP-06 Probe Project',
      rootPath: projectRoot.path,
      projectType: 'novel',
    );
    final loadoutRepository = ProjectAgentSkillLoadoutRepository(
      workspacePort: LocalProjectWorkspacePort(),
    );
    final runtimeLoadoutService = ProjectAgentSkillRuntimeLoadoutService(
      loadoutRepository: loadoutRepository,
    );
    final executor = ProjectAgentSkillToolExecutor(
      skillPackageCatalog: LocalSkillPackageCatalog(
        packageRootPathResolver: PackageRootPathResolver(
          workspaceRootPath: workspaceRoot.path,
        ),
      ),
      runtimeLoadoutService: runtimeLoadoutService,
    );
    final recordingPort = _RecordingExecutorToolPort(executor: executor);
    return _SkillProbeHarness(
      tempRoot: tempRoot,
      workspaceRoot: workspaceRoot,
      project: project,
      loadoutRepository: loadoutRepository,
      runtimeLoadoutService: runtimeLoadoutService,
      executor: executor,
      recordingPort: recordingPort,
    );
  }

  Future<void> dispose() async {
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  }
}

class _RecordedToolCall {
  const _RecordedToolCall({required this.name, required this.arguments});

  final String name;
  final JsonMap arguments;
}

class _RecordingExecutorToolPort implements ToolExecutionPort {
  _RecordingExecutorToolPort({required ProjectAgentSkillToolExecutor executor})
    : _executor = executor;

  final ProjectAgentSkillToolExecutor _executor;
  final List<_RecordedToolCall> recordedCalls = <_RecordedToolCall>[];

  void reset() => recordedCalls.clear();

  @override
  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required JsonMap toolCall,
  }) async {
    final name = ValueReaders.stringValue(toolCall['name']);
    final arguments = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(toolCall['arguments']),
    );
    recordedCalls.add(_RecordedToolCall(name: name, arguments: arguments));
    if (name == 'load_agent_skill') {
      return _executor.loadAgentSkill(project, arguments);
    }
    return <String, Object?>{'ok': true, 'changed_paths': const <Object?>[]};
  }
}

class _SequencedLlmGateway implements LlmGateway {
  _SequencedLlmGateway(this._responses);

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

void _writeSkillPackage(
  String workspaceRootPath, {
  required String skillId,
  required String name,
  required String description,
}) {
  final dir = Directory(
    '$workspaceRootPath${Platform.pathSeparator}builtin_packages${Platform.pathSeparator}skills${Platform.pathSeparator}$skillId',
  )..createSync(recursive: true);
  File('${dir.path}${Platform.pathSeparator}SKILL.md').writeAsStringSync('''---
id: $skillId
name: $name
description: $description
---

# $name

$description
''');
}

Future<String> _writeReport(
  String repoRoot,
  _ProbeRecorder recorder, {
  required Map<String, Object?> conclusions,
}) async {
  final reportPath =
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}workbench_agent_skill_probe_report.json';
  final file = File(reportPath);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'created_at': DateTime.now().toIso8601String(),
      'passed': recorder.passedCount,
      'failed': recorder.failedCount,
      'steps': recorder.steps,
      'conclusions': conclusions,
    }),
  );
  return reportPath;
}

String _resolveRepoRoot() {
  var current = Directory.current.absolute;
  for (var depth = 0; depth < 6; depth += 1) {
    final docsFile = File(
      '${current.path}${Platform.pathSeparator}docs${Platform.pathSeparator}workbench-agent-entry-skill-probe-session-order-2026-05-29.md',
    );
    if (docsFile.existsSync()) {
      return current.path;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      break;
    }
    current = parent;
  }
  return Directory.current.absolute.path;
}

void _ensure(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

bool _sameStringList(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

class _ProbeRecorder {
  final List<JsonMap> steps = <JsonMap>[];

  int get passedCount =>
      steps.where((step) => ValueReaders.boolValue(step['ok'])).length;

  int get failedCount =>
      steps.where((step) => !ValueReaders.boolValue(step['ok'])).length;

  Future<void> capture(
    String name,
    FutureOr<Map<String, Object?>> Function() action,
  ) async {
    final startedAt = DateTime.now();
    try {
      final detail = await action();
      steps.add(<String, Object?>{
        'name': name,
        'ok': true,
        'detail': detail,
        'started_at': startedAt.toIso8601String(),
        'finished_at': DateTime.now().toIso8601String(),
      });
    } catch (error, stackTrace) {
      steps.add(<String, Object?>{
        'name': name,
        'ok': false,
        'detail': '$error',
        'stack_trace': '$stackTrace',
        'started_at': startedAt.toIso8601String(),
        'finished_at': DateTime.now().toIso8601String(),
      });
    }
  }
}
