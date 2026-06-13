import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../../../shared/services/desktop_text_file_picker_service.dart';
import '../models/project_reference_extraction_execution_result.dart';

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
           const ReferenceExtractionStrategyProfileCatalogService();

  final AppSettings? Function() _readSettings;
  final ProjectReferenceExtractionGatewayFactory _llmGatewayFactory;
  final ExecuteProjectReferenceExtraction _executeReferenceExtraction;
  final DesktopTextFilePickerService _sourcePickerService;
  final ModelExecutionProfileService _modelExecutionProfileService;
  final ProjectReferenceExtractionRequestBuilderService _requestBuilderService;
  final ReferenceExtractionStrategyProfileCatalogService
  _strategyCatalogService;
  static const int _maxSemanticContinuationRounds = 2;

  Future<ProjectReferenceExtractionExecutionResult> pickAndExecute({
    required ProjectDescriptor project,
    String strategyProfileId = '',
  }) async {
    final selectedPath = await _sourcePickerService.pickSingleFile(
      dialogTitle: '选择参考源文档',
    );
    if (selectedPath == null) {
      return const ProjectReferenceExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '已取消参考资料提取。',
      );
    }
    return execute(
      project: project,
      sourceFilePath: selectedPath,
      strategyProfileId: strategyProfileId,
    );
  }

  Future<ProjectReferenceExtractionExecutionResult> execute({
    required ProjectDescriptor project,
    required String sourceFilePath,
    String strategyProfileId = '',
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
    if (!sourceFile.existsSync()) {
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
    final provider = settings.defaultProvider();
    if (provider == null) {
      return const ProjectReferenceExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '当前没有可用的 provider 配置，请先补齐模型接口。',
      );
    }
    final executionProfile = _modelExecutionProfileService.resolve(
      settings: settings,
      provider: provider,
      overrideModelId: '',
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
      final runId = 'reference_extraction_gui_${DateTime.now().microsecondsSinceEpoch}';
      var request = _requestBuilderService.build(
        ProjectReferenceExtractionRequestInput(
          sourceFilePath: sourceFile.absolute.path,
          displayName: _displayNameFromPath(sourceFile.path),
          targetLanguage: 'zh-CN',
          maxChapterEntries: 6,
          maxEntityEntries: 6,
          exportBundle: true,
          attachToProject: true,
          projectMountedEntries: true,
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
      while (_shouldContinueSemantically(result) &&
          continuationRound < _maxSemanticContinuationRounds) {
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
      if (!_isPublishedProjectionResult(result)) {
        return ProjectReferenceExtractionExecutionResult(
          ok: false,
          didMutateProject: false,
          statusMessage: _incompleteStatusMessage(result),
        );
      }
      return ProjectReferenceExtractionExecutionResult(
        ok: true,
        didMutateProject: true,
        statusMessage: _successMessage(result),
      );
    } catch (error) {
      return ProjectReferenceExtractionExecutionResult(
        ok: false,
        didMutateProject: false,
        statusMessage: '参考资料提取失败：$error',
      );
    }
  }

  String _displayNameFromPath(String sourceFilePath) {
    final fileName = sourceFilePath.replaceAll('\\', '/').split('/').last;
    return fileName.trim().isEmpty ? '参考资料提取' : '参考资料提取：$fileName';
  }

  String _successMessage(ProjectReferenceExtractionResult result) {
    final projectionHint = result.generatedProjectionPaths.isEmpty
        ? '可返回工作台资料区查看新生成的项目资料投影。'
        : '已生成 ${result.generatedProjectionPaths.join('、')}，可返回工作台资料区查看。';
    return '参考资料提取完成：接纳 ${result.acceptedProposalCount} 条，沉淀 ${result.finalizedEntryCount} 条结构化条目。$projectionHint';
  }

  bool _shouldContinueSemantically(ProjectReferenceExtractionResult result) {
    if (_isPublishedProjectionResult(result)) {
      return false;
    }
    return result.runStatus ==
            ReferenceExtractionRunStatuses.awaitingSemanticContinuation ||
        result.runStatus ==
            ReferenceExtractionRunStatuses.semanticContinuationInProgress ||
        result.needsContinuation;
  }

  bool _isPublishedProjectionResult(ProjectReferenceExtractionResult result) {
    return result.publishedSnapshotAvailable &&
        result.finalizedEntryCount > 0 &&
        result.projectMountStatus == ProjectReferenceMountStatuses.applied;
  }

  String _incompleteStatusMessage(ProjectReferenceExtractionResult result) {
    final reason = result.deliveryRationale.trim().isEmpty
        ? result.outputCompletionStatus
        : result.deliveryRationale.trim();
    return '参考资料提取暂未完成：当前状态 ${result.runStatus}，输出状态 ${result.outputCompletionStatus}。原因：$reason';
  }
}
