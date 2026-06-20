import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/selector_option_view_data.dart';
import '../../presentation/models/workspace_command_request_view_data.dart';
import '../models/project_import_action_policy.dart';
import 'project_import_action_policy_service.dart';

class ProjectImportWorkspaceCommandViewDataService {
  ProjectImportWorkspaceCommandViewDataService({
    ProjectImportActionPolicyService? actionPolicyService,
  }) : _actionPolicyService =
           actionPolicyService ?? ProjectImportActionPolicyService();

  final ProjectImportActionPolicyService _actionPolicyService;

  WorkspaceCommandViewData build({
    required String projectType,
    required ProjectStorageStrategy storageStrategy,
    List<String> sourcePaths = const <String>[],
    String requestedTargetDirectory = '',
    bool requestedAutoDeconstruct = false,
    bool? requestedSmartAnalysis,
    String smartAnalysisProviderId = '',
    String smartAnalysisModelId = '',
    List<SelectorOptionViewData> smartAnalysisModelOptions =
        const <SelectorOptionViewData>[],
    bool requestedSmartDeconstruction = false,
    String smartDeconstructionProviderId = '',
    String smartDeconstructionModelId = '',
    List<SelectorOptionViewData> smartDeconstructionModelOptions =
        const <SelectorOptionViewData>[],
    bool isBusy = false,
    String busyLabel = '',
    String status = '',
  }) {
    final defaultSmartAnalysis =
        projectType.trim() != BookDeconstructionConstants.projectTypeId;
    final resolvedSmartAnalysis =
        requestedSmartAnalysis ?? defaultSmartAnalysis;
    final policy = _actionPolicyService.build(
      projectType: projectType,
      storageStrategy: storageStrategy,
      sourcePaths: sourcePaths,
      requestedTargetDirectory: requestedTargetDirectory,
      requestedAutoDeconstruct: requestedAutoDeconstruct,
      requestedSmartAnalysis: resolvedSmartAnalysis,
      smartAnalysisProviderId: smartAnalysisProviderId,
      smartAnalysisModelId: smartAnalysisModelId,
      requestedSmartDeconstruction: requestedSmartDeconstruction,
      smartDeconstructionProviderId: smartDeconstructionProviderId,
      smartDeconstructionModelId: smartDeconstructionModelId,
    );
    return WorkspaceCommandViewData(
      mode: WorkspaceCommandMode.importFiles,
      title: '导入文件',
      description: _descriptionFor(projectType.trim()),
      confirmLabel: '导入文件',
      isBusy: isBusy,
      busyLabel: busyLabel.trim(),
      status: status,
      projectTitle: '',
      projectType: projectType.trim(),
      genre: '',
      premise: '',
      notes: '',
      relativePath: '',
      entryName: '',
      content: '',
      sourcePathsText: policy.sourcePaths.join('\n'),
      targetDirectory: policy.resolvedTargetDirectory,
      autoDeconstruct: policy.autoDeconstruct,
      canAutoDeconstruct: policy.canAutoDeconstruct,
      smartAnalysis: policy.smartAnalysis,
      canSmartAnalyze: policy.canSmartAnalyze,
      smartAnalysisProviderId: policy.smartAnalysisProviderId,
      smartAnalysisModelId: policy.smartAnalysisModelId,
      smartAnalysisModelOptions: smartAnalysisModelOptions,
      smartDeconstruction: policy.smartDeconstruction,
      canSmartDeconstruction: policy.canSmartDeconstruction,
      smartDeconstructionProviderId: policy.smartDeconstructionProviderId,
      smartDeconstructionModelId: policy.smartDeconstructionModelId,
      smartDeconstructionModelOptions: smartDeconstructionModelOptions,
      importFileSelectionHint: policy.fileSelectionHint,
      importOutputHint: policy.outputHint,
    );
  }

  WorkspaceCommandViewData rebuild({
    required WorkspaceCommandRequestViewData request,
    required ProjectStorageStrategy storageStrategy,
    bool isBusy = false,
    String busyLabel = '',
    String status = '',
  }) {
    return build(
      projectType: request.projectType,
      storageStrategy: storageStrategy,
      sourcePaths: request.sourcePaths,
      requestedTargetDirectory: request.targetDirectory,
      requestedAutoDeconstruct: request.autoDeconstruct,
      requestedSmartAnalysis: request.smartAnalysis,
      smartAnalysisProviderId: request.smartAnalysisProviderId,
      smartAnalysisModelId: request.smartAnalysisModelId,
      requestedSmartDeconstruction: request.smartDeconstruction,
      smartDeconstructionProviderId: request.smartDeconstructionProviderId,
      smartDeconstructionModelId: request.smartDeconstructionModelId,
      isBusy: isBusy,
      busyLabel: busyLabel,
      status: status,
    );
  }

  ProjectImportActionPolicy resolvePolicy({
    required WorkspaceCommandRequestViewData request,
    required ProjectStorageStrategy storageStrategy,
  }) {
    return _actionPolicyService.build(
      projectType: request.projectType,
      storageStrategy: storageStrategy,
      sourcePaths: request.sourcePaths,
      requestedTargetDirectory: request.targetDirectory,
      requestedAutoDeconstruct: request.autoDeconstruct,
      requestedSmartAnalysis: request.smartAnalysis,
      smartAnalysisProviderId: request.smartAnalysisProviderId,
      smartAnalysisModelId: request.smartAnalysisModelId,
      requestedSmartDeconstruction: request.smartDeconstruction,
      smartDeconstructionProviderId: request.smartDeconstructionProviderId,
      smartDeconstructionModelId: request.smartDeconstructionModelId,
    );
  }

  String _descriptionFor(String projectType) {
    if (projectType == BookDeconstructionConstants.projectTypeId) {
      return '导入源文稿或文件夹，随后生成结构化预览。';
    }
    return '导入一个或多个本地文件，可按需启用智能分析。';
  }
}
