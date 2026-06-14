import '../project/project_descriptor.dart';
import '../project/project_runtime_profile_document_service.dart';
import '../project/project_type_transition_blocker.dart';
import '../project/project_type_transition_preparation_service.dart';
import 'update_project_manifest_use_case.dart';
import 'write_project_text_file_use_case.dart';

class ExecuteProjectTypeTransitionUseCase {
  ExecuteProjectTypeTransitionUseCase({
    required ProjectTypeTransitionPreparationService
    projectTypeTransitionPreparationService,
    required UpdateProjectManifestUseCase updateProjectManifestUseCase,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    ProjectRuntimeProfileDocumentService? projectRuntimeProfileDocumentService,
  }) : _projectTypeTransitionPreparationService =
           projectTypeTransitionPreparationService,
       _updateProjectManifestUseCase = updateProjectManifestUseCase,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _projectRuntimeProfileDocumentService =
           projectRuntimeProfileDocumentService ??
           ProjectRuntimeProfileDocumentService();

  final ProjectTypeTransitionPreparationService
  _projectTypeTransitionPreparationService;
  final UpdateProjectManifestUseCase _updateProjectManifestUseCase;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final ProjectRuntimeProfileDocumentService
  _projectRuntimeProfileDocumentService;

  Future<ProjectDescriptor> execute({
    required ProjectDescriptor project,
    required String targetProjectTypeId,
    String runtimeBaselineId = '',
    bool hasActiveLongTaskRun = false,
  }) async {
    // 中文注释: 执行阶段先走同源计划校验，再把项目类型、运行基准和运行配置一起收束到新合同。
    final plan = _projectTypeTransitionPreparationService.prepare(
      project: project,
      targetProjectTypeId: targetProjectTypeId,
      runtimeBaselineId: runtimeBaselineId,
      hasActiveLongTaskRun: hasActiveLongTaskRun,
    );
    if (!plan.canTransition) {
      throw StateError(_buildBlockedMessage(plan.blockers));
    }
    final targetDefinition = plan.targetProjectTypeDefinition;
    if (targetDefinition == null) {
      throw StateError('项目类型转换计划缺少目标类型定义。');
    }
    await _updateProjectManifestUseCase.execute(
      project: project,
      title: project.name,
      projectType: targetDefinition.id,
      storageStrategy: plan.targetStorageStrategy,
      runtimeBaselineId: plan.targetRuntimeBaselineId,
    );
    final runtimeProfile = _projectRuntimeProfileDocumentService.buildProfile(
      projectType: targetDefinition.id,
      runtimeBaselineId: plan.targetRuntimeBaselineId,
    );
    await _writeProjectTextFileUseCase.execute(
      project: project,
      relativePath: ProjectRuntimeProfileDocumentService.profileRelativePath,
      content: _projectRuntimeProfileDocumentService.encode(runtimeProfile),
    );
    return ProjectDescriptor(
      id: project.id,
      name: project.name,
      rootPath: project.rootPath,
      projectType: targetDefinition.id,
      storageStrategy: plan.targetStorageStrategy,
      runtimeBaselineId: plan.targetRuntimeBaselineId,
    );
  }

  String _buildBlockedMessage(List<ProjectTypeTransitionBlocker> blockers) {
    // 中文注释: 执行失败时只把核心阻断原因串起来，方便上层直接展示或记录。
    return blockers.map((item) => item.message).join('；');
  }
}
