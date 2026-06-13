import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/project_assets/presentation/models/project_assets_view_data.dart';
import 'package:novel_agent_app/features/project_assets/presentation/widgets/expression_constraint_binding_editor_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'shows user-friendly strategy fields and keeps diagnostics collapsed by default',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ExpressionConstraintBindingEditorPanel(
              viewData: _sampleViewData(),
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
      expect(find.text('内置方案'), findsOneWidget);
      expect(find.text('使用策略'), findsWidgets);
      expect(find.text('关闭'), findsOneWidget);
      expect(find.text('智能使用'), findsWidgets);
      expect(find.text('强力约束'), findsOneWidget);
      expect(find.text('适用范围'), findsOneWidget);
      expect(find.text('强度'), findsOneWidget);
      expect(find.text('写作规则'), findsWidgets);
      expect(find.text('定向智能体'), findsOneWidget);
      expect(find.text('定向模式'), findsOneWidget);
      expect(find.text('定向阶段'), findsOneWidget);
      expect(find.text('审阅智能体'), findsOneWidget);
      expect(find.text('全书共拟式长篇'), findsWidgets);
      expect(find.text('故事总前提'), findsOneWidget);
      expect(find.textContaining('预设'), findsNothing);
      expect(find.textContaining('Agent ID'), findsNothing);
      expect(find.textContaining('Mode ID'), findsNothing);
      expect(find.textContaining('Stage ID'), findsNothing);
      expect(find.text('策略模式标识'), findsNothing);
      expect(find.text('规则方案标识'), findsNothing);

      for (var i = 0; i < 3; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -280));
        await tester.pumpAndSettle();
      }
      expect(find.byType(ExpansionTile), findsOneWidget);
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      expect(find.text('策略模式标识'), findsOneWidget);
      expect(find.text('规则方案标识'), findsOneWidget);
      expect(find.text('注入方式'), findsOneWidget);
      expect(find.text('优先级权重'), findsOneWidget);
    },
  );

  testWidgets('submits selected strategy mode with project binding request', (
    WidgetTester tester,
  ) async {
    ExpressionConstraintBindingEditorRequestViewData? capturedRequest;
    await tester.binding.setSurfaceSize(const Size(900, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ExpressionConstraintBindingEditorPanel(
            viewData: _sampleViewData(),
            onSaveRequested: (request) => capturedRequest = request,
            onRemoveRequested: _noopRemove,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.widgetWithText(RadioListTile<String>, '强力约束'),
    );
    await tester.tap(find.widgetWithText(RadioListTile<String>, '强力约束'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存设置'));
    await tester.pumpAndSettle();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.selectedPolicyMode, 'force');
  });
}

ExpressionConstraintBindingEditorViewData _sampleViewData() {
  return const ExpressionConstraintBindingEditorViewData(
    profileId: 'de_ai',
    bindingId: 'binding_de_ai',
    displayName: '去 AI 风',
    summary: '降低模板化表达、解释腔和过度工整的平衡句。',
    kindLabel: '自然表达',
    originLabel: '内置方案',
    sourcePath: 'builtin://expression_constraints/de_ai',
    entryAgentContextId: 'reviewer',
    selectedPolicyMode: 'adaptive',
    availablePolicyOptions: <ExpressionConstraintPolicyOptionViewData>[
      ExpressionConstraintPolicyOptionViewData(
        id: 'disabled',
        label: '关闭',
        description: '保留这套规则方案，但当前项目不注入表达规则，也不要求复核。',
      ),
      ExpressionConstraintPolicyOptionViewData(
        id: 'adaptive',
        label: '智能使用',
        description: '优先覆盖正文、修订等用户可见文本，必要时建议加强。',
      ),
      ExpressionConstraintPolicyOptionViewData(
        id: 'force',
        label: '强力约束',
        description: '对正文与修订强执行，明显偏离时直接阻塞修订。',
      ),
    ],
    scopeSummary: '全项目默认启用；定向智能体：审阅智能体；写作模式：全书共拟式长篇；执行阶段：故事总前提',
    strengthSummary: '按写作轮次智能控制强度，常规正文以分段约束为主，并在已应用时要求复核。',
    usageStrategySummary: '当前策略为智能使用；优先覆盖正文、修订等用户可见文本，技术轮次与研究轮次保持排除。',
    recommendedScopeText: '项目类型 novel, long_novel',
    rules: <String>['少用工整排比。'],
    riskSignals: <String>['总而言之'],
    diagnosticFields: <ExpressionConstraintDiagnosticFieldViewData>[
      ExpressionConstraintDiagnosticFieldViewData(
        label: '策略模式标识',
        value: 'adaptive',
      ),
      ExpressionConstraintDiagnosticFieldViewData(
        label: '规则方案标识',
        value: 'de_ai',
      ),
      ExpressionConstraintDiagnosticFieldViewData(
        label: '注入方式',
        value: 'brief_only / brief_and_sections（按轮次自动解析）',
      ),
    ],
    enabled: true,
    defaultForProject: true,
    availableAgentOptions: <ExpressionConstraintSelectableOptionViewData>[
      ExpressionConstraintSelectableOptionViewData(
        id: 'reviewer',
        label: '审阅智能体',
      ),
      ExpressionConstraintSelectableOptionViewData(
        id: 'writer',
        label: '写作智能体',
      ),
    ],
    availableModeOptions: <ExpressionConstraintSelectableOptionViewData>[
      ExpressionConstraintSelectableOptionViewData(
        id: 'full_outline_consensus',
        label: '全书共拟式长篇',
        note: '先一起谈清全书走向，再进入执行期。',
      ),
    ],
    availableStageOptions: <ExpressionConstraintSelectableOptionViewData>[
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
  );
}

void _noopSave(ExpressionConstraintBindingEditorRequestViewData request) {}

void _noopRemove(String profileId) {}
