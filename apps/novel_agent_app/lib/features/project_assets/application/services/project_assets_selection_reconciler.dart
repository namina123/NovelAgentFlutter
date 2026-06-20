import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_assets_catalog.dart';
import '../models/project_assets_snapshot.dart';
import '../models/project_assets_tab_id.dart';

class ProjectAssetsSelectionReconciler {
  const ProjectAssetsSelectionReconciler();

  ProjectAssetsSnapshot reconcile({
    required ProjectDescriptor project,
    required ProjectAssetsSnapshot previous,
    required ProjectAssetsCatalog catalog,
  }) {
    final activeTabId = _shouldPreferRagTab(project, previous.activeTabId)
        ? ProjectAssetsTabId.ragExtraction
        : _selectedActiveTab(previous.activeTabId);
    return previous.copyWith(
      activeTabId: activeTabId,
      selectedStyleId: _selectedStyleId(catalog, previous.selectedStyleId),
      selectedExpressionConstraintId: _selectedExpressionConstraintId(
        catalog,
        previous.selectedExpressionConstraintId,
      ),
      selectedForeshadowId: _selectedForeshadowId(
        catalog,
        previous.selectedForeshadowId,
      ),
      selectedTimelineId: _selectedTimelineId(
        catalog,
        previous.selectedTimelineId,
      ),
      selectedRelationshipId: _selectedRelationshipId(
        catalog,
        previous.selectedRelationshipId,
      ),
      selectedGraphReferenceKey: _selectedGraphReferenceKey(
        catalog,
        previous.selectedGraphReferenceKey,
      ),
    );
  }

  bool _shouldPreferRagTab(ProjectDescriptor project, String activeTabId) {
    if (project.projectType.trim() != 'knowledge_base') {
      return false;
    }
    if (!const KnowledgeBaseBranchCatalogService().isRagBranch(
      project.projectBranchId,
    )) {
      return false;
    }
    final cleanActiveTabId = activeTabId.trim();
    return cleanActiveTabId.isEmpty ||
        cleanActiveTabId == ProjectAssetsTabId.styles ||
        cleanActiveTabId == ProjectAssetsTabId.referenceExtraction;
  }

  String _selectedActiveTab(String activeTabId) {
    final cleanTabId = activeTabId.trim();
    return cleanTabId.isEmpty
        ? ProjectAssetsTabId.referenceExtraction
        : cleanTabId;
  }

  String _selectedStyleId(ProjectAssetsCatalog catalog, String currentId) {
    if (currentId.trim().isNotEmpty &&
        catalog.styles.any(
          (item) => ValueReaders.stringValue(item['id']) == currentId,
        )) {
      return currentId.trim();
    }
    if (catalog.styles.isEmpty) {
      return '';
    }
    return ValueReaders.stringValue(catalog.styles.first['id']);
  }

  String _selectedExpressionConstraintId(
    ProjectAssetsCatalog catalog,
    String currentId,
  ) {
    if (currentId.trim().isNotEmpty &&
        catalog.expressionConstraints.any(
          (item) => item.id == currentId.trim(),
        )) {
      return currentId.trim();
    }
    if (catalog.expressionConstraints.isEmpty) {
      return '';
    }
    return catalog.expressionConstraints.first.id;
  }

  String _selectedForeshadowId(ProjectAssetsCatalog catalog, String currentId) {
    if (currentId.trim().isNotEmpty &&
        catalog.foreshadows.any((item) => item.id == currentId.trim())) {
      return currentId.trim();
    }
    if (catalog.foreshadows.isEmpty) {
      return '';
    }
    return catalog.foreshadows.first.id;
  }

  String _selectedTimelineId(ProjectAssetsCatalog catalog, String currentId) {
    if (currentId.trim().isNotEmpty &&
        catalog.timelines.any((item) => item.id == currentId.trim())) {
      return currentId.trim();
    }
    if (catalog.timelines.isEmpty) {
      return '';
    }
    return catalog.timelines.first.id;
  }

  String _selectedRelationshipId(
    ProjectAssetsCatalog catalog,
    String currentId,
  ) {
    if (currentId.trim().isNotEmpty &&
        catalog.relationships.any((item) => item.id == currentId.trim())) {
      return currentId.trim();
    }
    if (catalog.relationships.isEmpty) {
      return '';
    }
    return catalog.relationships.first.id;
  }

  String _selectedGraphReferenceKey(
    ProjectAssetsCatalog catalog,
    String currentKey,
  ) {
    if (currentKey.trim().isNotEmpty &&
        catalog.referenceIndex.references.any(
          (item) => item.referenceKey == currentKey.trim(),
        )) {
      return currentKey.trim();
    }
    if (catalog.referenceIndex.references.isEmpty) {
      return '';
    }
    return catalog.referenceIndex.references.first.referenceKey;
  }
}
