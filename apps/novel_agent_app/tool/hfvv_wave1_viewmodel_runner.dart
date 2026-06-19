import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_app/features/workbench/application/models/conversation_tool_lifecycle_status.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_wave1_viewmodel_support.dart';
import 'hfvv_wave1_user_decision_support.dart';
import 'hfvv_path_leak_support.dart';
import 'probe_support.dart';
import '../../../tools/probe_config_support.dart';

const String _runId = '2026-06-10T01-35-42';

Future<void> main(List<String> arguments) async {
  final summary = await runHfvvWave1();
  stdout.writeln(ValueReaders.boolValue(summary['ok']) ? 'PASS' : 'FAIL');
  if (!ValueReaders.boolValue(summary['ok'])) {
    exitCode = 1;
  }
}

Future<JsonMap> runHfvvWave1({bool requireRealProbeOptIn = true}) async {
  if (requireRealProbeOptIn) {
    await ensureLocalRealProbeOptIn(probeName: 'hfvv_wave1_viewmodel_runner');
  }
  final repoRoot = resolveLocalProbeRepoRoot();
  final apiConfig = await loadProbeApiConfig(
    probeName: 'hfvv_wave1_viewmodel_runner',
    repoRootOverride: repoRoot,
    requireRealProbeOptIn: requireRealProbeOptIn,
  );
  final summary = <String, Object?>{
    'session': 'HFVV-04',
    'run_id': _runId,
    'started_at': DateTime.now().toIso8601String(),
    'provider_source': apiConfig.sourceLabel,
    'model_id': apiConfig.modelId,
    'lanes': <Object?>[],
  };

  try {
    final laneReports = <JsonMap>[
      await _runLaneA(apiConfig),
      await _runLaneB(apiConfig),
      await _runLaneC(apiConfig),
      await _runLaneD(apiConfig),
      await _runLaneE(apiConfig),
    ];
    summary['lanes'] = laneReports;
    summary['ok'] = laneReports.every(
      (lane) => ValueReaders.boolValue(lane['ok']),
    );
  } catch (error, stackTrace) {
    summary['ok'] = false;
    summary['error'] = '$error';
    summary['stack_trace'] = '$stackTrace';
  } finally {
    summary['finished_at'] = DateTime.now().toIso8601String();
    await _writeSummary(repoRoot, summary);
  }
  return summary;
}

Future<JsonMap> _runLaneA(ProbeApiConfig apiConfig) async {
  const laneId = 'lane_a_ordinary_information_before_writing';
  final harness = await HfvvWave1AppShellHarness.create(
    runId: _runId,
    laneId: laneId,
    apiConfig: apiConfig,
  );
  final steps = <String>[];
  final modelDecisions = <JsonMap>[];
  final continuationStrategies = <String>[];
  final continuationReasons = <String>[];
  var stepIndex = 0;

  Future<void> capture(String label) async {
    stepIndex += 1;
    final stepId = _stepId(stepIndex);
    final event = _conversationEvent(harness, phase: label);
    steps.add(stepId);
    modelDecisions.add(event);
    await harness.recordStep(
      stepId: stepId,
      label: label,
      modelEvent: event,
      toolEvents: _toolEvents(harness),
    );
  }

  JsonMap report = <String, Object?>{
    'lane_id': laneId,
    'run_id': _runId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace':
        'artifacts/high_fidelity_viewmodel_validation/$_runId/$laneId/',
    'fixes_applied': const <Object?>[],
    'rerun_count': 0,
  };

  try {
    await capture('initialized');
    await harness.createProject(
      title: 'HFVV-04 Lane A 普通项目信息先行',
      projectTypeId: 'novel',
    );
    await harness.writeProjectManifest();
    await capture('project_created');

    const prompt = '''
我想从零开始做一个普通小说项目，题材是“社畜穿越到明代，想把后世常识慢慢变成可落地的小改良”，整体轻松向，但涉及明代制度、民间工艺、盐铁、农业改良时必须先判断哪些点需要可靠资料。

这一步先别直接写正文，也别假设资料都充分。请先根据当前项目状态判断还缺什么，必要时先做资料整理或给我下一步确认选项。
''';
    await harness.sendPrompt(prompt);
    await harness.waitForConversationActivity();
    await capture('turn_1_active');
    await harness.waitForConversationToSettle();
    await capture('turn_1_settled');

    final laneADecision = decideLaneAResearchFirstStep(
      harness.conversation.pendingOptions,
    );
    continuationStrategies.add(laneADecision.strategy);
    continuationReasons.add(laneADecision.reason);
    if (laneADecision.option != null) {
      await harness.selectPendingOption(laneADecision.option!);
    } else if (laneADecision.followUpPrompt.trim().isNotEmpty) {
      await harness.sendPrompt(laneADecision.followUpPrompt);
    }
    await harness.waitForConversationActivity(
      timeout: const Duration(seconds: 45),
    );
    await capture('turn_2_active');
    await harness.waitForConversationToSettle();
    await capture('turn_2_settled');

    var laneAState = await _loadLaneAValidationState(harness);
    if (!laneAState.hasResearchEvidence &&
        !laneAState.wroteChapterDirectly &&
        laneAState.waitingUser) {
      continuationStrategies.add('send_follow_up_prompt');
      continuationReasons.add('materialize_research_records');
      await harness.sendPrompt(laneAResearchMaterializationFollowUpPrompt);
      await harness.waitForConversationActivity(
        timeout: const Duration(seconds: 45),
      );
      await capture('turn_3_active');
      await harness.waitForConversationToSettle();
      await capture('turn_3_settled');
      laneAState = await _loadLaneAValidationState(harness);
    }

    final hasResearchEvidence = laneAState.hasResearchEvidence;
    final latestAssistant = laneAState.latestAssistant;
    final wroteChapter = laneAState.wroteChapterDirectly;
    final waitingUser = laneAState.waitingUser;
    final projectEntries = laneAState.projectEntries;
    final expressionBindings = await _loadExpressionBindingProfileIds(harness);
    final ok =
        hasResearchEvidence &&
        !wroteChapter &&
        expressionBindings.contains('de_ai');

    report = <String, Object?>{
      ...report,
      'ok': ok,
      'report_category': ok
          ? 'success'
          : _laneCategoryFromSignals(
              waitingUser: waitingUser,
              hasEvidence: hasResearchEvidence,
            ),
      'finished_at': DateTime.now().toIso8601String(),
      'project_manifest': await harness.projectManifest(),
      'viewmodel_steps': steps,
      'model_decisions': modelDecisions,
      'tool_events': _toolEvents(harness),
      'validation': <String, Object?>{
        'has_research_evidence': hasResearchEvidence,
        'wrote_chapter_directly': wroteChapter,
        'waiting_user': waitingUser,
        'continuation_strategies': continuationStrategies,
        'continuation_reasons': continuationReasons,
        'expression_constraint_profile_ids': expressionBindings,
        'latest_assistant_excerpt': _clip(latestAssistant, 700),
      },
      'files_created': projectEntries,
      'failures': ok
          ? const <Object?>[]
          : <Object?>[
              <String, Object?>{
                'category': _laneCategoryFromSignals(
                  waitingUser: waitingUser,
                  hasEvidence: hasResearchEvidence,
                ),
                'summary': '普通项目没有稳定表现出“信息先行再写作”的证据链。',
              },
            ],
    };
  } catch (error, stackTrace) {
    report = _laneExceptionReport(
      base: report,
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    await harness.writeLaneReport(report);
    await harness.writeFixLog(_fixLog(report));
    harness.controller.dispose();
  }
  return report;
}

Future<JsonMap> _runLaneB(ProbeApiConfig apiConfig) async {
  const laneId = 'lane_b_ordinary_multi_agent';
  final harness = await HfvvWave1AppShellHarness.create(
    runId: _runId,
    laneId: laneId,
    apiConfig: apiConfig,
  );
  final steps = <String>[];
  final modelDecisions = <JsonMap>[];
  final continuationStrategies = <String>[];
  var stepIndex = 0;

  Future<void> capture(String label) async {
    stepIndex += 1;
    final stepId = _stepId(stepIndex);
    final event = _conversationEvent(harness, phase: label);
    steps.add(stepId);
    modelDecisions.add(event);
    await harness.recordStep(
      stepId: stepId,
      label: label,
      modelEvent: event,
      toolEvents: _toolEvents(harness),
    );
  }

  JsonMap report = <String, Object?>{
    'lane_id': laneId,
    'run_id': _runId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace':
        'artifacts/high_fidelity_viewmodel_validation/$_runId/$laneId/',
    'fixes_applied': const <Object?>[],
    'rerun_count': 0,
  };

  try {
    await capture('initialized');
    await harness.createProject(
      title: 'HFVV-04 Lane B 多智能体普通写作',
      projectTypeId: 'novel',
    );
    await harness.writeProjectManifest();
    await capture('project_created');

    const prompt = '''
请把这次普通小说开局准备当成一次真实多智能体协作：

1. 让资料考据子智能体先判断有没有需要核查的历史与制度信息。
2. 让角色设定子智能体给出主角、搭档和冲突种子。
3. 让剧情审核子智能体指出可能的节奏或设定漏洞。
4. 最后由主智能体综合成一版中文开局方案，并给出 600-900 字试写。

题材仍然是“现代社畜穿到明代做小改良”，但不要预设章节，不要只给空口号。
''';
    await harness.sendPrompt(prompt);
    await harness.waitForConversationActivity(
      timeout: const Duration(minutes: 2),
    );
    await capture('turn_1_active');
    await harness.waitForConversationToSettle(
      timeout: const Duration(minutes: 10),
    );
    await capture('turn_1_settled');

    if (shouldRequestLaneBActualSubAgents(
      subAgentRuns: harness.conversation.subAgentRuns,
      latestAssistant: _latestAssistantText(
        harness.conversation.conversationEntries,
      ),
    )) {
      continuationStrategies.add('request_actual_sub_agent_runs');
      await harness.sendPrompt(laneBActualSubAgentFollowUpPrompt);
      await harness.waitForConversationActivity(
        timeout: const Duration(minutes: 2),
      );
      await capture('turn_2_active');
      await harness.waitForConversationToSettle(
        timeout: const Duration(minutes: 10),
      );
      await capture('turn_2_settled');
    }

    final subAgentRuns = harness.conversation.subAgentRuns;
    final hasSubAgents = subAgentRuns.isNotEmpty;
    final hasDistinctActivity = subAgentRuns.any(
      (run) => run.toolCount > 0 || run.events.isNotEmpty,
    );
    final latestAssistant = _latestAssistantText(
      harness.conversation.conversationEntries,
    );
    final ok =
        hasSubAgents && hasDistinctActivity && latestAssistant.isNotEmpty;

    report = <String, Object?>{
      ...report,
      'ok': ok,
      'report_category': ok ? 'success' : 'content_quality_failure',
      'finished_at': DateTime.now().toIso8601String(),
      'project_manifest': await harness.projectManifest(),
      'viewmodel_steps': steps,
      'model_decisions': modelDecisions,
      'tool_events': _toolEvents(harness),
      'validation': <String, Object?>{
        'sub_agent_run_count': subAgentRuns.length,
        'continuation_strategies': continuationStrategies,
        'sub_agent_runs': subAgentRuns
            .map(
              (run) => <String, Object?>{
                'id': run.id,
                'agent_name': run.agentName,
                'task': run.task,
                'status': run.status,
                'tool_count': run.toolCount,
                'events': run.events,
              },
            )
            .toList(growable: false),
        'latest_assistant_excerpt': _clip(latestAssistant, 700),
      },
      'files_created': await harness.listProjectEntries(),
      'failures': ok
          ? const <Object?>[]
          : <Object?>[
              <String, Object?>{
                'category': 'content_quality_failure',
                'summary': '普通项目未从 ViewModel 观察到可证明的多智能体运行轨迹。',
              },
            ],
    };
  } catch (error, stackTrace) {
    report = _laneExceptionReport(
      base: report,
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    await harness.writeLaneReport(report);
    await harness.writeFixLog(_fixLog(report));
    harness.controller.dispose();
  }
  return report;
}

Future<JsonMap> _runLaneC(ProbeApiConfig apiConfig) async {
  const laneId = 'lane_c_user_side_knowledge_base';
  final harness = await HfvvWave1AppShellHarness.create(
    runId: _runId,
    laneId: laneId,
    apiConfig: apiConfig,
  );
  final steps = <String>[];
  final modelDecisions = <JsonMap>[];
  var stepIndex = 0;

  Future<void> capture(String label) async {
    stepIndex += 1;
    final stepId = _stepId(stepIndex);
    final event = _conversationEvent(harness, phase: label);
    steps.add(stepId);
    modelDecisions.add(event);
    await harness.recordStep(
      stepId: stepId,
      label: label,
      modelEvent: event,
      toolEvents: _toolEvents(harness),
    );
  }

  JsonMap report = <String, Object?>{
    'lane_id': laneId,
    'run_id': _runId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace':
        'artifacts/high_fidelity_viewmodel_validation/$_runId/$laneId/',
    'fixes_applied': const <Object?>[],
    'rerun_count': 0,
  };

  try {
    await capture('initialized');
    await harness.createProject(
      title: 'HFVV-04 Lane C 用户侧知识库',
      projectTypeId: 'knowledge_base',
    );
    final sourceFile = File(
      '${harness.workspaceRoot.path}${Platform.pathSeparator}user_sources'
      '${Platform.pathSeparator}salt_city_setting_notes.md',
    );
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsString(_laneCUserSourceMarkdown);
    await harness.writeProjectManifest();
    await capture('project_created');

    await harness.controller.projectAssetsController.refresh();
    harness.referenceSourcePickerService.enqueue(sourceFile.path);
    final extraction = harness.controller.projectAssetsController
        .onProjectAssetsExtractReferenceRequested();
    await harness.waitUntil(
      () => harness.controller.projectAssetsController.viewData.isLoading,
      description: 'lane c extraction loading',
      timeout: const Duration(seconds: 20),
    );
    await capture('reference_extraction_active');
    await extraction;
    await harness.waitUntil(
      () => !harness.controller.projectAssetsController.viewData.isLoading,
      description: 'lane c extraction complete',
      timeout: const Duration(minutes: 10),
    );
    await capture('reference_extraction_settled');

    await harness.sendPrompt(
      '只根据当前项目知识库，用中文回答：主角是谁？她隶属什么组织？禁忌是什么？核心冲突是什么？如果知识库没有就明确说不知道。',
    );
    await harness.waitForConversationActivity();
    await capture('query_turn_active');
    await harness.waitForConversationToSettle();
    await capture('query_turn_settled');

    final projectEntries = await harness.listProjectEntries();
    final latestAssistant = _latestAssistantText(
      harness.conversation.conversationEntries,
    );
    final extractionEvidence =
        _hasProjectPath(projectEntries, const <String>[
          '.novel_agent/sqlite/novel_agent.db',
          'knowledge/',
          'research/',
        ]) ||
        harness
            .controller
            .projectAssetsController
            .viewData
            .entries
            .isNotEmpty ||
        harness.resources.informationViewData.entries.isNotEmpty;
    final answerHasAnchors =
        _containsAll(latestAssistant, const <String>['林烬', '潮汐议会']) &&
        latestAssistant.contains('声纹钥');
    final leakCheck = await _containsSourceLeak(
      harness,
      disallowedFragments: <String>[
        harness.repoRoot.path,
        harness.workspaceRoot.path,
      ],
    );
    final ok = extractionEvidence && answerHasAnchors && !leakCheck;

    report = <String, Object?>{
      ...report,
      'ok': ok,
      'report_category': ok ? 'success' : 'validation_failure',
      'finished_at': DateTime.now().toIso8601String(),
      'project_manifest': await harness.projectManifest(),
      'viewmodel_steps': steps,
      'model_decisions': modelDecisions,
      'tool_events': _toolEvents(harness),
      'validation': <String, Object?>{
        'source_file_repo_relative': harness.relativeToRepo(sourceFile.path),
        'extraction_evidence': extractionEvidence,
        'answer_has_expected_anchors': answerHasAnchors,
        'absolute_source_path_leak_detected': leakCheck,
        'latest_assistant_excerpt': _clip(latestAssistant, 700),
      },
      'files_created': projectEntries,
      'failures': ok
          ? const <Object?>[]
          : <Object?>[
              <String, Object?>{
                'category': 'validation_failure',
                'summary': '用户侧知识库生成缺少结构化证据、问答消费证据，或出现来源路径泄漏。',
              },
            ],
    };
  } catch (error, stackTrace) {
    report = _laneExceptionReport(
      base: report,
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    await harness.writeLaneReport(report);
    await harness.writeFixLog(_fixLog(report));
    harness.controller.dispose();
  }
  return report;
}

Future<JsonMap> _runLaneD(ProbeApiConfig apiConfig) async {
  const laneId = 'lane_d_book_import_knowledge_base';
  final harness = await HfvvWave1AppShellHarness.create(
    runId: _runId,
    laneId: laneId,
    apiConfig: apiConfig,
  );
  final steps = <String>[];
  final modelDecisions = <JsonMap>[];
  var stepIndex = 0;

  Future<void> capture(String label) async {
    stepIndex += 1;
    final stepId = _stepId(stepIndex);
    final event = _conversationEvent(harness, phase: label);
    steps.add(stepId);
    modelDecisions.add(event);
    await harness.recordStep(
      stepId: stepId,
      label: label,
      modelEvent: event,
      toolEvents: _toolEvents(harness),
    );
  }

  JsonMap report = <String, Object?>{
    'lane_id': laneId,
    'run_id': _runId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace':
        'artifacts/high_fidelity_viewmodel_validation/$_runId/$laneId/',
    'fixes_applied': const <Object?>[],
    'rerun_count': 0,
  };

  try {
    await capture('initialized');
    await harness.createProject(
      title: 'HFVV-04 Lane D 书籍导入知识库',
      projectTypeId: 'knowledge_base',
    );
    await harness.writeProjectManifest();
    await capture('project_created');

    final sourceFile = File(
      '${harness.repoRoot.path}${Platform.pathSeparator}artifacts'
      '${Platform.pathSeparator}high_fidelity_viewmodel_validation'
      '${Platform.pathSeparator}$_runId${Platform.pathSeparator}hfvv_03'
      '${Platform.pathSeparator}source_assets${Platform.pathSeparator}utf8'
      '${Platform.pathSeparator}harry_potter_volume1_raw_utf8.txt',
    );
    if (!sourceFile.existsSync()) {
      throw StateError('Lane D source file missing: ${sourceFile.path}');
    }
    await harness.controller.projectAssetsController.refresh();
    harness.referenceSourcePickerService.enqueue(sourceFile.path);
    final extraction = harness.controller.projectAssetsController
        .onProjectAssetsExtractReferenceRequested();
    await harness.waitUntil(
      () => harness.controller.projectAssetsController.viewData.isLoading,
      description: 'lane d extraction loading',
      timeout: const Duration(seconds: 20),
    );
    await capture('reference_extraction_active');
    await extraction;
    await harness.waitUntil(
      () => !harness.controller.projectAssetsController.viewData.isLoading,
      description: 'lane d extraction complete',
      timeout: const Duration(minutes: 15),
    );
    await capture('reference_extraction_settled');

    await harness.sendPrompt(
      '只根据当前项目知识库，用中文回答：哈利收到来信时住在哪条路？海格带他去哪里买魔法用品？奇洛教授有什么异常？如果知识库没有就明确说不知道。',
    );
    await harness.waitForConversationActivity();
    await capture('query_turn_active');
    await harness.waitForConversationToSettle(
      timeout: const Duration(minutes: 8),
    );
    await capture('query_turn_settled');

    final projectEntries = await harness.listProjectEntries();
    final latestAssistant = _latestAssistantText(
      harness.conversation.conversationEntries,
    );
    final extractionEvidence =
        _hasProjectPath(projectEntries, const <String>[
          '.novel_agent/sqlite/novel_agent.db',
          'knowledge/',
          'research/',
        ]) ||
        harness
            .controller
            .projectAssetsController
            .viewData
            .entries
            .isNotEmpty ||
        harness.resources.informationViewData.entries.isNotEmpty;
    final answerAnchorCount = _anchorHitCount(latestAssistant, const <String>[
      '女贞路',
      '对角巷',
      '海格',
      '奇洛',
    ]);
    final leakCheck = await _containsSourceLeak(
      harness,
      disallowedFragments: <String>[
        harness.repoRoot.path,
        harness.workspaceRoot.path,
      ],
    );
    final ok =
        extractionEvidence &&
        answerAnchorCount >= 2 &&
        _containsChinese(latestAssistant) &&
        !leakCheck;

    report = <String, Object?>{
      ...report,
      'ok': ok,
      'report_category': ok ? 'success' : 'content_quality_failure',
      'finished_at': DateTime.now().toIso8601String(),
      'project_manifest': await harness.projectManifest(),
      'viewmodel_steps': steps,
      'model_decisions': modelDecisions,
      'tool_events': _toolEvents(harness),
      'validation': <String, Object?>{
        'source_file_repo_relative': harness.relativeToRepo(sourceFile.path),
        'extraction_evidence': extractionEvidence,
        'answer_anchor_count': answerAnchorCount,
        'absolute_source_path_leak_detected': leakCheck,
        'latest_assistant_excerpt': _clip(latestAssistant, 700),
      },
      'files_created': projectEntries,
      'failures': ok
          ? const <Object?>[]
          : <Object?>[
              <String, Object?>{
                'category': 'content_quality_failure',
                'summary': 'Harry Potter 书籍导入后的知识库消费结果不足以证明结构化提取与中文问答可用。',
              },
            ],
    };
  } catch (error, stackTrace) {
    report = _laneExceptionReport(
      base: report,
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    await harness.writeLaneReport(report);
    await harness.writeFixLog(_fixLog(report));
    harness.controller.dispose();
  }
  return report;
}

Future<JsonMap> _runLaneE(ProbeApiConfig apiConfig) async {
  const laneId = 'lane_e_network_knowledge_base';
  final harness = await HfvvWave1AppShellHarness.create(
    runId: _runId,
    laneId: laneId,
    apiConfig: apiConfig,
  );
  final steps = <String>[];
  final modelDecisions = <JsonMap>[];
  var stepIndex = 0;

  Future<void> capture(String label) async {
    stepIndex += 1;
    final stepId = _stepId(stepIndex);
    final event = _conversationEvent(harness, phase: label);
    steps.add(stepId);
    modelDecisions.add(event);
    await harness.recordStep(
      stepId: stepId,
      label: label,
      modelEvent: event,
      toolEvents: _toolEvents(harness),
    );
  }

  JsonMap report = <String, Object?>{
    'lane_id': laneId,
    'run_id': _runId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace':
        'artifacts/high_fidelity_viewmodel_validation/$_runId/$laneId/',
    'fixes_applied': const <Object?>[],
    'rerun_count': 0,
  };

  try {
    await capture('initialized');
    await harness.createProject(
      title: 'HFVV-04 Lane E 网络知识库',
      projectTypeId: 'knowledge_base',
    );
    await harness.writeProjectManifest();
    await capture('project_created');

    const prompt = '''
请把当前项目当成“历史制度与技术节点”知识库来整理，不要写小说正文。

目标：为“明代背景下适合前二十章逐步落地的小改良”做第一轮资料整理，优先核查民间制盐、冶铁/高炉、农业改良、基础交通或水利里最适合写进故事的 4-6 个技术节点。

要求：
- 需要联网时请明确发起资料研究。
- 只保留有来源线索、适合故事落地的内容。
- 不确定就写不知道，不要假装成功。
''';
    await harness.sendPrompt(prompt);
    await harness.waitForConversationActivity(
      timeout: const Duration(minutes: 2),
    );
    await capture('turn_1_active');
    await harness.waitForConversationToSettle(
      timeout: const Duration(minutes: 10),
    );
    await capture('turn_1_settled');

    final researchOption = _findPendingOption(
      harness.conversation.pendingOptions,
      keywords: const <String>['资料', '研究', '继续', '联网'],
    );
    if (researchOption != null) {
      await harness.selectPendingOption(researchOption);
      await harness.waitForConversationActivity(
        timeout: const Duration(minutes: 2),
      );
      await capture('turn_2_active');
      await harness.waitForConversationToSettle(
        timeout: const Duration(minutes: 10),
      );
      await capture('turn_2_settled');
    }

    final projectEntries = await harness.listProjectEntries();
    final latestAssistant = _latestAssistantText(
      harness.conversation.conversationEntries,
    );
    final hasNetworkKnowledgeEvidence =
        _hasProjectPath(projectEntries, const <String>[
          'research/',
          '.novel_agent/information/research_notes/',
          'knowledge/',
        ]) ||
        harness.resources.informationViewData.entries.isNotEmpty;
    final fakeSuccess =
        !hasNetworkKnowledgeEvidence &&
        !_hasToolLifecycle(
          harness.conversation.conversationEntries,
          ConversationToolLifecycleStatus.failed,
        ) &&
        harness.conversation.pendingOptions.isEmpty;
    final ok = hasNetworkKnowledgeEvidence && !fakeSuccess;

    report = <String, Object?>{
      ...report,
      'ok': ok,
      'report_category': ok
          ? 'success'
          : (fakeSuccess ? 'validation_failure' : 'content_quality_failure'),
      'finished_at': DateTime.now().toIso8601String(),
      'project_manifest': await harness.projectManifest(),
      'viewmodel_steps': steps,
      'model_decisions': modelDecisions,
      'tool_events': _toolEvents(harness),
      'validation': <String, Object?>{
        'has_network_knowledge_evidence': hasNetworkKnowledgeEvidence,
        'fake_success_detected': fakeSuccess,
        'waiting_user': harness.conversation.pendingOptions.isNotEmpty,
        'tool_failed': _hasToolLifecycle(
          harness.conversation.conversationEntries,
          ConversationToolLifecycleStatus.failed,
        ),
        'latest_assistant_excerpt': _clip(latestAssistant, 700),
      },
      'files_created': projectEntries,
      'failures': ok
          ? const <Object?>[]
          : <Object?>[
              <String, Object?>{
                'category': fakeSuccess
                    ? 'validation_failure'
                    : 'content_quality_failure',
                'summary': '网络知识库没有留下可信的资料研究证据，或表现出“没有资料却像成功”的假阳性。',
              },
            ],
    };
  } catch (error, stackTrace) {
    report = _laneExceptionReport(
      base: report,
      error: error,
      stackTrace: stackTrace,
    );
  } finally {
    await harness.writeLaneReport(report);
    await harness.writeFixLog(_fixLog(report));
    harness.controller.dispose();
  }
  return report;
}

String _stepId(int value) => 'step_${value.toString().padLeft(3, '0')}';

JsonMap _conversationEvent(
  HfvvWave1AppShellHarness harness, {
  required String phase,
}) {
  final latestAssistant = _latestAssistantText(
    harness.conversation.conversationEntries,
  );
  return <String, Object?>{
    'phase': phase,
    'captured_at': DateTime.now().toIso8601String(),
    'generation_status': harness.conversation.generationStatus,
    'tool_core_status': harness.conversation.toolCoreStatus,
    'pending_option_labels': harness.conversation.pendingOptions
        .map((option) => option.label)
        .toList(growable: false),
    'sub_agent_run_count': harness.conversation.subAgentRuns.length,
    'information_entry_count':
        harness.resources.informationViewData.entries.length,
    'latest_assistant_excerpt': _clip(latestAssistant, 500),
  };
}

List<Object?> _toolEvents(HfvvWave1AppShellHarness harness) {
  return harness.conversation.conversationEntries
      .where((entry) => entry.toolLifecycleStatus != null)
      .map(
        (entry) => <String, Object?>{
          'id': entry.id,
          'title': entry.title,
          'body': _clip(entry.body, 240),
          'status': entry.toolLifecycleStatus?.name ?? '',
          'detail_summary': entry.detailSummary,
        },
      )
      .toList(growable: false);
}

UserOptionViewData? _findPendingOption(
  List<UserOptionViewData> options, {
  required List<String> keywords,
}) {
  for (final keyword in keywords) {
    for (final option in options) {
      final text = '${option.label} ${option.description} ${option.prompt}';
      if (text.contains(keyword)) {
        return option;
      }
    }
  }
  return options.isEmpty ? null : options.first;
}

Future<_LaneAValidationState> _loadLaneAValidationState(
  HfvvWave1AppShellHarness harness,
) async {
  final projectEntries = await harness.listProjectEntries();
  final latestAssistant = _latestAssistantText(
    harness.conversation.conversationEntries,
  );
  return _LaneAValidationState(
    projectEntries: projectEntries,
    hasResearchEvidence:
        projectEntries.any(_isLaneAInformationArtifact) ||
        harness.resources.informationViewData.entries.isNotEmpty,
    wroteChapterDirectly:
        _hasProjectPath(projectEntries, const <String>['chapters/chapter_']) ||
        latestAssistant.contains('第01章') ||
        latestAssistant.contains('第1章'),
    waitingUser: harness.conversation.pendingOptions.isNotEmpty,
    latestAssistant: latestAssistant,
  );
}

bool _isLaneAInformationArtifact(JsonMap entry) {
  final path = ValueReaders.stringValue(
    entry['relative_path'],
  ).replaceAll('\\', '/');
  if (ValueReaders.boolValue(entry['is_dir'])) {
    return false;
  }
  final lower = path.toLowerCase();
  if (lower.contains('chapters/chapter_')) {
    return false;
  }
  if (lower.contains('research/')) {
    return true;
  }
  if (lower.contains('knowledge/')) {
    return true;
  }
  if (lower.contains('.novel_agent/information/research_notes/')) {
    return true;
  }
  if (lower.contains('.novel_agent/information/research_requests/')) {
    return true;
  }
  if (lower.contains('tracking/conversation_draft/research_')) {
    return true;
  }
  if (lower.contains('information_')) {
    return true;
  }
  if (lower.contains('risk_assessment')) {
    return true;
  }
  return path.contains('资料') ||
      path.contains('研究') ||
      path.contains('风险评估') ||
      path.contains('优先级清单');
}

String _latestAssistantText(List<ConversationEntryViewData> entries) {
  for (final entry in entries.reversed) {
    final body = entry.body.trim();
    if (body.isNotEmpty &&
        entry.toolLifecycleStatus == null &&
        !entry.isError &&
        entry.kind.name != 'user') {
      return body;
    }
  }
  for (final entry in entries.reversed) {
    final body = entry.body.trim();
    if (body.isNotEmpty && !entry.isError) {
      return body;
    }
  }
  return '';
}

bool _hasProjectPath(List<JsonMap> entries, List<String> prefixes) {
  for (final entry in entries) {
    final path = ValueReaders.stringValue(
      entry['relative_path'],
    ).replaceAll('\\', '/');
    for (final prefix in prefixes) {
      if (path.contains(prefix)) {
        return true;
      }
    }
  }
  return false;
}

bool _hasToolLifecycle(
  List<ConversationEntryViewData> entries,
  ConversationToolLifecycleStatus status,
) {
  return entries.any((entry) => entry.toolLifecycleStatus == status);
}

Future<List<String>> _loadExpressionBindingProfileIds(
  HfvvWave1AppShellHarness harness,
) async {
  final projectManifest = await harness.projectManifest();
  return ValueReaders.stringList(
    projectManifest['expression_constraint_profile_ids'],
  );
}

String _laneCategoryFromSignals({
  required bool waitingUser,
  required bool hasEvidence,
}) {
  if (waitingUser) {
    return 'waiting_user';
  }
  if (!hasEvidence) {
    return 'validation_failure';
  }
  return 'content_quality_failure';
}

class _LaneAValidationState {
  const _LaneAValidationState({
    required this.projectEntries,
    required this.hasResearchEvidence,
    required this.wroteChapterDirectly,
    required this.waitingUser,
    required this.latestAssistant,
  });

  final List<JsonMap> projectEntries;
  final bool hasResearchEvidence;
  final bool wroteChapterDirectly;
  final bool waitingUser;
  final String latestAssistant;
}

JsonMap _laneExceptionReport({
  required JsonMap base,
  required Object error,
  required StackTrace stackTrace,
}) {
  final summary = '$error';
  return <String, Object?>{
    ...base,
    'ok': false,
    'report_category': _categorizeException(summary),
    'finished_at': DateTime.now().toIso8601String(),
    'error': summary,
    'stack_trace': '$stackTrace',
    'failures': <Object?>[
      <String, Object?>{
        'category': _categorizeException(summary),
        'summary': summary,
      },
    ],
  };
}

String _categorizeException(String summary) {
  final lower = summary.toLowerCase();
  if (lower.contains('timed out') ||
      lower.contains('429') ||
      lower.contains('quota') ||
      lower.contains('connection') ||
      lower.contains('socket') ||
      lower.contains('tls') ||
      lower.contains('api')) {
    return 'blocked_external';
  }
  return 'technical_failure';
}

Future<bool> _containsSourceLeak(
  HfvvWave1AppShellHarness harness, {
  required List<String> disallowedFragments,
}) async {
  final entries = await harness.listProjectEntries();
  for (final entry in entries) {
    final relativePath = ValueReaders.stringValue(entry['relative_path']);
    if (ValueReaders.boolValue(entry['is_dir'])) {
      continue;
    }
    if (!_looksTextLike(relativePath)) {
      continue;
    }
    final content = await harness.readProjectFile(relativePath);
    final cleanContent = content.replaceAll('\\', '/');
    for (final fragment in disallowedFragments) {
      final cleanFragment = fragment.replaceAll('\\', '/');
      if (cleanFragment.trim().isNotEmpty &&
          cleanContent.contains(cleanFragment)) {
        return true;
      }
    }
    if (containsProbableAbsolutePathLeak(cleanContent)) {
      return true;
    }
  }
  return false;
}

bool _looksTextLike(String relativePath) {
  final cleanPath = relativePath.toLowerCase();
  return cleanPath.endsWith('.json') ||
      cleanPath.endsWith('.md') ||
      cleanPath.endsWith('.txt') ||
      cleanPath.endsWith('.yaml') ||
      cleanPath.endsWith('.yml');
}

bool _containsAll(String text, List<String> anchors) {
  for (final anchor in anchors) {
    if (!text.contains(anchor)) {
      return false;
    }
  }
  return true;
}

int _anchorHitCount(String text, List<String> anchors) {
  var result = 0;
  for (final anchor in anchors) {
    if (text.contains(anchor)) {
      result += 1;
    }
  }
  return result;
}

bool _containsChinese(String text) {
  return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
}

String _clip(String text, int maxLength) {
  final cleanText = text.trim();
  if (cleanText.length <= maxLength) {
    return cleanText;
  }
  return '${cleanText.substring(0, maxLength)}...';
}

String _fixLog(JsonMap report) {
  final ok = ValueReaders.boolValue(report['ok']);
  final category = ValueReaders.stringValue(report['report_category']);
  final summary = ok
      ? '本轮未触发生产修复；HFVV-04 仅完成首轮高保真运行与证据落盘。'
      : '本轮已冻结失败现场，等待 HFVV-05 进入生产链路修复与重跑。';
  return '''
# ${ValueReaders.stringValue(report['lane_id'])}

- status: ${ok ? 'passed' : 'failed'}
- report_category: $category
- note: $summary
''';
}

Future<void> _writeSummary(String repoRoot, JsonMap summary) async {
  final root = Directory(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
    'high_fidelity_viewmodel_validation${Platform.pathSeparator}$_runId',
  )..createSync(recursive: true);
  final jsonFile = File(
    '${root.path}${Platform.pathSeparator}hfvv_04_wave1_summary.json',
  );
  await jsonFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(summary)}\n',
  );
  final markdownFile = File(
    '${root.path}${Platform.pathSeparator}hfvv_04_wave1_summary.md',
  );
  final lanes = ValueReaders.objectList(summary['lanes']);
  final lines = <String>[
    '# HFVV-04 Wave 1 Summary',
    '',
    '- run_id: $_runId',
    '- model_id: ${ValueReaders.stringValue(summary['model_id'])}',
    '- ok: ${ValueReaders.boolValue(summary['ok'])}',
    '',
    '## Lanes',
    '',
    for (final lane in lanes)
      '- ${ValueReaders.stringValue(ValueReaders.mapValue(lane)['lane_id'])}: ${ValueReaders.boolValue(ValueReaders.mapValue(lane)['ok']) ? 'passed' : ValueReaders.stringValue(ValueReaders.mapValue(lane)['report_category'])}',
  ];
  await markdownFile.writeAsString('${lines.join('\n')}\n');
}

const String _laneCUserSourceMarkdown = '''
# 盐井城设定笔记

主角：林烬，原本是做城市声学维护的工程师，穿越后在盐井城做低调记录员。

组织：潮汐议会，表面上是维护盐运秩序的公共议会，实际上把持城内盐井税契与消息分发。

禁忌：任何人不得私自复制“声纹钥”或在夜潮时段公开试验，会被视为窃取议会印记。

核心冲突：
- 林烬发现旧盐井图与议会公开版本不一致。
- 她怀疑有人借“夜潮噪音”掩盖非法盐运和人员失踪。
- 她必须在不惊动议会的前提下确认失踪记录与旧井位。
''';
