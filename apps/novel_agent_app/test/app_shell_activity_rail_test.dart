import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/navigation/app_shell_navigation_action_handler.dart';
import 'package:novel_agent_app/app/navigation/app_shell_navigation_catalog.dart';
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
            sections: AppShellNavigationCatalog.sections(),
            selectedDestination: AppDestination.workbench,
            actionHandler: handler,
          ),
        ),
      ),
    );

    expect(find.text('创作'), findsOneWidget);
    expect(find.text('创作台'), findsOneWidget);
    expect(find.text('智能体生态'), findsOneWidget);

    await tester.tap(find.text('智能体生态'));
    await tester.pumpAndSettle();

    expect(handler.requestedDestinations, [AppDestination.agentEcosystem]);
  });

  test(
    'knowledge base primary workspace swaps workbench entry to project assets',
    () {
      final sections = AppShellNavigationCatalog.sections(
        projectAssetsPrimaryWorkspace: true,
      );
      final workspaceSection = sections.singleWhere(
        (section) => section.id == 'workspace',
      );
      expect(
        workspaceSection.items.first.destination,
        AppDestination.projectAssets,
      );
      expect(workspaceSection.items.first.label, '资料库');
    },
  );

  test('book deconstruction navigation requires the project capability', () {
    final unavailableItems = AppShellNavigationCatalog.sections()
        .singleWhere((section) => section.id == 'workspace')
        .items;
    final availableItems = AppShellNavigationCatalog.sections(
      hasBookDeconstructionCapability: true,
    ).singleWhere((section) => section.id == 'workspace').items;

    expect(
      unavailableItems.any(
        (item) => item.destination == AppDestination.bookDeconstruction,
      ),
      isFalse,
    );
    expect(
      availableItems.any(
        (item) => item.destination == AppDestination.bookDeconstruction,
      ),
      isTrue,
    );
  });

  test(
    'native book deconstruction uses analysis as its only primary workspace entry',
    () {
      final workspaceItems = AppShellNavigationCatalog.sections(
        bookDeconstructionPrimaryWorkspace: true,
        hasBookDeconstructionCapability: true,
      ).singleWhere((section) => section.id == 'workspace').items;

      expect(
        workspaceItems.first.destination,
        AppDestination.bookDeconstruction,
      );
      expect(workspaceItems.first.label, '拆书分析');
      expect(
        workspaceItems
            .where(
              (item) => item.destination == AppDestination.bookDeconstruction,
            )
            .length,
        1,
      );
      expect(
        workspaceItems.any(
          (item) => item.destination == AppDestination.workbench,
        ),
        isFalse,
      );
    },
  );
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
