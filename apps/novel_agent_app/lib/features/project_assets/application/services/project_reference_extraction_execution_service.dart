import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import '../../../../shared/services/user_facing_error_humanizer.dart';

import '../../../../shared/services/desktop_text_file_picker_service.dart';
import '../models/project_reference_extraction_execution_result.dart';
import 'project_reference_extraction_source_resolution_service.dart';

typedef ProjectReferenceExtractionGatewayFactory =
    LlmGateway Function(
      ProviderEndpointSettings provider,
      JsonMap networkSettings,
    );
typedef ExecuteProjectReferenceExtraction =
    Future<ProjectReferenceExtractionResult> Function({
      required ProjectDescriptor project,
      required LlmGateway llmGateway,
      required String modelId,
      required ProjectReferenceExtractionRequest request,
    });

class ProjectReferenceExtractionExecutionService {
  ProjectReferenceExtractionExecutionService({
    required AppSettings? Function() readSettings,
    required ProjectReferenceExtractionGatewayFactory llmGatewayFactory,
    required ExecuteProjectReferenceExtraction executeReferenceExtraction,
    DesktopTextFilePickerService? sourcePickerService,
    ModelExecutionProfileService? modelExecutionProfileService,
    ProjectReferenceExtractionRequestBuilderService? requestBuilderService,
    ReferenceExtractionStrategyProfileCatalogService? strategyCatalogService,
    ProjectReferenceExtractionSourceResolutionService? sourceResolutionService,
  }) : _readSettings = readSettings,
       _llmGatewayFactory = llmGatewayFactory,
       _executeReferenceExtraction = executeReferenceExtraction,
       _sourcePickerService =
           sourcePickerService ?? const DesktopTextFilePickerService(),
       _modelExecutionProfileService =
           modelExecutionProfileService ?? ModelExecutionProfileService(),
       _requestBuilderService =
           requestBuilderService ??
           const ProjectReferenceExtractionRequestBuilderService(),
       _strategyCatalogService =
           strategyCatalogService ??
           const ReferenceExtractionStrategyProfileCatalogService(),
       _sourceResolutionService =
           sourceResolutionService ??
           ProjectReferenceExtractionSourceResolutionService(),
       _runCoordinator = ReferenceExtractionRunCoordinator(
         workspacePort: LocalProjectWorkspacePort(),
       );

  final AppSettings? Function() _readSettings;
  final ProjectReferenceExtractionGatewayFactory _llmGatewayFactory;
  final ExecuteProjectReferenceExtraction _executeReferenceExtraction;
  final DesktopTextFilePickerService _sourcePickerService;
  final ModelExecutionProfileService _modelExecutionProfileService;
  final ProjectReferenceExtractionRequestBuilderService _requestBuilderService;
  final ReferenceExtractionStrategyProfileCatalogService
  _strategyCatalogService;
  final ProjectReferenceExtractionSourceResolutionService
  _sourceResolutionService;
  final ReferenceExtractionRunCoordinator _runCoordinator;

  Future<ProjectReferenceExtractionExecutionResult> pickAndExecute({
    required ProjectDescriptor project,
    String strategyProfileId = '',
    String overrideProviderId = '',
    String overrideModelId = '',
    bool analysisOnly = false,
  }) async {
    final resolution = await _sourceResolutionService.resolve(
      project: project,
      pickSourceFile: () =>
          _sourcePickerService.pickSingleFile(dialogTitle: '选择参考源文档'),
    );
    if (!resolution.ok) {
      return ProjectReferenceExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: resolution.statusMessage,
      );
    }
    final result = await execute(
      project: project,
      sourceFilePath: resolution.sourceFilePath,
      strategyProfileId: strategyProfileId,
      overrideProviderId: overrideProviderId,
      overrideModelId: overrideModelId,
      analysisOnly: analysisOnly,
    );
    if (!resolution.usedDeconstructionProjection) {
      return result;
    }
    return result.copyWith(
      statusMessage: result.ok
          ? '${resolution.statusMessage} ${result.statusMessage}'.trim()
          : result.statusMessage,
    );
  }

  Future<ProjectReferenceExtractionExecutionResult> execute({
    required ProjectDescriptor project,
    required String sourceFilePath,
    String strategyProfileId = '',
    String overrideProviderId = '',
    String overrideModelId = '',
    bool analysisOnly = false,
  }) async {
    final cleanSourcePath = sourceFilePath.trim();
    if (cleanSourcePath.isEmpty) {
      return const ProjectReferenceExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '缺少可提取的参考源文档路径。',
      );
    }
    final sourceFile = File(cleanSourcePath);
    if (!await sourceFile.exists()) {
      return ProjectReferenceExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '参考源文档不存在：$cleanSourcePath',
      );
    }
    final settings = _readSettings();
    if (settings == null) {
      return const ProjectReferenceExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '当前还没有可用的应用设置，请先完成模型配置。',
      );
    }
    // 中文注释: 支持调用方（拆书"分析"步）显式指定 provider+model；未指定则回退 app 默认。
    // 两个都透传：下拉键是 "providerId::modelId"，但这里原来只按 defaultProvider() 取 provider，
    // 用户在非默认 provider 下选模型会错配——同时按 overrideProviderId 解析 provider 才正确。
    final cleanOverrideProviderId = overrideProviderId.trim();
    ProviderEndpointSettings? provider;
    if (cleanOverrideProviderId.isNotEmpty) {
      for (final candidate in settings.providers) {
        if (candidate.id == cleanOverrideProviderId) {
          provider = candidate;
          break;
        }
      }
    } else {
      provider = settings.defaultProvider();
    }
    if (provider == null) {
      return const ProjectReferenceExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '当前没有可用的接口配置，请先补齐模型接口。',
      );
    }
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
      overrideModelId: overrideModelId.trim(),
    );
    final runtimeProfile = ValueReaders.mapValue(
      executionProfile['runtime_profile'],
    );
    final resolvedModelId = ValueReaders.stringValue(
      executionProfile['resolved_model_id'],
    );
    if (provider.baseUrl.trim().isEmpty || resolvedModelId.trim().isEmpty) {
      return const ProjectReferenceExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '请先在设置里配置真实的模型接口地址和模型名，再执行参考资料提取。',
      );
    }

    try {
      final normalizedStrategyProfileId = _strategyCatalogService
          .normalizeProfileId(strategyProfileId);
      final gateway = _llmGatewayFactory(provider, settings.networkSettings);
      final runId = _runCoordinator.identityService.resolveRunId(
        requestedRunId:
            'reference_extraction_gui_${DateTime.now().microsecondsSinceEpoch}',
        now: DateTime.now(),
        fallbackPrefix: 'reference_extraction_gui',
      );
      var request = _requestBuilderService.build(
        ProjectReferenceExtractionRequestInput(
          sourceFilePath: sourceFile.absolute.path,
          displayName: _displayNameFromPath(sourceFile.path),
          targetLanguage: 'zh-CN',
          maxChapterEntries: 6,
          maxEntityEntries: 6,
          // 拆书步骤③只允许暂存分析结果，用户在步骤④确认前不得生成项目资产。
          exportBundle: !analysisOnly,
          attachToProject: !analysisOnly,
          projectMountedEntries: !analysisOnly,
          explicitProjectionConfirmationGranted: !analysisOnly,
          runId: runId,
          strategyProfileId: normalizedStrategyProfileId,
          availableContextChars: ValueReaders.intValue(
            runtimeProfile['context_length'],
          ),
        ),
      );
      var result = await _executeReferenceExtraction(
        project: project,
        llmGateway: gateway,
        modelId: resolvedModelId,
        request: request,
      );
      var continuationRound = 0;
      while (_runCoordinator.publicationService.shouldContinueSemantically(
            result,
          ) &&
          continuationRound < 2) {
        continuationRound += 1;
        request = ProjectReferenceExtractionRequest(
          sourceFilePath: request.sourceFilePath,
          packageId: result.packageId,
          packageKind: request.packageKind,
          displayName: request.displayName,
          packageVersionId: result.packageVersionId,
          versionLabel: request.versionLabel,
          packageNamespace: request.packageNamespace,
          createdBy: request.createdBy,
          sourceLanguage: request.sourceLanguage,
          targetLanguage: request.targetLanguage,
          maxChapterEntries: request.maxChapterEntries,
          maxEntityEntries: request.maxEntityEntries,
          exportBundle: request.exportBundle,
          attachToProject: request.attachToProject,
          projectMountedEntries: request.projectMountedEntries,
          explicitProjectionConfirmationGranted:
              request.explicitProjectionConfirmationGranted,
          bundleOutputDirectory: request.bundleOutputDirectory,
          runId: request.runId,
          strategyProfileId: request.strategyProfileId,
          availableContextChars: request.availableContextChars,
          additionalStrategyProfiles: request.additionalStrategyProfiles,
        );
        result = await _executeReferenceExtraction(
          project: project,
          llmGateway: gateway,
          modelId: resolvedModelId,
          request: request,
        );
      }
      final completedSuccessfully = analysisOnly
          ? result.publishedSnapshotAvailable && result.finalizedEntryCount > 0
          : _runCoordinator.publicationService.isPublishedProjectionResult(
              result,
            );
      if (!completedSuccessfully) {
        return ProjectReferenceExtractionExecutionResult(
          ok: false,
          didMutateProject: false,
          statusMessage: _runCoordinator.publicationService
              .buildIncompleteStatusMessage(result),
        );
      }
      if (analysisOnly) {
        return ProjectReferenceExtractionExecutionResult(
          ok: true,
          didMutateProject: false,
          statusMessage:
              '参考资料分析完成：接纳 ${result.acceptedProposalCount} 条，暂存 ${result.finalizedEntryCount} 条结构化条目，尚未应用到项目资产。',
          runId: result.runId,
          packageId: result.packageId,
          packageVersionId: result.packageVersionId,
        );
      }
      return ProjectReferenceExtractionExecutionResult(
        ok: true,
        didMutateProject: true,
        statusMessage: _runCoordinator.publicationService.buildSuccessMessage(
          result,
        ),
        runId: result.runId,
        packageId: result.packageId,
        packageVersionId: result.packageVersionId,
      );
    } catch (error) {
      return ProjectReferenceExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: UserFacingErrorHumanizer.humanize(error, action: '提取参考资料'),
      );
    }
  }

  String _displayNameFromPath(String sourceFilePath) {
    final fileName = sourceFilePath.replaceAll('\\', '/').split('/').last;
    return fileName.trim().isEmpty ? '参考资料提取' : '参考资料提取：$fileName';
  }
}
