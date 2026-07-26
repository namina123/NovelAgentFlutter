import 'long_task_project_contract_assessment.dart';
import 'project_descriptor.dart';
import 'project_runtime_baseline_catalog_service.dart';
import 'project_runtime_profile.dart';

/// Validates the persisted facts that make a project eligible for long tasks.
///
/// Runtime options are intentionally not an authority for project type or
/// baseline: those facts belong to the manifest descriptor and its derived
/// runtime profile.
class LongTaskProjectContractService {
  const LongTaskProjectContractService({
    ProjectRuntimeBaselineCatalogService? runtimeBaselineCatalogService,
  }) : _runtimeBaselineCatalogService =
           runtimeBaselineCatalogService ??
           const ProjectRuntimeBaselineCatalogService();

  final ProjectRuntimeBaselineCatalogService _runtimeBaselineCatalogService;

  LongTaskProjectContractAssessment assess({
    required ProjectDescriptor project,
    ProjectRuntimeProfile? runtimeProfile,
    String requestedRuntimeBaselineId = '',
  }) {
    if (project.projectType.trim() != 'long_novel') {
      return const LongTaskProjectContractAssessment.rejected(
        errorCode: 'long_task_unsupported_project_type',
        message: '只有长篇长任务项目可以创建或运行长任务队列。',
      );
    }
    final baselineId = project.runtimeBaselineId.trim();
    if (baselineId.isEmpty) {
      return const LongTaskProjectContractAssessment.rejected(
        errorCode: 'long_task_runtime_baseline_missing',
        message: '当前长篇项目尚未配置运行基准，不能启动长任务。',
      );
    }
    if (!_runtimeBaselineCatalogService.containsForProjectType(
      project.projectType,
      baselineId,
    )) {
      return const LongTaskProjectContractAssessment.rejected(
        errorCode: 'long_task_runtime_baseline_invalid',
        message: '当前项目的运行基准无效，不能启动长任务。',
      );
    }
    final requestedBaselineId = requestedRuntimeBaselineId.trim();
    if (requestedBaselineId.isNotEmpty && requestedBaselineId != baselineId) {
      return const LongTaskProjectContractAssessment.rejected(
        errorCode: 'long_task_runtime_baseline_mismatch',
        message: '本次任务请求的运行基准与当前项目不一致，已拒绝启动。',
      );
    }
    if (runtimeProfile != null &&
        (runtimeProfile.projectType.trim() != project.projectType.trim() ||
            runtimeProfile.runtimeBaselineId.trim() != baselineId)) {
      return const LongTaskProjectContractAssessment.rejected(
        errorCode: 'long_task_runtime_profile_mismatch',
        message: '项目运行画像与当前项目合同不一致，不能启动长任务。',
      );
    }
    return const LongTaskProjectContractAssessment.allowed();
  }
}
