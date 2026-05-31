import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/navigation/app_shell_navigation_action_handler.dart';
import 'package:novel_agent_app/app/routing/app_destination.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/shared/widgets/app_shell_compact_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('compact scaffold keeps drawer navigation available', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final handler = _FakeNavigationActionHandler();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppShellCompactScaffold(
          selectedDestination: AppDestination.workbench,
          actionHandler: handler,
          page: const ColoredBox(
            color: Color(0xFFF5F5F5),
            child: Center(child: Text('main-page')),
          ),
        ),
      ),
    );

    expect(find.text('main-page'), findsOneWidget);
    expect(find.text('功能入口'), findsNothing);

    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('功能入口'), findsOneWidget);
    expect(find.text('打开项目'), findsOneWidget);
    expect(find.text('工作台'), findsWidgets);
    expect(find.text('智能体生态'), findsOneWidget);
    expect(find.text('长任务'), findsOneWidget);

    await tester.tap(find.text('智能体生态'));
    await tester.pumpAndSettle();

    expect(handler.requestedDestinations, [AppDestination.agentEcosystem]);
    expect(find.text('功能入口'), findsNothing);
  });

  testWidgets('compact scaffold reserves bottom space for launcher dock', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppShellCompactScaffold(
          selectedDestination: AppDestination.workbench,
          actionHandler: _FakeNavigationActionHandler(),
          page: ColoredBox(
            color: const Color(0xFFF5F5F5),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                key: const ValueKey('page-footer'),
                width: 140,
                height: 40,
                color: const Color(0xFFB3D7E4),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final footerRect = tester.getRect(find.byKey(const ValueKey('page-footer')));
    final launcherRect = tester.getRect(
      find.byKey(const ValueKey('app-shell-compact-launcher')),
    );
    expect(footerRect.bottom, lessThanOrEqualTo(launcherRect.top));
  });

  testWidgets('compact scaffold hides expanded drawer panel while keyboard is visible', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(780, 1400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Widget buildScaffold({double keyboardInset = 0}) {
      return MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(390, 700),
            viewInsets: EdgeInsets.only(bottom: keyboardInset),
          ),
          child: AppShellCompactScaffold(
            selectedDestination: AppDestination.workbench,
            actionHandler: _FakeNavigationActionHandler(),
            page: const ColoredBox(color: Color(0xFFF5F5F5)),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildScaffold());
    await tester.tap(find.byIcon(Icons.menu_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('功能入口'), findsOneWidget);

    await tester.pumpWidget(buildScaffold(keyboardInset: 260));
    await tester.pumpAndSettle();

    expect(find.text('功能入口'), findsNothing);
    final launcherRect = tester.getRect(
      find.byKey(const ValueKey('app-shell-compact-launcher')),
    );
    expect(launcherRect.bottom, lessThanOrEqualTo(700 - 260));
  });
}

class _FakeNavigationActionHandler implements AppShellNavigationActionHandler {
  final List<AppDestination> requestedDestinations = <AppDestination>[];

  @override
  Future<void> onAppShellDestinationRequested(AppDestination destination) async {
    // 中文注释: 测试替身只记录导航意图，不引入真实控制器和路由装配。
    requestedDestinations.add(destination);
  }
}
