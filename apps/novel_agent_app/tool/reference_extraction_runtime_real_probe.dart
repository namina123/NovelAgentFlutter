import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import 'probe_support.dart';
import '../../../tools/probe_config_support.dart';

Future<void> main() async {
  await ensureLocalRealProbeOptIn(
    probeName: 'reference_extraction_runtime_real_probe',
  );
  final repoRoot = resolveLocalProbeRepoRoot();
  final apiConfig = await loadProbeApiConfig(
    probeName: 'reference_extraction_runtime_real_probe',
    repoRootOverride: repoRoot,
  );
  final runId =
      Platform.environment['REFERENCE_EXTRACTION_RUNTIME_REAL_PROBE_RUN_ID']
              ?.trim()
              .isNotEmpty ==
          true
      ? Platform.environment['REFERENCE_EXTRACTION_RUNTIME_REAL_PROBE_RUN_ID']!
            .trim()
      : DateTime.now().toIso8601String();
  final workspaceRoot = buildProbeWorkspaceDirectory(
    repoRoot: repoRoot,
    probeName: 'reference_extraction_runtime_real_probe',
    runId: runId,
  );
  await workspaceRoot.create(recursive: true);
  final projectRoot = Directory(
    '${workspaceRoot.path}${Platform.pathSeparator}project',
  )..createSync(recursive: true);
  final sourceFile = File(_resolveSourceFilePath(repoRoot)).absolute;
  final report = <String, Object?>{
    'probe_name': 'reference_extraction_runtime_real_probe',
    'run_id': runId,
    'workspace_root': workspaceRoot.path,
    'project_root': projectRoot.path,
    'source_file': sourceFile.path,
    'probe_config_source': apiConfig.sourceLabel,
    'model_id': apiConfig.modelId,
    'started_at': DateTime.now().toIso8601String(),
  };

  try {
    if (!sourceFile.existsSync()) {
      throw StateError('Source file missing: ${sourceFile.path}');
    }
    final provider = ProviderEndpointSettings(
      id: 'reference_extraction_runtime_real_probe',
      title: 'Reference Extraction Runtime Real Probe',
      protocol: 'openai_compatible',
      baseUrl: apiConfig.baseUrl,
      apiKey: apiConfig.apiKey,
      modelId: apiConfig.modelId,
      description: 'Local real provider config for runtime extraction probe.',
      isDefault: true,
    );
    final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
    final project = ProjectDescriptor(
      id: 'reference_extraction_runtime_real_probe_project',
      name: '参考提取 runtime 真实探针项目',
      rootPath: projectRoot.path,
      projectType: 'novel',
    );
    final runtimeService = ProjectReferenceExtractionRuntimeService(
      workspacePort: bundle.projectWorkspacePort,
      loadAvailableAgents: (project) =>
          bundle.agentPackageCatalog.loadAgentPackages(project),
      loadAvailableGroups: (project) =>
          bundle.agentGroupCatalog.loadAgentGroups(project),
      groupBindingRepository: bundle.projectAgentGroupBindingRepository,
    );
    final runtimeProfile = _resolveRuntimeProfile();
    final request = const ProjectReferenceExtractionRequestBuilderService().build(
      ProjectReferenceExtractionRequestInput(
        sourceFilePath: sourceFile.path,
        packageId: '',
        displayName: '',
        packageVersionId: '',
        versionLabel: '',
        sourceLanguage: '',
        targetLanguage: 'zh-CN',
        maxChapterEntries: 6,
        maxEntityEntries: 6,
        exportBundle: true,
        attachToProject: true,
        projectMountedEntries: true,
        bundleOutputDirectory:
            '${workspaceRoot.path}${Platform.pathSeparator}bundle',
        strategyProfileId: _resolveStrategyProfileId(),
        availableContextChars: runtimeProfile,
      ),
    );
    final gateway = bundle.createGateway(provider);
    final result = await runtimeService.execute(
      project: project,
      llmGateway: gateway,
      modelId: apiConfig.modelId,
      request: request,
    );
    final sqliteDbPath =
        '${projectRoot.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}sqlite${Platform.pathSeparator}novel_agent.db';
    final sqliteDbFile = File(sqliteDbPath);
    final projectionPaths = result.generatedProjectionPaths;
    final projectionChecks = <String, bool>{
      for (final path in projectionPaths)
        path: await _exists(projectRoot, path),
    };
    final stagingIdentitySample = await _extractSourceIdentitySample(
      result.stagingRunPath,
    );
    final stagingText = result.stagingRunPath.trim().isEmpty
        ? ''
        : await File(result.stagingRunPath).readAsString();

    report['ok'] = true;
    report['runtime_result'] = _runtimeResultJson(result);
    report['sqlite_checks'] = <String, Object?>{
      'db_path': sqliteDbPath,
      'db_exists': await sqliteDbFile.exists(),
    };
    report['projection_checks'] = <String, Object?>{
      'generated_projection_paths': projectionPaths,
      'generated_projection_exists': projectionChecks,
    };
    report['project_entry_roots'] = await _projectEntryRoots(
      bundle.projectWorkspacePort,
      project,
    );
    report['source_identity_sample'] = stagingIdentitySample;
    report['fact_anchor_hits'] = <String, Object?>{
      'common': _termHits(stagingText, _commonFactAnchors),
      'tricky': _termHits(stagingText, _trickyFactAnchors),
    };
  } catch (error, stackTrace) {
    report['ok'] = false;
    report['error'] = '$error';
    report['stack_trace'] = '$stackTrace';
  } finally {
    report['finished_at'] = DateTime.now().toIso8601String();
    final reportFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}reference_extraction_runtime_real_probe_report.json',
    );
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    final markdownFile = File(
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}reference_extraction_runtime_real_probe_report.md',
    );
    await markdownFile.writeAsString(_reportMarkdown(report));
    stdout.writeln('report: ${reportFile.path}');
    stdout.writeln(ValueReaders.boolValue(report['ok']) ? 'PASS' : 'FAIL');
    if (!ValueReaders.boolValue(report['ok'])) {
      exitCode = 1;
    }
  }
}

const List<String> _commonFactAnchors = <String>[
  '哈利',
  '德思礼',
  '海格',
  '对角巷',
  '女贞路',
];

const List<String> _trickyFactAnchors = <String>[
  '分院帽',
  '古灵阁',
  '奇洛',
  '麦格',
  '伏地魔',
  '尼可勒梅',
  '厄里斯魔镜',
  '魁地奇',
  '斯莱特林',
  '格兰芬多',
];

String _resolveSourceFilePath(String repoRoot) {
  final override = Platform.environment['REFERENCE_EXTRACTION_SOURCE_FILE'];
  if (override != null && override.trim().isNotEmpty) {
    return override.trim();
  }
  return '$repoRoot${Platform.pathSeparator}references${Platform.pathSeparator}files${Platform.pathSeparator}Harry Potter - Volume 1 Raw.txt';
}

String _resolveStrategyProfileId() {
  final raw = Platform.environment['REFERENCE_EXTRACTION_STRATEGY_PROFILE_ID'];
  return (raw ?? '').trim();
}

int _resolveRuntimeProfile() {
  final raw =
      Platform.environment['REFERENCE_EXTRACTION_AVAILABLE_CONTEXT_CHARS'];
  final parsed = int.tryParse((raw ?? '').trim());
  if (parsed != null && parsed > 0) {
    return parsed;
  }
  return 131072;
}

Map<String, Object?> _runtimeResultJson(ProjectReferenceExtractionResult result) {
  return <String, Object?>{
    'run_id': result.runId,
    'package_id': result.packageId,
    'package_version_id': result.packageVersionId,
    'source_file_path': result.sourceFilePath,
    'source_decode_mode': result.sourceDecodeMode,
    'group_resolution_kind': result.groupResolutionKind,
    'selected_group_id': result.selectedGroupId,
    'strategy_profile_id': result.strategyProfileId,
    'execution_concurrency_mode': result.executionConcurrencyMode,
    'proposal_count': result.proposalCount,
    'accepted_proposal_count': result.acceptedProposalCount,
    'finalized_entry_count': result.finalizedEntryCount,
    'batch_count': result.batchCount,
    'batch_coverage_ratio': result.batchCoverageRatio,
    'batch_planning_mode': result.batchPlanningMode,
    'batch_goal_kind': result.batchGoalKind,
    'batch_structure_mode': result.batchStructureMode,
    'completed_batch_count': result.completedBatchCount,
    'failed_batch_count': result.failedBatchCount,
    'pending_batch_count': result.pendingBatchCount,
    'run_status': result.runStatus,
    'delivery_status': result.deliveryStatus,
    'delivery_rationale': result.deliveryRationale,
    'output_completion_status': result.outputCompletionStatus,
    'output_compression_risk_level': result.outputCompressionRiskLevel,
    'needs_continuation': result.needsContinuation,
    'omission_report_count': result.omissionReportCount,
    'continuation_request_count': result.continuationRequestCount,
    'covered_coverage_dimension_ids': result.coveredCoverageDimensionIds,
    'uncovered_coverage_dimension_ids': result.uncoveredCoverageDimensionIds,
    'followup_segment_ids': result.followupSegmentIds,
    'coverage_requires_followup': result.coverageRequiresFollowup,
    'attach_to_project_requested': result.attachToProjectRequested,
    'project_mounted_entries_requested': result.projectMountedEntriesRequested,
    'project_mount_status': result.projectMountStatus,
    'project_mount_warning_codes': result.projectMountWarningCodes,
    'bundle_output_directory': result.bundleOutputDirectory,
    'staging_run_path': result.stagingRunPath,
    'generated_projection_paths': result.generatedProjectionPaths,
    'knowledge_card_ids': result.knowledgeCardIds,
    'design_element_ids': result.designElementIds,
    'research_note_ids': result.researchNoteIds,
    'reference_work_ids': result.referenceWorkIds,
  };
}

Future<Map<String, Object?>> _extractSourceIdentitySample(String stagingPath) async {
  if (stagingPath.trim().isEmpty) {
    return const <String, Object?>{};
  }
  final file = File(stagingPath);
  if (!await file.exists()) {
    return const <String, Object?>{};
  }
  final decoded = jsonDecode(await file.readAsString());
  final sample = _findFirstIdentityMap(decoded);
  return sample ?? const <String, Object?>{};
}

Map<String, Object?>? _findFirstIdentityMap(Object? node) {
  if (node is Map) {
    final map = <String, Object?>{};
    for (final entry in node.entries) {
      if (entry.key is String) {
        map[entry.key as String] = entry.value;
      }
    }
    if (map.containsKey('source_asset_id') &&
        map.containsKey('display_name') &&
        map.containsKey('resolver_uri')) {
      return <String, Object?>{
        'source_asset_id': ValueReaders.stringValue(map['source_asset_id']),
        'display_name': ValueReaders.stringValue(map['display_name']),
        'resolver_uri': ValueReaders.stringValue(map['resolver_uri']),
        'local_hint_path': ValueReaders.stringValue(map['local_hint_path']),
      };
    }
    for (final value in map.values) {
      final nested = _findFirstIdentityMap(value);
      if (nested != null) {
        return nested;
      }
    }
    return null;
  }
  if (node is List) {
    for (final item in node) {
      final nested = _findFirstIdentityMap(item);
      if (nested != null) {
        return nested;
      }
    }
  }
  return null;
}

Map<String, bool> _termHits(String text, List<String> terms) {
  return <String, bool>{
    for (final term in terms) term: text.contains(term),
  };
}

Future<bool> _exists(Directory projectRoot, String relativePath) async {
  final path = relativePath.replaceAll('/', Platform.pathSeparator);
  final file = File('${projectRoot.path}${Platform.pathSeparator}$path');
  return file.exists();
}

Future<List<String>> _projectEntryRoots(
  ProjectWorkspacePort workspacePort,
  ProjectDescriptor project,
) async {
  final entries = await workspacePort.listEntries(project.rootPath, recursive: true);
  final roots = <String>{};
  for (final entry in entries) {
    final relativePath = ValueReaders.stringValue(entry['relative_path']).trim();
    if (relativePath.isEmpty) {
      continue;
    }
    roots.add(relativePath.split('/').first);
  }
  final ordered = roots.toList(growable: false)..sort();
  return ordered;
}

String _reportMarkdown(Map<String, Object?> report) {
  final ok = ValueReaders.boolValue(report['ok']);
  final runtimeResult = ValueReaders.mapValue(report['runtime_result']);
  final sqliteChecks = ValueReaders.mapValue(report['sqlite_checks']);
  final sourceIdentity = ValueReaders.mapValue(report['source_identity_sample']);
  final lines = <String>[
    '# 参考提取 runtime 真实探针报告',
    '',
    '- 结果：${ok ? 'PASS' : 'FAIL'}',
    '- 源文件：${ValueReaders.stringValue(report['source_file'])}',
    '- 工作区：${ValueReaders.stringValue(report['workspace_root'])}',
    '- 项目目录：${ValueReaders.stringValue(report['project_root'])}',
    '- 配置来源：${ValueReaders.stringValue(report['probe_config_source'])}',
    '- 模型：${ValueReaders.stringValue(report['model_id'])}',
  ];
  if (ok) {
    lines.addAll(<String>[
      '- 组选路：${ValueReaders.stringValue(runtimeResult['group_resolution_kind'])}',
      '- 选中组：${ValueReaders.stringValue(runtimeResult['selected_group_id'])}',
      '- 候选提案：${ValueReaders.intValue(runtimeResult['proposal_count'])}',
      '- 正式接纳：${ValueReaders.intValue(runtimeResult['accepted_proposal_count'])}',
      '- 最终条目：${ValueReaders.intValue(runtimeResult['finalized_entry_count'])}',
      '- 交付状态：${ValueReaders.stringValue(runtimeResult['delivery_status'])}',
      '- 完整性状态：${ValueReaders.stringValue(runtimeResult['output_completion_status'])}',
      '- 压缩风险：${ValueReaders.stringValue(runtimeResult['output_compression_risk_level'])}',
      '- 挂载状态：${ValueReaders.stringValue(runtimeResult['project_mount_status'])}',
      '- SQLite：${ValueReaders.boolValue(sqliteChecks['db_exists'])}',
      '- 来源样本：${ValueReaders.stringValue(sourceIdentity['display_name'])}｜${ValueReaders.stringValue(sourceIdentity['source_asset_id'])}',
    ]);
  } else {
    lines.add('- 错误：${ValueReaders.stringValue(report['error'])}');
  }
  lines.add('');
  return '${lines.join('\n')}\n';
}
