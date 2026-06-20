import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_catalog.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_snapshot.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_tab_id.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_selection_reconciler.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('reconciles selected ids and prefers rag tab for rag branch projects', () {
    const reconciler = ProjectAssetsSelectionReconciler();
    final snapshot = ProjectAssetsSnapshot.initial().copyWith(
      activeTabId: ProjectAssetsTabId.styles,
      selectedStyleId: 'missing',
      selectedExpressionConstraintId: 'missing',
      selectedForeshadowId: 'missing',
      selectedTimelineId: 'missing',
      selectedRelationshipId: 'missing',
      selectedGraphReferenceKey: 'missing',
    );
    final catalog = ProjectAssetsCatalog(
      styles: const <JsonMap>[
        <String, Object?>{'id': 'style-a'},
      ],
      expressionConstraints: const <ExpressionConstraintProfile>[
        ExpressionConstraintProfile(
          id: 'constraint-a',
          displayName: 'Constraint A',
          summary: '',
          kind: ExpressionConstraintKind.naturalExpression,
          rules: <String>[],
          riskSignals: <String>[],
          metadata: <String, Object?>{},
        ),
      ],
      foreshadows: const <ForeshadowRecord>[
        ForeshadowRecord(id: 'foreshadow-a', title: 'F', status: 'ok'),
      ],
      timelines: const <TimelineRecord>[
        TimelineRecord(id: 'timeline-a', displayName: 'T', sequence: 1),
      ],
      relationships: const <RelationshipRecord>[
        RelationshipRecord(
          id: 'relationship-a',
          displayName: 'R',
          leftEntityId: 'l',
          rightEntityId: 'r',
        ),
      ],
    );

    final reconciled = reconciler.reconcile(
      project: const ProjectDescriptor(
        id: 'project_a',
        name: '测试项目',
        rootPath: 'D:/Projects/demo',
        projectType: 'knowledge_base',
        projectBranchId: KnowledgeBaseBranchCatalogService.ragBranchId,
        storageStrategy: ProjectStorageStrategy.markdownProjectStore,
      ),
      previous: snapshot,
      catalog: catalog,
    );

    expect(reconciled.activeTabId, ProjectAssetsTabId.ragExtraction);
    expect(reconciled.selectedStyleId, 'style-a');
    expect(reconciled.selectedExpressionConstraintId, 'constraint-a');
    expect(reconciled.selectedForeshadowId, 'foreshadow-a');
    expect(reconciled.selectedTimelineId, 'timeline-a');
    expect(reconciled.selectedRelationshipId, 'relationship-a');
  });
}
