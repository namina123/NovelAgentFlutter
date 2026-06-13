import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/project_creation/application/services/project_creation_expression_constraint_defaults_settings_service.dart';
import 'package:novel_agent_app/features/settings/presentation/models/project_creation_expression_constraint_defaults_view_data.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/project_creation_expression_constraint_defaults_panel.dart';

void main() {
  testWidgets('panel saves selected custom profile ids', (tester) async {
    Map<String, Object?>? savedPayload;
    await tester.pumpWidget(
      _buildHarness(
        viewData: const ProjectCreationExpressionConstraintDefaultsViewData(
          mode: ProjectCreationExpressionConstraintDefaultsMode.custom,
          fallbackSummary: '去 AI 风',
          options: <ProjectCreationExpressionConstraintOptionViewData>[
            ProjectCreationExpressionConstraintOptionViewData(
              id: 'de_ai',
              label: '去 AI 风',
              summary: 'summary',
              isSelected: true,
            ),
            ProjectCreationExpressionConstraintOptionViewData(
              id: 'strict_pov_boundary',
              label: '严格视角边界',
              summary: 'summary',
              isSelected: false,
            ),
          ],
        ),
        onSaved: (payload) => savedPayload = payload,
      ),
    );

    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存项目创建默认表达限制'));
    await tester.pumpAndSettle();

    expect(savedPayload, isNotNull);
    expect(savedPayload!['mode'], 'custom');
    expect(
      savedPayload!['profile_ids'],
      containsAll(<String>['de_ai', 'strict_pov_boundary']),
    );
  });

  testWidgets('panel can save disabled mode without loading defaults', (
    tester,
  ) async {
    Map<String, Object?>? savedPayload;
    await tester.pumpWidget(
      _buildHarness(
        viewData: const ProjectCreationExpressionConstraintDefaultsViewData(
          mode: ProjectCreationExpressionConstraintDefaultsMode.builtinFallback,
          fallbackSummary: '去 AI 风',
          options: <ProjectCreationExpressionConstraintOptionViewData>[
            ProjectCreationExpressionConstraintOptionViewData(
              id: 'de_ai',
              label: '去 AI 风',
              summary: 'summary',
              isSelected: true,
            ),
          ],
        ),
        onSaved: (payload) => savedPayload = payload,
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('不自动装载').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存项目创建默认表达限制'));
    await tester.pumpAndSettle();

    expect(savedPayload, isNotNull);
    expect(savedPayload!['mode'], 'disabled');
  });
}

Widget _buildHarness({
  required ProjectCreationExpressionConstraintDefaultsViewData viewData,
  required ValueChanged<Map<String, Object?>> onSaved,
}) {
  return MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: ProjectCreationExpressionConstraintDefaultsPanel(
        viewData: viewData,
        onSaved: onSaved,
      ),
    ),
  );
}
