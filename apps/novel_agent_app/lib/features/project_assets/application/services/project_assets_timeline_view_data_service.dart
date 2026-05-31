import '../../presentation/models/project_assets_view_data.dart';
import '../models/project_assets_snapshot.dart';

class ProjectAssetsTimelineViewDataService {
  const ProjectAssetsTimelineViewDataService();

  ProjectAssetsTimelineViewData build(ProjectAssetsSnapshot snapshot) {
    final items = snapshot.catalog.timelines
        .map(
          (record) => ProjectAssetsTimelineItemViewData(
            id: record.id,
            title: record.displayName,
            phaseLabel: record.phaseLabel,
            statusLabel: record.status,
            sequenceLabel: record.sequence.toString(),
            relatedCount:
                record.relatedForeshadowIds.length +
                record.relatedRelationshipIds.length,
            isSelected: record.id == snapshot.selectedTimelineId,
          ),
        )
        .toList(growable: false);
    return ProjectAssetsTimelineViewData(
      title: '时间线概览',
      description: '按顺序浏览当前项目已沉淀的事件资产。',
      items: items,
    );
  }
}
