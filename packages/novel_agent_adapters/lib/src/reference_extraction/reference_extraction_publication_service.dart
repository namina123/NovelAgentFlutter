import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_reference_extraction_runtime_models.dart';

class ReferenceExtractionPublicationService {
  const ReferenceExtractionPublicationService();

  bool shouldContinueSemantically(ProjectReferenceExtractionResult result) {
    if (isPublishedProjectionResult(result)) {
      return false;
    }
    return result.runStatus ==
            ReferenceExtractionRunStatuses.awaitingSemanticContinuation ||
        result.runStatus ==
            ReferenceExtractionRunStatuses.semanticContinuationInProgress ||
        result.needsContinuation;
  }

  bool isPublishedProjectionResult(ProjectReferenceExtractionResult result) {
    return result.publishedSnapshotAvailable &&
        result.finalizedEntryCount > 0 &&
        result.projectMountStatus == ProjectReferenceMountStatuses.applied;
  }

  String buildSuccessMessage(ProjectReferenceExtractionResult result) {
    final projectionHint = result.generatedProjectionPaths.isEmpty
        ? '可返回工作台资料区查看新生成的项目资料摘要。'
        : '已生成 ${result.generatedProjectionPaths.join('、')}，可返回工作台资料区查看。';
    return '参考资料提取完成：接纳 ${result.acceptedProposalCount} 条，沉淀 ${result.finalizedEntryCount} 条结构化条目。$projectionHint';
  }

  String buildIncompleteStatusMessage(ProjectReferenceExtractionResult result) {
    final reason = result.deliveryRationale.trim().isEmpty
        ? result.outputCompletionStatus
        : result.deliveryRationale.trim();
    return '参考资料提取暂未完成：当前状态 ${result.runStatus}，输出状态 ${result.outputCompletionStatus}。原因：$reason';
  }
}
