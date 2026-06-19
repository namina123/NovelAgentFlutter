import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_rag_extraction_mode_id.dart';
import 'project_rag_mount_summary.dart';

class ProjectRagExtractionSnapshot {
  const ProjectRagExtractionSnapshot({
    required this.activeModeId,
    required this.selectedCorpusId,
    required this.selectedCorpus,
    required this.mountSummary,
    required this.isLoading,
    required this.statusMessage,
    required this.recentSourcePath,
  });

  final String activeModeId;
  final String selectedCorpusId;
  final RagCorpusPackage? selectedCorpus;
  final ProjectRagMountSummary mountSummary;
  final bool isLoading;
  final String statusMessage;
  final String recentSourcePath;

  factory ProjectRagExtractionSnapshot.initial() {
    // 中文注释: 初始状态默认停在 RAG 提取模式，但还没有任何语料或挂载结果。
    return ProjectRagExtractionSnapshot(
      activeModeId: ProjectRagExtractionModeId.ragExtraction,
      selectedCorpusId: '',
      selectedCorpus: null,
      mountSummary: ProjectRagMountSummary.empty(),
      isLoading: false,
      statusMessage: '',
      recentSourcePath: '',
    );
  }

  ProjectRagExtractionSnapshot copyWith({
    String? activeModeId,
    String? selectedCorpusId,
    RagCorpusPackage? selectedCorpus,
    ProjectRagMountSummary? mountSummary,
    bool? isLoading,
    String? statusMessage,
    String? recentSourcePath,
  }) {
    // 中文注释: 只更新本次有变化的 RAG 工作区字段，避免把其他状态回写掉。
    return ProjectRagExtractionSnapshot(
      activeModeId: activeModeId ?? this.activeModeId,
      selectedCorpusId: selectedCorpusId ?? this.selectedCorpusId,
      selectedCorpus: selectedCorpus ?? this.selectedCorpus,
      mountSummary: mountSummary ?? this.mountSummary,
      isLoading: isLoading ?? this.isLoading,
      statusMessage: statusMessage ?? this.statusMessage,
      recentSourcePath: recentSourcePath ?? this.recentSourcePath,
    );
  }
}
