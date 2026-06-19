import '../models/project_rag_extraction_mode_id.dart';
import '../../presentation/models/project_rag_extraction_view_data.dart';

class ProjectRagExtractionModeViewDataService {
  const ProjectRagExtractionModeViewDataService();

  List<ProjectRagExtractionModeViewData> buildModes({
    required String selectedModeId,
  }) {
    // 中文注释: 模式列表只做 app 层的轻量投影，不把模式说明写回 core 合同。
    return ProjectRagExtractionModeId.values
        .map(
          (modeId) => ProjectRagExtractionModeViewData(
            id: modeId,
            title: ProjectRagExtractionModeId.labelOf(modeId),
            summary: ProjectRagExtractionModeId.summaryOf(modeId),
            badge: ProjectRagExtractionModeId.isImplemented(modeId)
                ? '可用'
                : '占位',
            isSelected: modeId == selectedModeId.trim(),
            isImplemented: ProjectRagExtractionModeId.isImplemented(modeId),
          ),
        )
        .toList(growable: false);
  }
}
