import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/project_assets/application/controllers/project_assets_controller.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_loader_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_workspace_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_reference_extraction_execution_service.dart';
import 'package:novel_agent_app/shared/services/desktop_text_file_picker_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../tools/probe_config_support.dart';
import '../tool/probe_support.dart';

void main() {
  HttpOverrides.global = null;

  test(
    'real GUI reference extraction probe validates controller-driven extraction and structure',
    () async {
      final repoRoot = resolveLocalProbeRepoRoot();
      final report = <String, Object?>{
        'probe_name': 'real_gui_reference_extraction_probe',
        'started_at': DateTime.now().toIso8601String(),
      };
      try {
        await ensureLocalRealProbeOptIn(
          probeName: 'real_gui_reference_extraction_probe',
        );
        final apiConfig = await loadProbeApiConfig(
          probeName: 'real_gui_reference_extraction_probe',
          repoRootOverride: repoRoot,
        );
        final runId = DateTime.now().toIso8601String();
        final workspaceRoot = buildProbeWorkspaceDirectory(
          repoRoot: repoRoot,
          probeName: 'real_gui_reference_extraction_probe',
          runId: runId,
        );
        await workspaceRoot.create(recursive: true);
        final projectRoot = Directory(
          '${workspaceRoot.path}${Platform.pathSeparator}project',
        )..createSync(recursive: true);
        final sourceFile = File(
          '$repoRoot${Platform.pathSeparator}references${Platform.pathSeparator}files${Platform.pathSeparator}Harry Potter - Volume 1 Raw.txt',
        );
        if (!sourceFile.existsSync()) {
          throw StateError('Source file missing: ${sourceFile.path}');
        }

        report['run_id'] = runId;
        report['workspace_root'] = workspaceRoot.path;
        report['project_root'] = projectRoot.path;
        report['source_file'] = sourceFile.path;
        report['probe_config_source'] = apiConfig.sourceLabel;
        report['model_id'] = apiConfig.modelId;

        final bundle = AdapterBundle.standard(workingDirectoryPath: repoRoot);
        final provider = ProviderEndpointSettings(
          id: 'real_gui_reference_extraction_probe',
          title: 'GUI Reference Extraction Probe',
          protocol: 'openai_compatible',
          baseUrl: apiConfig.baseUrl,
          apiKey: apiConfig.apiKey,
          modelId: apiConfig.modelId,
          description:
              'Local real provider config for GUI reference extraction probe.',
          isDefault: true,
        );
        final settings = AppSettings(
          defaultProviderId: provider.id,
          defaultAgentId: 'default_generalist',
          defaultModelId: apiConfig.modelId,
          defaultProjectPath: projectRoot.path,
          autoSaveDrafts: false,
          providers: <ProviderEndpointSettings>[provider],
        );
        final project = ProjectDescriptor(
          id: 'real_gui_reference_extraction_probe_project',
          name: 'GUI 参考提取探针项目',
          rootPath: projectRoot.path,
          projectType: 'novel',
        );

        final expressionConstraintProfileRepository =
            ExpressionConstraintProfileRepository(
              workspacePort: bundle.projectWorkspacePort,
            );
        final projectExpressionConstraintBindingRepository =
            ProjectExpressionConstraintBindingRepository(
              workspacePort: bundle.projectWorkspacePort,
            );
        final expressionConstraintWorkspaceService =
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  expressionConstraintProfileRepository.loadProfiles(
                    project,
                    includeBuiltins: true,
                  ),
              loadBindings:
                  projectExpressionConstraintBindingRepository.loadBindings,
              saveBindings:
                  projectExpressionConstraintBindingRepository.saveBindings,
            );
        final projectAssetLibraryService = ProjectAssetLibraryService(
          workspacePort: bundle.projectWorkspacePort,
          projectToolHostPort: bundle.projectToolHostPort,
        );
        final loaderService = ProjectAssetsLoaderService(
          projectAssetLibraryService: projectAssetLibraryService,
          timelineRepository: ProjectTimelineRepository(
            hostPort: bundle.projectToolHostPort,
          ),
          relationshipRepository: ProjectRelationshipRepository(
            hostPort: bundle.projectToolHostPort,
          ),
          expressionConstraintWorkspaceService:
              expressionConstraintWorkspaceService,
        );
        final referenceExtractionRuntimeService =
            ProjectReferenceExtractionRuntimeService(
              workspacePort: bundle.projectWorkspacePort,
              loadAvailableAgents: (project) =>
                  bundle.agentPackageCatalog.loadAgentPackages(project),
              loadAvailableGroups: (project) =>
                  bundle.agentGroupCatalog.loadAgentGroups(project),
              groupBindingRepository: bundle.projectAgentGroupBindingRepository,
            );

        final availableAgents = await bundle.agentPackageCatalog
            .loadAgentPackages(project);
        ProjectReferenceExtractionResult? lastRuntimeResult;
        var syncCount = 0;
        List<JsonMap> syncedEntries = const <JsonMap>[];
        final syncedProjectionTexts = <String, String>{};
        final executionService = ProjectReferenceExtractionExecutionService(
          readSettings: () => settings,
          llmGatewayFactory: (provider, networkSettings) =>
              bundle.createGateway(provider, networkSettings: networkSettings),
          executeReferenceExtraction:
              ({
                required project,
                required llmGateway,
                required modelId,
                required request,
              }) async {
                final result = await referenceExtractionRuntimeService.execute(
                  project: project,
                  llmGateway: llmGateway,
                  modelId: modelId,
                  request: request,
                );
                lastRuntimeResult = result;
                return result;
              },
          sourcePickerService: _FixedPickerService(sourceFile.path),
        );

        final controller = ProjectAssetsController(
          projectAssetLibraryService: projectAssetLibraryService,
          expressionConstraintWorkspaceService:
              expressionConstraintWorkspaceService,
          loaderService: loaderService,
          readCurrentProject: () => project,
          readAvailableProjectAgents: () => List<JsonMap>.from(availableAgents),
          syncWorkbenchResources: () async {
            syncCount++;
            syncedEntries = await bundle.projectWorkspacePort.listEntries(
              project.rootPath,
              recursive: true,
            );
            for (final relativePath in _projectionPaths) {
              final text = await bundle.projectWorkspacePort.readTextFile(
                project.rootPath,
                relativePath,
              );
              if ((text ?? '').trim().isNotEmpty) {
                syncedProjectionTexts[relativePath] = text!;
              }
            }
          },
          onBackRequested: () {},
          referenceExtractionExecutionService: executionService,
        );

        await controller.onProjectAssetsExtractReferenceRequested();

        final knowledgeIndexExists = await _exists(
          projectRoot,
          '.novel_agent/information/knowledge_cards/index.json',
        );
        final designIndexExists = await _exists(
          projectRoot,
          '.novel_agent/information/design_elements/index.json',
        );
        final referenceIndexExists = await _exists(
          projectRoot,
          '.novel_agent/information/reference_works/index.json',
        );
        final knowledgeSummaryExists = await _exists(
          projectRoot,
          'knowledge/项目知识摘要.md',
        );
        final designSummaryExists = await _exists(
          projectRoot,
          'knowledge/设计元素摘要.md',
        );
        final researchSummaryExists = await _exists(
          projectRoot,
          'research/资料研究摘要.md',
        );
        final referenceBoundaryExists = await _exists(
          projectRoot,
          'references/引用作品边界.md',
        );

        report['controller_status'] = controller.viewData.status;
        report['controller_is_loading'] = controller.viewData.isLoading;
        report['sync_count'] = syncCount;
        report['synced_entry_count'] = syncedEntries.length;
        report['synced_entry_roots'] = _rootDirectoriesOf(syncedEntries);
        report['synced_projection_paths'] = syncedProjectionTexts.keys.toList(
          growable: false,
        );
        report['runtime_result'] = lastRuntimeResult == null
            ? const <String, Object?>{}
            : <String, Object?>{
                'package_id': lastRuntimeResult!.packageId,
                'package_version_id': lastRuntimeResult!.packageVersionId,
                'group_resolution_kind': lastRuntimeResult!.groupResolutionKind,
                'selected_group_id': lastRuntimeResult!.selectedGroupId,
                'proposal_count': lastRuntimeResult!.proposalCount,
                'accepted_proposal_count':
                    lastRuntimeResult!.acceptedProposalCount,
                'finalized_entry_count': lastRuntimeResult!.finalizedEntryCount,
                'bundle_output_directory':
                    lastRuntimeResult!.bundleOutputDirectory,
                'staging_run_path': lastRuntimeResult!.stagingRunPath,
                'generated_projection_paths':
                    lastRuntimeResult!.generatedProjectionPaths,
              };
        report['projection_checks'] = <String, Object?>{
          'knowledge_summary_exists': knowledgeSummaryExists,
          'design_summary_exists': designSummaryExists,
          'research_summary_exists': researchSummaryExists,
          'reference_boundary_exists': referenceBoundaryExists,
          'knowledge_index_exists': knowledgeIndexExists,
          'design_index_exists': designIndexExists,
          'reference_index_exists': referenceIndexExists,
        };
        report['projection_snippets'] = syncedProjectionTexts.map(
          (path, text) => MapEntry(path, _truncate(text)),
        );

        _ensure(syncCount == 1, 'GUI 控制器链应触发一次工作台资源同步。');
        _ensure(
          controller.viewData.status.contains('参考资料提取完成'),
          '资产页状态应回写提取成功摘要。',
        );
        _ensure(
          knowledgeSummaryExists &&
              designSummaryExists &&
              researchSummaryExists &&
              referenceBoundaryExists,
          '项目级投影文件未完整落盘。',
        );
        _ensure(
          knowledgeIndexExists && designIndexExists && referenceIndexExists,
          '结构化信息索引未完整落盘。',
        );
        _ensure(lastRuntimeResult != null, '共享 runtime 没有返回正式提取结果。');

        report['ok'] = true;
      } catch (error, stackTrace) {
        report['ok'] = false;
        report['error'] = '$error';
        report['stack_trace'] = '$stackTrace';
      } finally {
        report['finished_at'] = DateTime.now().toIso8601String();
        final reportPath = await _writeReport(repoRoot, report);
        if (!ValueReaders.boolValue(report['ok'])) {
          fail('GUI reference extraction probe failed. report: $reportPath');
        }
      }
    },
    timeout: const Timeout(Duration(minutes: 20)),
    skip: !_realProbeEnabled(),
  );
}

const List<String> _projectionPaths = <String>[
  'knowledge/项目知识摘要.md',
  'knowledge/设计元素摘要.md',
  'research/资料研究摘要.md',
  'references/引用作品边界.md',
];

bool _realProbeEnabled() {
  final raw = Platform.environment['NOVEL_AGENT_ENABLE_REAL_PROBES'] ?? '';
  final normalized = raw.trim().toLowerCase();
  return normalized == '1' || normalized == 'true' || normalized == 'yes';
}

Future<String> _writeReport(
  String repoRoot,
  Map<String, Object?> report,
) async {
  final reportPath =
      '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_gui_reference_extraction_probe_report.json';
  final reportFile = File(reportPath);
  await reportFile.parent.create(recursive: true);
  await reportFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(report),
  );
  final markdownFile = File(
    '$repoRoot${Platform.pathSeparator}artifacts${Platform.pathSeparator}real_gui_reference_extraction_probe_report.md',
  );
  await markdownFile.writeAsString(_reportMarkdown(report));
  return reportPath;
}

Future<bool> _exists(Directory projectRoot, String relativePath) async {
  final file = File(
    '${projectRoot.path}${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
  return file.exists();
}

List<String> _rootDirectoriesOf(List<JsonMap> entries) {
  final roots = <String>{};
  for (final entry in entries) {
    final relativePath = ValueReaders.stringValue(
      entry['relative_path'],
    ).trim();
    if (relativePath.isEmpty) {
      continue;
    }
    roots.add(relativePath.split('/').first);
  }
  final ordered = roots.toList(growable: false)..sort();
  return ordered;
}

String _truncate(String value, {int maxLength = 240}) {
  final normalized = value.replaceAll('\r\n', '\n').trim();
  if (normalized.length <= maxLength) {
    return normalized;
  }
  return '${normalized.substring(0, maxLength)}...';
}

String _reportMarkdown(Map<String, Object?> report) {
  final ok = ValueReaders.boolValue(report['ok']);
  final runtimeResult = ValueReaders.mapValue(report['runtime_result']);
  final projectionChecks = ValueReaders.mapValue(report['projection_checks']);
  final lines = <String>[
    '# GUI 参考提取真实探针报告',
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
      '- 控制器状态：${ValueReaders.stringValue(report['controller_status'])}',
      '- 资源同步次数：${ValueReaders.intValue(report['sync_count'])}',
      '- 组选路：${ValueReaders.stringValue(runtimeResult['group_resolution_kind'])}',
      '- 选中组：${ValueReaders.stringValue(runtimeResult['selected_group_id'])}',
      '- 候选提案：${ValueReaders.intValue(runtimeResult['proposal_count'])}',
      '- 正式接纳：${ValueReaders.intValue(runtimeResult['accepted_proposal_count'])}',
      '- 最终条目：${ValueReaders.intValue(runtimeResult['finalized_entry_count'])}',
      '- 资料包：${ValueReaders.stringValue(runtimeResult['package_id'])}@${ValueReaders.stringValue(runtimeResult['package_version_id'])}',
      '- 知识摘要：${ValueReaders.boolValue(projectionChecks['knowledge_summary_exists'])}',
      '- 研究摘要：${ValueReaders.boolValue(projectionChecks['research_summary_exists'])}',
      '- 引用边界：${ValueReaders.boolValue(projectionChecks['reference_boundary_exists'])}',
    ]);
  } else {
    lines.add('- 错误：${ValueReaders.stringValue(report['error'])}');
  }
  lines.add('');
  return '${lines.join('\n')}\n';
}

void _ensure(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

class _FixedPickerService extends DesktopTextFilePickerService {
  const _FixedPickerService(this.selection);

  final String selection;

  @override
  Future<String?> pickSingleFile({required String dialogTitle}) async {
    return selection;
  }
}
