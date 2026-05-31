import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/project_assets_view_data.dart';
import '../models/project_assets_snapshot.dart';

class ProjectAssetsGraphViewDataService {
  const ProjectAssetsGraphViewDataService();

  ProjectAssetsGraphViewData build(ProjectAssetsSnapshot snapshot) {
    final references = snapshot.catalog.referenceIndex.references;
    final selected = _selectedReference(snapshot);
    final nodes = references
        .map(
          (reference) => ProjectAssetsGraphNodeViewData(
            referenceKey: reference.referenceKey,
            title: reference.displayName,
            kindLabel: _kindLabel(reference.assetKind),
            degree: reference.relatedReferenceKeys.length,
            hasMissingLinks: reference.missingReferenceKeys.isNotEmpty,
            isSelected: selected?.referenceKey == reference.referenceKey,
          ),
        )
        .toList(growable: false);
    final neighborRefs = selected == null
        ? const <SharedNarrativeAssetReference>[]
        : snapshot.catalog.referenceIndex.neighborsOf(
            selected.assetKind,
            selected.assetId,
          );
    final relatedAssets = neighborRefs
        .map(
          (reference) => ProjectAssetsRelatedAssetViewData(
            referenceKey: reference.referenceKey,
            title: reference.displayName,
            badge: _kindLabel(reference.assetKind),
            subtitle: reference.summary,
            isSelected: selected?.referenceKey == reference.referenceKey,
          ),
        )
        .toList(growable: false);
    final edgeCount = references.fold<int>(
      0,
      (sum, reference) => sum + reference.relatedReferenceKeys.length,
    );
    return ProjectAssetsGraphViewData(
      totalNodeCount: references.length,
      totalEdgeCount: edgeCount ~/ 2,
      focusTitle: selected?.displayName ?? '共享资产图谱',
      focusSummary: selected?.summary ?? '从伏笔、时间线、关系中读取当前项目的结构化关联。',
      focusKindLabel: selected == null ? '' : _kindLabel(selected.assetKind),
      nodes: nodes,
      relatedAssets: relatedAssets,
      missingReferenceKeys: selected?.missingReferenceKeys ?? const <String>[],
    );
  }

  SharedNarrativeAssetReference? _selectedReference(ProjectAssetsSnapshot snapshot) {
    final currentKey = snapshot.selectedGraphReferenceKey.trim();
    if (currentKey.isNotEmpty) {
      for (final reference in snapshot.catalog.referenceIndex.references) {
        if (reference.referenceKey == currentKey) {
          return reference;
        }
      }
    }
    final activeTabId = snapshot.activeTabId;
    if (activeTabId == 'foreshadows' && snapshot.selectedForeshadowId.isNotEmpty) {
      return snapshot.catalog.referenceIndex.referenceOf(
        'foreshadow',
        snapshot.selectedForeshadowId,
      );
    }
    if (activeTabId == 'timelines' && snapshot.selectedTimelineId.isNotEmpty) {
      return snapshot.catalog.referenceIndex.referenceOf(
        'timeline',
        snapshot.selectedTimelineId,
      );
    }
    if (activeTabId == 'relationships' &&
        snapshot.selectedRelationshipId.isNotEmpty) {
      return snapshot.catalog.referenceIndex.referenceOf(
        'relationship',
        snapshot.selectedRelationshipId,
      );
    }
    if (snapshot.catalog.referenceIndex.references.isEmpty) {
      return null;
    }
    return snapshot.catalog.referenceIndex.references.first;
  }

  String _kindLabel(String assetKind) {
    switch (assetKind) {
      case 'foreshadow':
        return '伏笔';
      case 'timeline':
        return '时间线';
      case 'relationship':
        return '关系';
      default:
        return assetKind;
    }
  }
}
