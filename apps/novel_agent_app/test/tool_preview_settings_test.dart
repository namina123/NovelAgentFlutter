import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/tool_strategy_settings_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tool preview settings keep saved detail mode', (tester) async {
    _setViewport(tester);

    Map<String, Object?>? savedPayload;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ToolStrategySettingsPanel(
            settings: const <String, Object?>{
              'mode': 'balanced',
              'tool_preview_mode': 'detail',
            },
            onSaved: (payload) {
              savedPayload = payload;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('工具展示'), findsOneWidget);
    expect(find.text('会话区工具预览'), findsOneWidget);
    expect(find.text('细节'), findsOneWidget);

    await tester.tap(find.text('保存工具策略'));
    await tester.pumpAndSettle();

    expect(savedPayload, isNotNull);
    expect(savedPayload!['tool_preview_mode'], 'detail');
  });

  testWidgets('tool preview settings normalize invalid value back to compact', (
    tester,
  ) async {
    _setViewport(tester);

    Map<String, Object?>? savedPayload;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: ToolStrategySettingsPanel(
            settings: const <String, Object?>{
              'mode': 'balanced',
              'tool_preview_mode': 'unexpected',
            },
            onSaved: (payload) {
              savedPayload = payload;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存工具策略'));
    await tester.pumpAndSettle();

    expect(savedPayload, isNotNull);
    expect(savedPayload!['tool_preview_mode'], 'compact');
  });
}

void _setViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1400, 1800);
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}
