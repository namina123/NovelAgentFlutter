import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/shared/widgets/action_button.dart';

void main() {
  testWidgets('action button keeps long chinese label inside narrow width', (
    tester,
  ) async {
    _setViewport(tester, const Size(360, 640));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 152,
              child: ActionButton(
                label: '这是一个用于窄宽度回归验证的超长中文动作按钮文案',
                labelMaxLines: 2,
                icon: Icons.auto_fix_high_rounded,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('这是一个用于窄宽度回归验证的超长中文动作按钮文案'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
