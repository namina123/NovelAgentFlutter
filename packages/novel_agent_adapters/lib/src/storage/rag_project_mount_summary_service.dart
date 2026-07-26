import 'package:novel_agent_core/novel_agent_core.dart';

import 'sqlite_rag_metadata_repository.dart';

class RagProjectMountSummaryService {
  RagProjectMountSummaryService({
    SqliteRagMetadataRepository? metadataRepository,
  }) : _metadataRepository =
           metadataRepository ?? SqliteRagMetadataRepository();

  final SqliteRagMetadataRepository _metadataRepository;

  Future<RagProjectMountSummary> summarize(ProjectDescriptor project) async {
    // 中文注释: 这里仅做项目维度挂载摘要，给 GUI / CLI / probe 消费，不承担挂载策略决策。
    final bindings = await _metadataRepository.listProjectMounts(
      project,
      projectId: project.id,
    );
    final corpusIds = bindings
        .map((entry) => entry.corpusId)
        .toList(growable: false);
    final topBinding = bindings.isEmpty ? null : bindings.first;
    return RagProjectMountSummary(
      projectId: project.id,
      bindingCount: bindings.length,
      corpusIds: corpusIds,
      topCorpusId: topBinding?.corpusId ?? '',
      topBindingId: topBinding?.bindingId ?? '',
      topMountScope: topBinding?.mountScope ?? '',
      topUsagePolicy: topBinding?.usagePolicy ?? '',
      topActivationPolicy: topBinding?.activationPolicy ?? '',
    );
  }
}

class RagProjectMountSummary {
  const RagProjectMountSummary({
    required this.projectId,
    required this.bindingCount,
    required this.corpusIds,
    required this.topCorpusId,
    required this.topBindingId,
    required this.topMountScope,
    required this.topUsagePolicy,
    required this.topActivationPolicy,
  });

  final String projectId;
  final int bindingCount;
  final List<String> corpusIds;
  final String topCorpusId;
  final String topBindingId;
  final String topMountScope;
  final String topUsagePolicy;
  final String topActivationPolicy;

  bool get hasBindings => bindingCount > 0;

  JsonMap toJson() {
    // 中文注释: 摘要对象只输出给消费层用的稳定字段，便于后续挂到状态卡或命令输出。
    return <String, Object?>{
      'project_id': projectId,
      'binding_count': bindingCount,
      'corpus_ids': corpusIds,
      'top_corpus_id': topCorpusId,
      'top_binding_id': topBindingId,
      'top_mount_scope': topMountScope,
      'top_usage_policy': topUsagePolicy,
      'top_activation_policy': topActivationPolicy,
      'has_bindings': hasBindings,
    };
  }
}
