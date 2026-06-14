import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_entry_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/user_option_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'hfvv_wave1_viewmodel_support.dart';
import 'probe_support.dart';
import '../../../tools/probe_config_support.dart';

const String _laneId = 'lane_ordinary_chaptered_continuation';

Future<void> main(List<String> arguments) async {
  await ensureLocalRealProbeOptIn(
    probeName: 'real_gui_chaptered_continuation_probe',
  );
  final summary = await runRealGuiChapteredContinuationProbe();
  stdout.writeln(ValueReaders.boolValue(summary['ok']) ? 'PASS' : 'FAIL');
  if (!ValueReaders.boolValue(summary['ok'])) {
    exitCode = 1;
  }
}

Future<JsonMap> runRealGuiChapteredContinuationProbe({
  bool requireRealProbeOptIn = true,
}) async {
  final rawRunId = DateTime.now().toIso8601String();
  final runId = safeProbeTimestamp(rawRunId);
  final apiConfig = await loadProbeApiConfig(
    probeName: 'real_gui_chaptered_continuation_probe',
    requireRealProbeOptIn: requireRealProbeOptIn,
    repoRootOverride: resolveLocalProbeRepoRoot(),
  );
  final harness = await HfvvWave1AppShellHarness.create(
    runId: runId,
    laneId: _laneId,
    apiConfig: apiConfig,
    streamMode: 'non_stream',
  );
  final steps = <String>[];
  final modelEvents = <JsonMap>[];
  final decisions = <JsonMap>[];
  var stepIndex = 0;

  Future<void> capture(String label) async {
    stepIndex += 1;
    final stepId = 'step_${stepIndex.toString().padLeft(3, '0')}';
    final modelEvent = _conversationEvent(harness, phase: label);
    steps.add(stepId);
    modelEvents.add(modelEvent);
    await harness.recordStep(
      stepId: stepId,
      label: label,
      modelEvent: modelEvent,
      toolEvents: _toolEvents(harness),
    );
  }

  JsonMap report = <String, Object?>{
    'probe_name': 'real_gui_chaptered_continuation_probe',
    'lane_id': _laneId,
    'run_id': runId,
    'raw_run_id': rawRunId,
    'started_at': DateTime.now().toIso8601String(),
    'workspace':
        'artifacts/high_fidelity_viewmodel_validation/$runId/$_laneId/',
    'provider_source': apiConfig.sourceLabel,
    'model_id': apiConfig.modelId,
    'fixes_applied': const <Object?>[],
    'rerun_count': 0,
  };

  try {
    await capture('initialized');
    await harness.createProject(
      title: 'HFVV 普通分章续写承接验证',
      projectTypeId: 'novel',
    );
    await _seedProjectFoundation(harness);
    harness.controller.onRefreshFilesRequested();
    await harness.controller.projectAssetsController.refresh();
    await harness.waitUntil(
      () => harness.resources.resourceEntries.any(
        (entry) => entry.relativePath.contains('chapters/第02章_摸底.md'),
      ),
      description: 'seeded project files visible in resource tree',
      timeout: const Duration(seconds: 20),
    );
    await harness.writeProjectManifest();
    await capture('project_seeded');

    await harness.sendPrompt(_continuationPrompt);
    await harness.waitForConversationActivity(
      timeout: const Duration(minutes: 2),
    );
    await capture('turn_1_active');
    await harness.waitForConversationToSettle(
      timeout: const Duration(minutes: 12),
    );
    await capture('turn_1_settled');

    for (var round = 2; round <= 3; round += 1) {
      final pendingOptions = harness.conversation.pendingOptions;
      if (pendingOptions.isEmpty) {
        break;
      }
      final decision = _decideNextStepFromPendingOptions(pendingOptions);
      decisions.add(decision);
      final option = decision['selected_option'];
      if (option is String && option.trim().isNotEmpty) {
        final match = pendingOptions.firstWhere(
          (candidate) => candidate.label == option,
          orElse: () => pendingOptions.first,
        );
        await harness.selectPendingOption(match);
      } else {
        await harness.sendPrompt(
          ValueReaders.stringValue(decision['follow_up_prompt']),
        );
      }
      await harness.waitForConversationActivity(
        timeout: const Duration(minutes: 2),
      );
      await capture('turn_${round}_active');
      await harness.waitForConversationToSettle(
        timeout: const Duration(minutes: 12),
      );
      await capture('turn_${round}_settled');
    }

    final projectRoot = harness.workbench.projectPath.trim();
    final project = _currentProjectDescriptor(harness);
    final projectEntries = await harness.listProjectEntries();
    final activationReportPath = _findProjectFilePath(
      projectEntries,
      RegExp(r'^tracking/conversation_draft/.*\.activation_report\.json$'),
    );
    final activationReport = activationReportPath == null
        ? const <String, Object?>{}
        : _decodeJson(await harness.readProjectFile(activationReportPath));
final chapter3Path = _findChapterPath(projectEntries, chapterNumber: 3);
    final chapter3Content = chapter3Path.isEmpty
        ? ''
        : await harness.readProjectFile(chapter3Path);
    final chapter3DeliveryPath = chapter3Path.isEmpty
        ? ''
        : _deliverySidecarPath(chapter3Path);
    final chapter3Delivery = chapter3DeliveryPath.isEmpty
        ? const <String, Object?>{}
        : _decodeJson(await harness.readProjectFile(chapter3DeliveryPath));
    final chapterBodyLength = _chapterBodyLength(chapter3Content);
    final activationSelectedSections = ValueReaders.mapList(
      ValueReaders.mapValue(
        activationReport['metadata'],
      )['selected_context_sections'],
    );
    final selectedIds = activationSelectedSections
        .map((item) => ValueReaders.stringValue(item['item_id']))
        .toList(growable: false);
    final continuitySelected =
        selectedIds.any(
          (id) => id.contains('tracking/continuity/scopes/global.json'),
        ) &&
        selectedIds.any(
          (id) => id.contains('tracking/continuity/frames/mainline.json'),
        ) &&
        selectedIds.any(
          (id) => id.contains('tracking/continuity/bundle.json'),
        );
    final firstParagraph = _chapterFirstParagraph(chapter3Content);
    final continuityOpeningOk =
        !firstParagraph.contains('只等门里的人给一句回音') &&
        (firstParagraph.contains('门开') ||
            firstParagraph.contains('门拉开') ||
            firstParagraph.contains('油灯光') ||
            firstParagraph.contains('门槛') ||
            firstParagraph.contains('门缝') ||
            firstParagraph.contains('王保正') ||
            firstParagraph.contains('井车') ||
            firstParagraph.contains('回了他一句') ||
            firstParagraph.contains('答道'));
    final deliverySubmission = ValueReaders.mapValue(
      chapter3Delivery['submission'],
    );
    final finalState = ValueReaders.mapValue(
      deliverySubmission['final_state_summary'],
    );
    final deliveryHasHandoff =
        ValueReaders.stringValue(
          deliverySubmission['summary'],
        ).trim().isNotEmpty &&
        ValueReaders.stringValue(
          finalState['next_chapter_handoff'],
        ).trim().isNotEmpty;
    final chapterLengthBindingEvidence =
        await _loadChapterLengthBindingEvidence(
          project,
          workspacePort: harness.bundle.projectWorkspacePort,
        );
    final toolStatuses = _toolStatusCounts(
      harness.conversation.conversationEntries,
    );
    final pendingOrRunningObserved =
        ValueReaders.intValue(toolStatuses['running']) > 0 ||
        ValueReaders.intValue(toolStatuses['pendingConfirmation']) > 0 ||
        steps.any((step) => step.contains('active'));
    final resourceTreeHasChapter3 =
        chapter3Path.isNotEmpty &&
        harness.resources.resourceEntries.any(
          (entry) => entry.relativePath == chapter3Path,
        );
    final terminalGenerationStatus = harness.conversation.generationStatus;
    final externalBlocked = _looksLikeExternalBlockedStatus(
      terminalGenerationStatus,
    );
    final ok =
        !externalBlocked &&
        activationReportPath != null &&
        continuitySelected &&
        chapter3Path.isNotEmpty &&
        chapterBodyLength >= 1550 &&
        chapterBodyLength <= 2600 &&
        continuityOpeningOk &&
        deliveryHasHandoff &&
        resourceTreeHasChapter3 &&
        pendingOrRunningObserved;

    report = <String, Object?>{
      ...report,
      'ok': ok,
      'report_category': ok
          ? ProbeReportCategories.success
          : externalBlocked
          ? 'blocked_external'
          : ProbeReportCategories.contentQualityFailure,
      'finished_at': DateTime.now().toIso8601String(),
      'project_manifest': await harness.projectManifest(),
      'viewmodel_steps': steps,
      'model_decisions': modelEvents,
      'dynamic_decisions': decisions,
      'tool_events': _toolEvents(harness),
      'files_created': projectEntries,
      'validation': <String, Object?>{
        'activation_report_path': activationReportPath ?? '',
        'activation_selected_item_ids': selectedIds,
        'continuity_selected': continuitySelected,
        'chapter_3_path': chapter3Path,
        'chapter_3_repo_relative': harness.relativeToRepo(
          '$projectRoot${Platform.pathSeparator}${chapter3Path.replaceAll('/', Platform.pathSeparator)}',
        ),
        'chapter_3_body_length': chapterBodyLength,
        'chapter_3_first_paragraph': _clip(firstParagraph, 220),
        'continuity_opening_ok': continuityOpeningOk,
        'chapter_3_delivery_path': chapter3DeliveryPath,
        'chapter_3_delivery_has_handoff': deliveryHasHandoff,
        'resource_tree_has_chapter_3': resourceTreeHasChapter3,
        'pending_or_running_tool_observed': pendingOrRunningObserved,
        'tool_status_counts': toolStatuses,
        'chapter_length_binding_evidence': chapterLengthBindingEvidence,
        'latest_assistant_excerpt': _clip(
          _latestAssistantText(harness.conversation.conversationEntries),
          600,
        ),
      },
      'failures': ok
          ? const <Object?>[]
          : <Object?>[
              if (externalBlocked)
                <String, Object?>{
                  'category': 'blocked_external',
                  'summary': terminalGenerationStatus,
                },
              if (!externalBlocked && activationReportPath == null)
                <String, Object?>{
                  'category': ProbeReportCategories.contentQualityFailure,
                  'summary': '普通分章续写没有产出 activation report。',
                },
              if (!externalBlocked && !continuitySelected)
                <String, Object?>{
                  'category': ProbeReportCategories.contentQualityFailure,
                  'summary': 'activation report 没有选到上一章交付摘要与章末锚点。',
                },
              if (!externalBlocked && chapter3Path.isEmpty)
                <String, Object?>{
                  'category': ProbeReportCategories.contentQualityFailure,
                  'summary': '续写没有形成正式第03章落盘文件。',
                },
              if (!externalBlocked &&
                  chapter3Path.isNotEmpty &&
                  (chapterBodyLength < 1600 || chapterBodyLength > 2600))
                <String, Object?>{
                  'category': ProbeReportCategories.contentQualityFailure,
                  'summary': '第03章正文长度 $chapterBodyLength，不在 1600-2600 验收窗口内。',
                },
              if (!externalBlocked && !continuityOpeningOk)
                <String, Object?>{
                  'category': ProbeReportCategories.contentQualityFailure,
                  'summary': '第03章开头没有稳定承接上一章章末状态，仍疑似重演门前动作。',
                },
              if (!externalBlocked && !deliveryHasHandoff)
                <String, Object?>{
                  'category': ProbeReportCategories.contentQualityFailure,
                  'summary': '第03章正式交付缺少 summary 或 next_chapter_handoff。',
                },
            ],
    };

    await _writeMarkdownSummary(harness, report);
  } catch (error, stackTrace) {
    report = <String, Object?>{
      ...report,
      'ok': false,
      'report_category': _categorizeException('$error'),
      'finished_at': DateTime.now().toIso8601String(),
      'error': '$error',
      'stack_trace': '$stackTrace',
      'failures': <Object?>[
        <String, Object?>{
          'category': _categorizeException('$error'),
          'summary': '$error',
        },
      ],
    };
  } finally {
    await harness.writeLaneReport(report);
    await harness.writeFixLog(_fixLog(report));
    harness.controller.dispose();
  }
  return report;
}

Future<void> _seedProjectFoundation(HfvvWave1AppShellHarness harness) async {
  final project = _currentProjectDescriptor(harness);
  final workspacePort = harness.bundle.projectWorkspacePort;
  final expressionBindingRepository =
      ProjectExpressionConstraintBindingRepository(
        workspacePort: workspacePort,
      );
  final expressionProfileRepository = ExpressionConstraintProfileRepository(
    workspacePort: workspacePort,
  );
  final constraintBindingRepository = LocalConstraintBindingRepository(
    workspacePort: workspacePort,
  );

  await workspacePort.writeTextFile(
    project.rootPath,
    'specs/project_spec.md',
    '# 项目规格\n\n这是一个普通项目下的正式分章续写验证，不是长任务。\n要求：第03章必须直接承接第02章章末，不要重演门前动作。\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'outline/总纲.md',
    '# 总纲\n\n主角周砚流落江南小镇，想先找个落脚点，再用简陋井车和晒盐改良换取站稳脚跟的机会。\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/characters/周砚.md',
    '# 周砚\n\n现代做工地机电维护的社畜，穿来后谨慎但嘴快，善于把复杂原理讲成乡里能懂的话。\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'summaries/第02章：摸底.summary.md',
    '第02章摘要：周砚冒雨敲开王保正家门，说明自己懂井车和晒盐法，想求一夜借宿与一个试做机会。',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'assets/timeline/第02章_摸底.timeline.md',
    '第02章时间线：夜雨中敲门 -> 王保正让出门缝 -> 周砚说明来意与井车想法 -> 门前气氛从戒备转向试探。',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'chapters/第02章_摸底.md',
    '# 第02章 摸底\n\n雨脚把青石板冲得发亮，周砚在门外站了半盏茶，才等来一声木闩轻响。\n\n门缝开得很窄，王保正先看了他一眼，又看了看他抱在怀里的旧木匣，声音里全是防备：“夜里来敲门，求什么？”\n\n周砚没敢往前挤，只把木匣托高半寸，压着气息道：“不求别的，求一晚屋檐，再求您明早给我半个时辰。我会做井车，也知道怎么让盐场少费一层柴火。要是我说得全是胡话，天亮前您把我赶出去都成。”\n\n王保正没立刻回话，只把门又让开一指，视线从他鞋上的泥一直扫到木匣边角，像是在量他话里到底有几分真。\n\n风从院里卷出来，带着潮木和冷灶灰的味道。周砚知道自己不能再把来历、雨路和苦相重复一遍，只能等一句真回音。\n',
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    '.novel_agent/continuity/deliveries/submission_chapters_第02章_摸底.md.json',
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'submission': <String, Object?>{
        'title': '第02章 摸底',
        'summary': '第02章交付：周砚已在门前说明自己会做井车和晒盐改良，只等王保正给出试探性回应。',
        'final_state_summary': <String, Object?>{
          'location': '王保正家门口',
          'active_goal': '争取借宿与一个试做井车的机会',
          'unresolved_hook': '王保正是否愿意先让他进门并听完井车想法',
          'next_chapter_handoff':
              '直接从王保正让出门缝、开口试探“你会打井车？”继续，主角立刻回答，不要重复敲门、报来历或再走一遍门前犹豫。',
        },
      },
    }),
  );

  final expressionBindings = defaultProbeExpressionBindings(
    idPrefix: 'ordinary_chaptered_continuation',
  );
  await expressionBindingRepository.saveBindings(project, expressionBindings);
  final profiles = await expressionProfileRepository.loadProfiles(project);
  final expressionSetup = buildProbeExpressionConstraintSetupReport(
    loadedProfiles: profiles,
    savedBindings: expressionBindings,
  );
  await workspacePort.writeTextFile(
    project.rootPath,
    'tracking/probe/expression_constraint_setup.json',
    '${const JsonEncoder.withIndent('  ').convert(expressionSetup)}\n',
  );

  await constraintBindingRepository.appendBinding(
    project,
    NarrativeConstraintBindingProposal(
      bindingId: 'ordinary_chapter_length_binding',
      constraintType: 'chapter_length',
      constraintLabel: '普通分章字数窗口',
      scope: const ConstraintBindingScope(
        appliesTo: <String>[ConstraintBindingAppliesTo.writing],
        stageIds: <String>['draft'],
      ),
      policy: const ConstraintBindingPolicy(
        hardExecutionPolicy: <String, Object?>{'target_word_count': 2200},
      ),
      source: const NarrativeSourceRef(
        sourceType: NarrativeSourceTypes.user,
        sourceId: 'hfvv_probe_user',
        label: 'hfvv probe user',
      ),
      constraintPayload: const <String, Object?>{
        'target_word_count': 2200,
        'preferred_min': 1600,
        'preferred_max': 2600,
      },
    ),
  );
}

ProjectDescriptor _currentProjectDescriptor(HfvvWave1AppShellHarness harness) {
  return ProjectDescriptor(
    id: '',
    name: harness.workbench.projectName,
    rootPath: harness.workbench.projectPath.trim(),
    projectType: 'novel',
  );
}

JsonMap _decideNextStepFromPendingOptions(List<UserOptionViewData> options) {
  for (final option in options) {
    final text = '${option.label} ${option.description} ${option.prompt}';
    if (text.contains('继续写') ||
        text.contains('直接续写') ||
        text.contains('本章') ||
        text.contains('第03章') ||
        text.contains('第三章')) {
      return <String, Object?>{
        'strategy': 'select_pending_option',
        'reason': 'option_keeps_chapter_continuation',
        'selected_option': option.label,
      };
    }
  }
  return <String, Object?>{
    'strategy': 'send_follow_up_prompt',
    'reason': 'no_direct_continuation_option',
    'selected_option': '',
    'follow_up_prompt': _continuationFollowUpPrompt,
  };
}

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
    'resource_entry_count': harness.resources.resourceEntries.length,
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
  return '';
}

Map<String, Object?> _toolStatusCounts(
  List<ConversationEntryViewData> entries,
) {
  final result = <String, int>{
    'running': 0,
    'completed': 0,
    'failed': 0,
    'pendingConfirmation': 0,
  };
  for (final entry in entries) {
    final status = entry.toolLifecycleStatus?.name;
    if (status == null || !result.containsKey(status)) {
      continue;
    }
    result[status] = (result[status] ?? 0) + 1;
  }
  return result;
}

String _findChapterPath(List<JsonMap> entries, {required int chapterNumber}) {
  final prefix = '第${chapterNumber.toString().padLeft(2, '0')}章';
  final numericPrefix = chapterNumber.toString().padLeft(2, '0');
  final paddedNumericPrefix = chapterNumber.toString().padLeft(3, '0');
  for (final entry in entries) {
    if (ValueReaders.boolValue(entry['is_dir'])) {
      continue;
    }
    final path = _normalizedProjectRelativePath(
      entry['relative_path'],
    );
    if (!path.startsWith('chapters/') || !path.endsWith('.md')) {
      continue;
    }
    final fileName = path.split('/').last;
    if (fileName.startsWith(prefix) ||
        fileName.startsWith('$numericPrefix-') ||
        fileName.startsWith('$paddedNumericPrefix-') ||
        fileName == '$paddedNumericPrefix.md' ||
        fileName.startsWith('第$numericPrefix章') ||
        fileName.startsWith('$chapterNumber-')) {
      return path;
    }
  }
  return '';
}

String _findProjectFilePath(List<JsonMap> entries, RegExp pattern) {
  for (final entry in entries) {
    if (ValueReaders.boolValue(entry['is_dir'])) {
      continue;
    }
    final path = _normalizedProjectRelativePath(
      entry['relative_path'],
    );
    if (pattern.hasMatch(path)) {
      return path;
    }
  }
  return '';
}

String _normalizedProjectRelativePath(Object? raw) {
  final path = ValueReaders.stringValue(raw).replaceAll('\\', '/');
  final projectRootMarker = 'HFVV_普通分章续写承接验证/';
  final rootIndex = path.indexOf(projectRootMarker);
  if (rootIndex >= 0) {
    return path.substring(rootIndex + projectRootMarker.length);
  }
  return path;
}

String _deliverySidecarPath(String chapterPath) {
  final fileName = chapterPath.split('/').last;
  return '.novel_agent/continuity/deliveries/submission_chapters_$fileName.json';
}

int _chapterBodyLength(String markdown) {
  final body = markdown
      .replaceAll('\r\n', '\n')
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('#'))
      .join('\n')
      .replaceAll(RegExp(r'\s+'), '')
      .trim();
  return body.length;
}

String _chapterFirstParagraph(String markdown) {
  final body = markdown
      .replaceAll('\r\n', '\n')
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('#'))
      .join('\n')
      .trim();
  if (body.isEmpty) {
    return '';
  }
  final parts = body.split(RegExp(r'\n\s*\n'));
  return parts.first.trim();
}

Future<JsonMap> _loadChapterLengthBindingEvidence(
  ProjectDescriptor project, {
  required ProjectWorkspacePort workspacePort,
}) async {
  final repository = LocalConstraintBindingRepository(
    workspacePort: workspacePort,
  );
  final bindings = await repository.listBindings(project);
  final match = bindings.where(
    (binding) => binding.constraintType == 'chapter_length',
  );
  return <String, Object?>{
    'binding_count': bindings.length,
    'chapter_length_binding_count': match.length,
    'chapter_length_bindings': match
        .map(
          (binding) => <String, Object?>{
            'binding_id': binding.bindingId,
            'constraint_payload': ValueReaders.deepCopyMap(
              binding.constraintPayload,
            ),
            'hard_execution_policy': ValueReaders.deepCopyMap(
              binding.policy.hardExecutionPolicy,
            ),
          },
        )
        .toList(growable: false),
  };
}

JsonMap _decodeJson(String raw) {
  final clean = raw.trim();
  if (clean.isEmpty) {
    return const <String, Object?>{};
  }
  try {
    return ValueReaders.mapValue(jsonDecode(clean));
  } catch (_) {
    return const <String, Object?>{};
  }
}

Future<void> _writeMarkdownSummary(
  HfvvWave1AppShellHarness harness,
  JsonMap report,
) async {
  final validation = ValueReaders.mapValue(report['validation']);
  final file = File(
    '${harness.artifactRoot.path}${Platform.pathSeparator}probe_summary.md',
  );
  final lines = <String>[
    '# 普通分章续写真机高保真探针',
    '',
    '- 结果：${ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL'}',
    '- 分类：${ValueReaders.stringValue(report['report_category'])}',
    '- 章节文件：`${ValueReaders.stringValue(validation['chapter_3_path'])}`',
    '- 正文长度：${ValueReaders.intValue(validation['chapter_3_body_length'])}',
    '- continuity selected：${ValueReaders.boolValue(validation['continuity_selected'])}',
    '- continuity opening ok：${ValueReaders.boolValue(validation['continuity_opening_ok'])}',
    '- delivery handoff：${ValueReaders.boolValue(validation['chapter_3_delivery_has_handoff'])}',
    '- running/pending observed：${ValueReaders.boolValue(validation['pending_or_running_tool_observed'])}',
    '',
    '## 首段',
    '',
    _clip(
      ValueReaders.stringValue(validation['chapter_3_first_paragraph']),
      300,
    ),
    '',
    '## 最新回复摘要',
    '',
    _clip(
      ValueReaders.stringValue(validation['latest_assistant_excerpt']),
      500,
    ),
  ];
  await file.writeAsString('${lines.join('\n')}\n');
}

String _categorizeException(String summary) {
  final lower = summary.toLowerCase();
  if (lower.contains('timed out') ||
      lower.contains('429') ||
      lower.contains('quota') ||
      lower.contains('connection') ||
      lower.contains('socket') ||
      lower.contains('tls') ||
      lower.contains('api') ||
      lower.contains('handshake')) {
    return 'blocked_external';
  }
  return 'technical_failure';
}

bool _looksLikeExternalBlockedStatus(String status) {
  final lower = status.trim().toLowerCase();
  if (lower.isEmpty) {
    return false;
  }
  return lower.contains('handshakeexception') ||
      lower.contains('connection terminated during handshake') ||
      lower.contains('socketexception') ||
      lower.contains('tls') ||
      lower.contains('429') ||
      lower.contains('quota') ||
      lower.contains('rate limit') ||
      lower.contains('api');
}

String _fixLog(JsonMap report) {
  final ok = ValueReaders.boolValue(report['ok']);
  return '''
# $_laneId

- status: ${ok ? 'passed' : 'failed'}
- report_category: ${ValueReaders.stringValue(report['report_category'])}
- note: ${ok ? '已形成普通分章续写的真实 GUI/ViewModel 证据。' : '已冻结普通分章续写失败现场，需继续定位生产链。'}
''';
}

String _clip(String text, int maxLength) {
  final cleanText = text.trim();
  if (cleanText.length <= maxLength) {
    return cleanText;
  }
  return '${cleanText.substring(0, maxLength)}...';
}

const String _continuationPrompt = '''
先承接前文已经落定的门后回应，不要回退铺垫，直接把第三章正式写出来。

这是普通项目下的正式分章续写，不是长任务，也不是重新规划开局。

硬要求：
- 直接承接当前项目里第02章章末已经落定的状态。
- 不要重复敲门、重复自报来历、重复把“求借宿”再讲一遍。
- 开头就进入王保正的试探性回应和周砚的应对。
- 生成正式正文并落到 chapters/ 下。
- 正文控制在约 2200 字，允许 1600-2600 字浮动。
''';

const String _continuationFollowUpPrompt = '''
继续按第三章正式续写执行：直接从王保正的回应开始推进，不要回退重演第02章门前动作；保持正文在 1600-2600 字，并形成正式章节交付。
''';
