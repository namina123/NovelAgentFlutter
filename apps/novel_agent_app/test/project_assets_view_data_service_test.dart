import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_catalog.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_snapshot.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_tab_id.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_view_data_service.dart';
import 'package:novel_agent_app/features/project_assets/presentation/models/project_assets_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'ProjectAssetsViewDataService exposes expression constraint timeline relationship and graph tabs',
    () {
      const service = ProjectAssetsViewDataService();
      final referenceIndex = const SharedNarrativeAssetReferenceIndexService()
          .buildIndex(
            foreshadows: const <ForeshadowRecord>[
              ForeshadowRecord(
                id: 'hook',
                title: '开场伏笔',
                status: 'planted',
                relatedTimelineIds: <String>['event-1'],
              ),
            ],
            timelines: const <TimelineRecord>[
              TimelineRecord(
                id: 'event-1',
                displayName: '主角进入学院',
                sequence: 1,
                relatedForeshadowIds: <String>['hook'],
              ),
            ],
            relationships: const <RelationshipRecord>[
              RelationshipRecord(
                id: 'bond-1',
                displayName: '主角与导师',
                leftEntityId: 'hero',
                rightEntityId: 'mentor',
              ),
            ],
          );
      final snapshot = ProjectAssetsSnapshot.initial().copyWith(
        activeTabId: ProjectAssetsTabId.expressionConstraints,
        selectedExpressionConstraintId: 'de_ai',
        entryAgentContextId: 'reviewer',
        availableAgentOptions:
            const <ExpressionConstraintSelectableOptionViewData>[
              ExpressionConstraintSelectableOptionViewData(
                id: 'reviewer',
                label: '审阅智能体',
                note: '负责补充审阅和校对建议',
              ),
              ExpressionConstraintSelectableOptionViewData(
                id: 'writer',
                label: '写作智能体',
              ),
            ],
        availableModeOptions:
            const <ExpressionConstraintSelectableOptionViewData>[
              ExpressionConstraintSelectableOptionViewData(
                id: 'full_outline_consensus',
                label: '全书共拟式长篇',
              ),
            ],
        availableStageOptions:
            const <ExpressionConstraintSelectableOptionViewData>[
              ExpressionConstraintSelectableOptionViewData(
                id: 'book_premise',
                label: '故事总前提',
                note: '全书共拟式长篇',
                groupId: 'full_outline_consensus',
              ),
            ],
        catalog: ProjectAssetsCatalog(
          styles: const <JsonMap>[
            <String, Object?>{
              'id': 'modern',
              'display_name': '现代直白',
              'summary': '偏现代',
            },
          ],
          expressionConstraints: const <ExpressionConstraintProfile>[
            ExpressionConstraintProfile(
              id: 'de_ai',
              displayName: '去 AI 风',
              summary: '压低模板化表达。',
              kind: ExpressionConstraintKind.naturalExpression,
              rules: <String>['少用工整排比。'],
              riskSignals: <String>['总而言之'],
              metadata: <String, Object?>{'builtin': true},
            ),
          ],
          expressionConstraintBindings:
              const <ProjectExpressionConstraintBinding>[
                ProjectExpressionConstraintBinding(
                  profileId: 'de_ai',
                  enabled: true,
                  defaultForProject: true,
                  targetModeIds: <String>['full_outline_consensus'],
                  targetStageIds: <String>['book_premise'],
                  metadata: <String, Object?>{'policy_mode': 'adaptive'},
                ),
              ],
          foreshadows: const <ForeshadowRecord>[
            ForeshadowRecord(id: 'hook', title: '开场伏笔', status: 'planted'),
          ],
          timelines: const <TimelineRecord>[
            TimelineRecord(id: 'event-1', displayName: '主角进入学院', sequence: 1),
          ],
          relationships: const <RelationshipRecord>[
            RelationshipRecord(
              id: 'bond-1',
              displayName: '主角与导师',
              leftEntityId: 'hero',
              rightEntityId: 'mentor',
            ),
          ],
          referenceIndex: referenceIndex,
        ),
        selectedGraphReferenceKey: 'foreshadow:hook',
      );

      final viewData = service.build(snapshot: snapshot, status: 'ok');

      expect(
        viewData.tabs.map((item) => item.id),
        containsAll(<String>[
          ProjectAssetsTabId.expressionConstraints,
          ProjectAssetsTabId.timelines,
          ProjectAssetsTabId.relationships,
          ProjectAssetsTabId.graph,
        ]),
      );
      expect(viewData.entries.single.id, 'de_ai');
      expect(viewData.entries.single.meta, contains('内置方案'));
      expect(viewData.description, contains('表达限制是项目级写作约束系统'));
      expect(viewData.description, contains('智能体 reviewer'));
      expect(viewData.expressionConstraintEditor.displayName, '去 AI 风');
      expect(viewData.expressionConstraintEditor.profileId, 'de_ai');
      expect(viewData.expressionConstraintEditor.originLabel, '内置方案');
      expect(viewData.expressionConstraintEditor.enabled, isTrue);
      expect(
        viewData.expressionConstraintEditor.selectedPolicyMode,
        'adaptive',
      );
      expect(
        viewData.expressionConstraintEditor.availablePolicyOptions.map(
          (item) => item.label,
        ),
        containsAll(<String>['关闭', '智能使用', '强力约束']),
      );
      expect(
        viewData.expressionConstraintEditor.selectedAgentIds,
        contains('reviewer'),
      );
      expect(
        viewData.expressionConstraintEditor.availableAgentOptions.map(
          (item) => item.id,
        ),
        containsAll(<String>['reviewer', 'writer']),
      );
      expect(viewData.expressionConstraintEditor.selectedModeIds, <String>[
        'full_outline_consensus',
      ]);
      expect(viewData.expressionConstraintEditor.selectedStageIds, <String>[
        'book_premise',
      ]);
      expect(
        viewData.expressionConstraintEditor.availableStageOptions.map(
          (item) => item.id,
        ),
        contains('book_premise'),
      );
      expect(
        viewData.expressionConstraintEditor.scopeSummary,
        contains('全项目默认启用'),
      );
      expect(viewData.expressionConstraintEditor.strengthSummary, isNotEmpty);
      expect(
        viewData.expressionConstraintEditor.usageStrategySummary,
        contains('智能使用'),
      );
      expect(
        viewData.expressionConstraintEditor.diagnosticFields.map(
          (item) => item.label,
        ),
        containsAll(<String>['策略模式标识', '规则方案标识', '注入方式']),
      );
      expect(viewData.graph.totalNodeCount, 3);
      expect(viewData.graph.relatedAssets, isNotEmpty);
      expect(viewData.timeline.items.single.id, 'event-1');
      expect(
        viewData.referenceExtractionStrategyPicker.selectedProfileId,
        ReferenceExtractionBuiltinStrategyProfileIds.standard,
      );
      expect(
        viewData.referenceExtractionStrategyPicker.options.map(
          (item) => item.displayName,
        ),
        containsAll(<String>['标准提取', '事实优先', '探索扩展']),
      );
    },
  );
}
