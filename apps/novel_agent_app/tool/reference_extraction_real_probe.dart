import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';
import '../../../tools/probe_config_support.dart';

Future<void> main() async {
  await ensureLocalRealProbeOptIn(probeName: 'reference_extraction_real_probe');
  final repoRoot = resolveLocalProbeRepoRoot();
  final apiConfig = await loadProbeApiConfig(
    probeName: 'reference_extraction_real_probe',
    repoRootOverride: repoRoot,
  );
  final runId =
      Platform.environment['REFERENCE_EXTRACTION_PROBE_RUN_ID']
              ?.trim()
              .isNotEmpty ==
          true
      ? Platform.environment['REFERENCE_EXTRACTION_PROBE_RUN_ID']!.trim()
      : DateTime.now().toIso8601String();
  final workspaceRoot = buildProbeWorkspaceDirectory(
    repoRoot: repoRoot,
    probeName: 'reference_extraction_real_probe',
    runId: runId,
  );
  await workspaceRoot.create(recursive: true);
  final substrateRoot = Directory(
    '${workspaceRoot.path}${Platform.pathSeparator}substrate',
  )..createSync(recursive: true);
  final bundleRoot = Directory(
    '${workspaceRoot.path}${Platform.pathSeparator}bundle',
  );

  final sourceFile = File(_resolveSourceFilePath(repoRoot)).absolute;
  final report = <String, Object?>{
    'probe_name': 'reference_extraction_real_probe',
    'run_id': runId,
    'workspace_root': workspaceRoot.path,
    'source_file': sourceFile.path,
    'probe_config_source': apiConfig.sourceLabel,
    'model_id': apiConfig.modelId,
    'started_at': DateTime.now().toIso8601String(),
  };

  try {
    if (!sourceFile.existsSync()) {
      throw StateError('Source file missing: ${sourceFile.path}');
    }
    const sourceReader = ReferenceSourceDocumentFileReaderService();
    const sourceLanguageHintService = ReferenceSourceLanguageHintService();
    final sourceDocument = await sourceReader.read(
      sourceFilePath: sourceFile.path,
    );
    report['source_decode_mode'] = sourceDocument.decodeMode;
    final sourceTitle = sourceDocument.sourceTitle;
    final sourceStem = _sourceStem(sourceTitle);
    final runtimeRunId =
        Platform.environment['REFERENCE_EXTRACTION_RUNTIME_RUN_ID']
                ?.trim()
                .isNotEmpty ==
            true
        ? Platform.environment['REFERENCE_EXTRACTION_RUNTIME_RUN_ID']!.trim()
        : 'reference_extraction_real_${_safeIdentifier(sourceStem)}';
    final provider = ProviderEndpointSettings(
      id: 'reference_extraction_real_probe',
      title: 'Reference Extraction Real Probe',
      protocol: 'openai_compatible',
      baseUrl: apiConfig.baseUrl,
      apiKey: apiConfig.apiKey,
      modelId: apiConfig.modelId,
      description: 'Local real provider config for reference extraction probe.',
      isDefault: true,
    );
    final gateway = AdapterBundle.standard(
      workingDirectoryPath: repoRoot,
    ).createGateway(provider);
    final substrate = SqliteReferenceEvidenceSubstrate(
      substrateRootPath: substrateRoot.path,
    );
    final stagingWorkspace = FileReferenceExtractionStagingWorkspace(
      stagingRootPath:
          '${workspaceRoot.path}${Platform.pathSeparator}staging_workspace',
    );
    final proposalGenerator = _RealReferenceExtractionProposalGenerator(
      gateway: gateway,
      modelId: apiConfig.modelId,
    );
    final useCase = ExecuteReferenceExtractionFromSourceDocumentUseCase(
      substrate: substrate,
      stagingWorkspace: stagingWorkspace,
      proposalGenerator: proposalGenerator,
    );

    final writerProfile = _agentProfile(
      id: 'writer_default',
      name: '默认作者',
      role: '普通项目写作主智能体。',
    );
    final extractorProfile = _agentProfile(
      id: 'reference_extractor',
      name: '参考资产提取师',
      role: '负责参考资产提取、证据归档与知识候选整理。',
    );
    final writingGroup = _group(
      id: 'writing_room',
      name: '普通写作组',
      primaryProfile: writerProfile,
      metadata: const <String, Object?>{},
    );
    final extractionGroup = _group(
      id: 'reference_extraction_room',
      name: '参考资产提取组',
      primaryProfile: extractorProfile,
      metadata: <String, Object?>{
        'task_family_ids': <String>[AgentTaskFamilies.referenceExtraction],
      },
    );

    final request = ReferenceExtractionRunRequest(
      runId: runtimeRunId,
      sourceDocumentRequest: ReferenceSourceDocumentIngestionRequest(
        sourceText: sourceDocument.sourceText,
        sourceTitle: sourceTitle,
        sourceRef: sourceFile.path,
        packageId: 'reference_probe_${_safeIdentifier(sourceStem)}',
        packageKind: ReferencePackageKinds.referenceWorkPackage,
        displayName: '参考资产提取真实探针：$sourceTitle',
        packageVersionId: 'seed_${_safeIdentifier(sourceStem)}',
        versionLabel: 'seed-bootstrap',
        createdAt: DateTime.now().toIso8601String(),
        createdBy: 'reference_extraction_real_probe',
        sourceLanguage: sourceLanguageHintService.infer(
          sourceFilePath: sourceFile.path,
          sourceTitle: sourceTitle,
          sourceText: sourceDocument.sourceText,
        ),
        targetLanguage: 'zh-CN',
        maxChapterEntries: 5,
        maxEntityEntries: 5,
      ),
      finalizedAt: DateTime.now().toIso8601String(),
      finalizedBy: 'reference_extraction_real_probe',
      finalizedPackageVersionId: 'final_${_safeIdentifier(sourceStem)}',
      finalizedVersionLabel: 'real-agent-finalized',
      strategyProfileId: _resolveStrategyProfileId(),
      availableContextChars: _resolveAvailableContextChars(),
      groupSelections: <ProjectAgentGroupSelection>[
        const ProjectAgentGroupSelection(
          groupId: 'writing_room',
          displayName: '普通写作组',
          selectedByDefault: true,
        ),
        const ProjectAgentGroupSelection(
          groupId: 'reference_extraction_room',
          displayName: '参考资产提取组',
          selectedByDefault: true,
          taskFamilyIds: <String>[AgentTaskFamilies.referenceExtraction],
        ),
      ],
      groupAssessments: <AgentGroupAvailabilityAssessment>[
        AgentGroupAvailabilityAssessment(
          group: writingGroup,
          isSupported: true,
          isDegraded: false,
          supportedMembers: writingGroup.members,
        ),
        AgentGroupAvailabilityAssessment(
          group: extractionGroup,
          isSupported: true,
          isDegraded: false,
          supportedMembers: extractionGroup.members,
        ),
      ],
      agentAssessments: <AgentAvailabilityAssessment>[
        AgentAvailabilityAssessment(profile: writerProfile, isSupported: true),
        AgentAvailabilityAssessment(
          profile: extractorProfile,
          isSupported: true,
        ),
      ],
    );

    final result = await useCase.execute(request);
    final finalizedSnapshot = result.finalizedSnapshot;
    String snapshotPath = '';
    if (finalizedSnapshot != null) {
      final exportService = ReferenceBundleExportService(substrate: substrate);
      await exportService.exportToDirectory(
        bundleRoot.path,
        ReferenceBundleExportRequest(
          packageId: finalizedSnapshot.packageRecord.packageId,
          packageVersionId:
              finalizedSnapshot.packageVersionRecord.packageVersionId,
          bundleId:
              '${finalizedSnapshot.packageRecord.packageId}_${finalizedSnapshot.packageVersionRecord.packageVersionId}',
          createdAt: DateTime.now().toIso8601String(),
          createdBy: 'reference_extraction_real_probe',
        ),
      );
      final snapshotFile = File(
        '${workspaceRoot.path}${Platform.pathSeparator}finalized_snapshot.json',
      );
      await snapshotFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(finalizedSnapshot.toJson()),
      );
      snapshotPath = snapshotFile.path;
    }
    final stagingFile = File(
      '${workspaceRoot.path}${Platform.pathSeparator}staging_summary.json',
    );
    await stagingFile.writeAsString(
      const JsonEncoder.withIndent(
        '  ',
      ).convert(_stagingSummary(result.stagingRun, result.reviewOutcome)),
    );

    final decisionCounts = <String, int>{};
    for (final decision in result.reviewOutcome.decisions) {
      decisionCounts[decision.disposition] =
          (decisionCounts[decision.disposition] ?? 0) + 1;
    }

    report['ok'] = true;
    report['runtime_run_id'] = runtimeRunId;
    report['strategy_profile_id'] = _resolveStrategyProfileId();
    report['available_context_chars'] = _resolveAvailableContextChars();
    report['group_resolution_kind'] = result.groupResolution.resolutionKind;
    report['selected_group_id'] = result.groupResolution.selectedGroup.id;
    report['execution_mode'] =
        result.groupResolution.executionProfile.executionMode;
    report['instruction_profile_id'] =
        result.groupResolution.executionProfile.instructionProfileId;
    report['tool_permission_profile_id'] =
        result.groupResolution.executionProfile.toolPermissionProfileId;
    report['phase_records'] = result.stagingRun.phaseRecords
        .map(
          (record) => <String, Object?>{
            'phase_id': record.phaseId,
            'detail': record.detail,
          },
        )
        .toList(growable: false);
    report['proposal_count'] = result.stagingRun.proposals.length;
    report['review_decision_counts'] = decisionCounts;
    report['accepted_proposal_ids'] = result.reviewOutcome.acceptedProposalIds;
    report['delivery_status'] = result.deliveryDecision.deliveryStatus;
    report['delivery_rationale'] = result.deliveryDecision.rationale;
    report['output_completion_status'] =
        result.reviewOutcome.outputCompletionStatus;
    report['seed_entry_count'] = result.seedResult.generatedEntryCount;
    report['finalized_entry_count'] = finalizedSnapshot?.entries.length ?? 0;
    report['finalized_entry_titles'] =
        finalizedSnapshot?.entries
            .map((entry) => entry.title)
            .toList(growable: false) ??
        const <String>[];
    report['bundle_output_directory'] = finalizedSnapshot == null
        ? ''
        : bundleRoot.path;
    report['summary_projection_path'] = finalizedSnapshot == null
        ? ''
        : '${bundleRoot.path}${Platform.pathSeparator}projections${Platform.pathSeparator}summary.md';
    report['snapshot_path'] = snapshotPath;
    report['staging_summary_path'] = stagingFile.path;
  } catch (error, stackTrace) {
    report['ok'] = false;
    report['error'] = '$error';
    report['stack_trace'] = '$stackTrace';
  } finally {
    report['finished_at'] = DateTime.now().toIso8601String();
    final reportFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}reference_extraction_real_probe_report.json',
    );
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    final markdownFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}reference_extraction_real_probe_report.md',
    );
    await markdownFile.writeAsString(_reportMarkdown(report));
    stdout.writeln('report: ${reportFile.path}');
    stdout.writeln(ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL');
    if (!ValueReaders.boolValue(report['ok'])) {
      exitCode = 1;
    }
  }
}

String _resolveSourceFilePath(String repoRoot) {
  final override = Platform.environment['REFERENCE_EXTRACTION_SOURCE_FILE'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }
  return '$repoRoot${Platform.pathSeparator}references${Platform.pathSeparator}files${Platform.pathSeparator}Harry Potter - Volume 1 Raw.txt';
}

String _sourceStem(String sourceTitle) {
  final dotIndex = sourceTitle.lastIndexOf('.');
  return dotIndex > 0 ? sourceTitle.substring(0, dotIndex) : sourceTitle;
}

String _safeIdentifier(String value) {
  final normalized = value
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return normalized.isEmpty ? 'reference_source' : normalized.toLowerCase();
}

int _resolveAvailableContextChars() {
  final raw =
      Platform.environment['REFERENCE_EXTRACTION_AVAILABLE_CONTEXT_CHARS'];
  final parsed = int.tryParse((raw ?? '').trim());
  if (parsed != null && parsed > 0) {
    return parsed;
  }
  return 131072;
}

String _resolveStrategyProfileId() {
  final raw = Platform.environment['REFERENCE_EXTRACTION_STRATEGY_PROFILE_ID'];
  return (raw ?? '').trim();
}

AgentProfile _agentProfile({
  required String id,
  required String name,
  required String role,
}) {
  return AgentProfile(
    id: id,
    name: name,
    description: role,
    role: role,
    source: 'probe',
  );
}

ResolvedAgentGroupProfile _group({
  required String id,
  required String name,
  required AgentProfile primaryProfile,
  required Map<String, Object?> metadata,
}) {
  return ResolvedAgentGroupProfile(
    id: id,
    name: name,
    description: name,
    orchestration: 'supervised',
    members: <ResolvedAgentGroupMemberProfile>[
      ResolvedAgentGroupMemberProfile(
        profile: primaryProfile,
        isPrimary: true,
        isRequired: true,
      ),
    ],
    source: 'probe',
    metadata: metadata,
  );
}

Map<String, Object?> _stagingSummary(
  ReferenceExtractionStagingRun run,
  ReferenceExtractionReviewOutcome reviewOutcome,
) {
  return <String, Object?>{
    'run_id': run.runId,
    'package_id': run.packageId,
    'package_version_id': run.packageVersionId,
    'source_document_title': run.sourceDocumentTitle,
    'source_language': run.sourceLanguage,
    'target_language': run.targetLanguage,
    'group_resolution_kind': run.groupResolution.resolutionKind,
    'selected_group_id': run.groupResolution.selectedGroup.id,
    'execution_mode': run.groupResolution.executionProfile.executionMode,
    'proposal_count': run.proposals.length,
    'review_decisions': reviewOutcome.decisions
        .map(
          (decision) => <String, Object?>{
            'proposal_id': decision.proposalId,
            'disposition': decision.disposition,
            'rationale': decision.rationale,
          },
        )
        .toList(growable: false),
    'phase_records': run.phaseRecords
        .map(
          (record) => <String, Object?>{
            'phase_id': record.phaseId,
            'detail': record.detail,
          },
        )
        .toList(growable: false),
  };
}

String _reportMarkdown(Map<String, Object?> report) {
  final ok = ValueReaders.boolValue(report['ok']);
  final lines = <String>[
    '# 参考资产提取真实探针报告',
    '',
    '- 结果：${ok ? 'PASS' : 'FAIL'}',
    '- 源文件：${ValueReaders.stringValue(report['source_file'])}',
    '- 工作区：${ValueReaders.stringValue(report['workspace_root'])}',
    '- 配置来源：${ValueReaders.stringValue(report['probe_config_source'])}',
    '- 模型：${ValueReaders.stringValue(report['model_id'])}',
  ];
  if (ok) {
    lines.addAll(<String>[
      '- 解析结果：${ValueReaders.stringValue(report['group_resolution_kind'])}',
      '- 选中组：${ValueReaders.stringValue(report['selected_group_id'])}',
      '- 执行模式：${ValueReaders.stringValue(report['execution_mode'])}',
      '- 候选数：${ValueReaders.intValue(report['proposal_count'])}',
      '- 最终条目数：${ValueReaders.intValue(report['finalized_entry_count'])}',
      '- Bundle：${ValueReaders.stringValue(report['bundle_output_directory'])}',
      '- Summary：${ValueReaders.stringValue(report['summary_projection_path'])}',
      '- Snapshot：${ValueReaders.stringValue(report['snapshot_path'])}',
      '- Staging：${ValueReaders.stringValue(report['staging_summary_path'])}',
    ]);
  } else {
    lines.add('- 错误：${ValueReaders.stringValue(report['error'])}');
  }
  lines.add('');
  return '${lines.join('\n')}\n';
}

class _RealReferenceExtractionProposalGenerator
    implements ReferenceExtractionProposalGenerator {
  _RealReferenceExtractionProposalGenerator({
    required LlmGateway gateway,
    required String modelId,
  }) : _gateway = gateway,
       _modelId = modelId;

  final LlmGateway _gateway;
  final String _modelId;

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    final seedEntries = request.seedSnapshot.entries
        .take(10)
        .map(
          (entry) => <String, Object?>{
            'entry_id': entry.entryId,
            'entry_kind': entry.entryKind,
            'title': entry.title,
            'summary': entry.summary,
            'tags': entry.tags,
            'payload': entry.payload,
          },
        )
        .toList(growable: false);
    final prompt =
        '''
你正在执行 NovelAgent 的 reference_extraction.proposal_generation 阶段。

任务：
基于给定的 seed entries，为《${request.sourceDocumentTitle}》生成 4 到 6 条参考资产提取候选。

要求：
1. 只返回 JSON 数组，不要 markdown，不要解释。
2. 每个对象字段必须包含：
   - proposal_id
   - entry_id
   - entry_namespace
   - entry_kind
   - title
   - summary
   - seed_entry_ids
   - tags
   - confidence
3. entry_kind 只允许：
   - knowledge_fact
   - design_element
   - style_technique
   - reference_work_boundary
4. title、summary 必须用中文。
5. seed_entry_ids 必须引用下面给出的 entry_id，至少 1 个，最好 2 个以上。
6. confidence 用 0 到 1 的小数。只有你认为证据很稳时，才允许 >= 0.80。
7. 不要编造 seed 里不存在的具体剧情细节。
8. 优先提取：
   - 角色/世界事实
   - 命名与象征线索
   - 风格/叙事手法
   - 原作边界提醒

source_language=${request.sourceLanguage}
target_language=${request.targetLanguage}
selected_group=${request.groupResolution.selectedGroup.id}
instruction_profile=${request.groupResolution.executionProfile.instructionProfileId}

seed_entries=
${const JsonEncoder.withIndent('  ').convert(seedEntries)}
''';

    final result = await _gateway.requestChat(
      request: ChatRequest.textPrompt(
        prompt: prompt,
        modelId: _modelId,
        options: const <String, Object?>{'stream': false, 'temperature': 0.3},
      ),
    );
    final content = ValueReaders.stringValue(result['content']);
    final decoded = _decodeJsonArray(content);
    final seedEntryById = <String, ReferenceEntryRecord>{
      for (final entry in request.seedSnapshot.entries) entry.entryId: entry,
    };
    final proposals = <ReferenceExtractionProposal>[];
    for (final rawItem in decoded) {
      final item = ValueReaders.mapValue(rawItem);
      if (item.isEmpty) {
        continue;
      }
      final referencedSeedIds = ValueReaders.stringList(
        item['seed_entry_ids'],
      ).where(seedEntryById.containsKey).toList(growable: false);
      final sourceRefs = <InformationSourceRef>[];
      final evidenceRefs = <NarrativeEvidenceRef>[];
      for (final seedId in referencedSeedIds) {
        final entry = seedEntryById[seedId];
        if (entry == null) {
          continue;
        }
        sourceRefs.addAll(entry.sourceRefs);
        evidenceRefs.addAll(entry.evidenceRefs);
      }
      proposals.add(
        ReferenceExtractionProposal(
          proposalId: ValueReaders.stringValue(item['proposal_id']),
          entryId: ValueReaders.stringValue(item['entry_id']),
          entryNamespace: ValueReaders.stringValue(
            item['entry_namespace'],
            'semantic_extraction',
          ),
          entryKind: ValueReaders.stringValue(item['entry_kind']),
          title: ValueReaders.stringValue(item['title']),
          summary: ValueReaders.stringValue(item['summary']),
          payload: <String, Object?>{
            'seed_entry_ids': referencedSeedIds,
            'generated_by': 'real_reference_extraction_probe',
          },
          sourceRefs: sourceRefs,
          evidenceRefs: evidenceRefs,
          tags: ValueReaders.stringList(item['tags']),
          confidence: _doubleValue(item['confidence']),
          metadata: <String, Object?>{
            'selected_group_id': request.groupResolution.selectedGroup.id,
          },
        ),
      );
    }
    return ReferenceExtractionProposalGenerationResult(
      proposals: List<ReferenceExtractionProposal>.unmodifiable(proposals),
    );
  }

  List<Object?> _decodeJsonArray(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw StateError('Model returned empty proposal content.');
    }
    final fencedMatch = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
    ).firstMatch(trimmed);
    final candidate = fencedMatch == null
        ? trimmed
        : fencedMatch.group(1)!.trim();
    final start = candidate.indexOf('[');
    final end = candidate.lastIndexOf(']');
    if (start < 0 || end < start) {
      throw StateError('Model did not return a JSON array: $trimmed');
    }
    final jsonText = candidate.substring(start, end + 1);
    final decoded = jsonDecode(jsonText);
    if (decoded is! List) {
      throw StateError('Decoded proposals are not a list.');
    }
    return List<Object?>.from(decoded);
  }

  double _doubleValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(ValueReaders.stringValue(value)) ?? 0;
  }
}
