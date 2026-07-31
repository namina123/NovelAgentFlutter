import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/settings/presentation/widgets/permissions_settings_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('permissions settings panel saves aligned mode aliases', (
    tester,
  ) async {
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
          body: PermissionsSettingsPanel(
            settings: const <String, Object?>{'mode': 'safe'},
            onSaved: (payload) {
              savedPayload = payload;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('这里定义应用允许哪些能力真正进入执行链。工具策略决定「AI 倾向怎么用工具」，这里只决定「应用是否允许做」。'), findsOneWidget);
    expect(find.text('允许调用本机程序'), findsOneWidget);

    await tester.tap(find.text('保存权限设置'));
    await tester.pumpAndSettle();

    expect(savedPayload, isNotNull);
    expect(savedPayload!['mode'], 'safe');
    expect(savedPayload!['permission_mode'], 'safe');
    expect(savedPayload!['tool_permission_mode'], 'safe');
    expect(savedPayload!['information_permission_mode'], 'safe');
    expect(savedPayload!['confirmation_mode'], 'user_confirmation_required');
    expect(savedPayload!['allow_formal_delivery'], isTrue);
    expect(savedPayload!['allow_sub_agents'], isTrue);
    expect(savedPayload!['allow_long_task_control'], isTrue);
  });
}
