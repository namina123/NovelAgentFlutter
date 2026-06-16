import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/tool_strategy_settings_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'tool strategy settings panel saves compact tool preview mode by default',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 1800);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      Map<String, Object?>? savedPayload;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ToolStrategySettingsPanel(
              settings: const <String, Object?>{'mode': 'balanced'},
              onSaved: (payload) {
                savedPayload = payload;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('这里控制 AI 在已经暴露的工具里如何行动。它不负责权限放行，只负责执行风格与偏好。'),
        findsOneWidget,
      );
      final saveButton = find.text('保存工具策略');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(savedPayload, isNotNull);
      expect(savedPayload!['tool_preview_mode'], 'compact');
    },
  );
}
