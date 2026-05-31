import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/task_center/presentation/widgets/task_center_detail_panel.dart';

void main() {
  testWidgets('TaskCenterDetailPanel shows resume brief body', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 900,
            height: 600,
            child: TaskCenterDetailPanel(
              title: '任务详情',
              subtitle: 'tasks/ch01.json',
              detailBody: '# 当前任务',
              resumeBriefBody: '## 恢复现场\n当前停在用户确认点\n\n建议下一步：处理检查点',
              queueSummary: '',
              schedulerSummary: '',
              guidanceRevisitBody: '',
            ),
          ),
        ),
      ),
    );

    expect(find.text('任务详情'), findsOneWidget);
    expect(find.textContaining('## 恢复现场'), findsOneWidget);
    expect(find.textContaining('当前停在用户确认点'), findsOneWidget);
    expect(find.textContaining('建议下一步：处理检查点'), findsOneWidget);
  });
}
