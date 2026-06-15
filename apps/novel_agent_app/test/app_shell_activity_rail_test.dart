import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/navigation/app_shell_navigation_action_handler.dart';
import 'package:novel_agent_app/app/routing/app_destination.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/shared/widgets/app_shell_activity_rail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('activity rail exposes agent ecosystem in workspace section', (
    WidgetTester tester,
  ) async {
    final handler = _FakeNavigationActionHandler();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppShellActivityRail(
            selectedDestination: AppDestination.workbench,
            actionHandler: handler,
          ),
        ),
      ),
    );

    expect(find.text('工作'), findsOneWidget);
    expect(find.text('工作台'), findsOneWidget);
    expect(find.text('智能体生态'), findsOneWidget);

    await tester.tap(find.text('智能体生态'));
    await tester.pumpAndSettle();

    expect(handler.requestedDestinations, [AppDestination.agentEcosystem]);
  });
}

class _FakeNavigationActionHandler implements AppShellNavigationActionHandler {
  final List<AppDestination> requestedDestinations = <AppDestination>[];

  @override
  Future<void> onAppShellDestinationRequested(
    AppDestination destination,
  ) async {
    requestedDestinations.add(destination);
  }
}
