import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/project_assets/presentation/models/project_assets_view_data.dart';
import 'package:novel_agent_app/features/project_assets/presentation/widgets/expression_constraint_binding_editor_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'shows expression constraint system framing and builtin de_ai preset identity',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ExpressionConstraintBindingEditorPanel(
              viewData: const ExpressionConstraintBindingEditorViewData(
                profileId: 'de_ai',
                displayName: '去 AI 风',
                summary: '降低模板化表达、解释腔和过度工整的平衡句。',
                kindLabel: '自然表达',
                sourcePath: 'builtin://expression_constraints/de_ai',
                entryAgentContextId: 'reviewer',
                recommendedScopeText: '项目类型 novel, long_novel',
                rules: <String>['少用工整排比。'],
                riskSignals: <String>['总而言之'],
                enabled: true,
                defaultForProject: true,
                availableAgentOptions:
                    <ExpressionConstraintSelectableOptionViewData>[
                      ExpressionConstraintSelectableOptionViewData(
                        id: 'reviewer',
                        label: '审阅智能体',
                      ),
                      ExpressionConstraintSelectableOptionViewData(
                        id: 'writer',
                        label: '写作智能体',
                      ),
                    ],
                availableModeOptions:
                    <ExpressionConstraintSelectableOptionViewData>[
                      ExpressionConstraintSelectableOptionViewData(
                        id: 'full_outline_consensus',
                        label: '全书共拟式长篇',
                        note: '先一起谈清全书走向，再进入执行期。',
                      ),
                    ],
                availableStageOptions:
                    <ExpressionConstraintSelectableOptionViewData>[
                      ExpressionConstraintSelectableOptionViewData(
                        id: 'book_premise',
                        label: '故事总前提',
                        note: '全书共拟式长篇',
                        groupId: 'full_outline_consensus',
                      ),
                    ],
                selectedAgentIds: <String>['reviewer'],
                selectedModeIds: <String>['full_outline_consensus'],
                selectedStageIds: <String>['book_premise'],
                targetAgentIdsText: 'reviewer',
                targetModeIdsText: 'full_outline_consensus',
                targetStageIdsText: 'book_premise',
                weightText: '100',
                hasBinding: true,
                isBuiltin: true,
              ),
              onSaveRequested: _noopSave,
              onRemoveRequested: _noopRemove,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('表达限制'), findsOneWidget);
      expect(find.textContaining('项目级写作约束系统'), findsOneWidget);
      expect(find.text('去 AI 风'), findsOneWidget);
      expect(find.text('内置预设'), findsOneWidget);
      expect(find.text('当前预设 ID：de_ai'), findsOneWidget);
      expect(find.textContaining('这是表达限制系统中的一个内置预设'), findsOneWidget);
      expect(find.text('当前入口智能体：reviewer'), findsOneWidget);
      expect(find.text('启用这个表达限制预设'), findsOneWidget);
      expect(find.text('定向智能体'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('定向模式'), findsOneWidget);
      expect(find.text('定向阶段'), findsOneWidget);
      expect(find.text('审阅智能体'), findsOneWidget);
      expect(find.text('全书共拟式长篇'), findsWidgets);
      expect(find.text('故事总前提'), findsOneWidget);
      expect(find.text('Agent IDs（逗号分隔）'), findsNothing);
      expect(find.text('Mode IDs（逗号分隔）'), findsNothing);
      expect(find.text('Stage IDs（逗号分隔）'), findsNothing);
    },
  );
}

void _noopSave(ExpressionConstraintBindingEditorRequestViewData request) {}

void _noopRemove(String profileId) {}
