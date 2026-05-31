import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/layout/app_layout_metrics.dart';
import 'package:novel_agent_app/app/layout/app_layout_mode.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/workbench/presentation/layout/workbench_pane_layout_policy.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/pane_resize_divider.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/resizable_workbench_layout.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_desktop_section_id.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_desktop_surface.dart';
import 'package:novel_agent_app/features/workbench/presentation/widgets/workbench_pane_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop workbench shell keeps three-pane structure', (
    WidgetTester tester,
  ) async {
    final metrics = AppLayoutMetrics(
      size: const Size(1600, 1000),
      shortestSide: 1000,
      orientation: Orientation.landscape,
      viewInsetsBottom: 0,
      devicePixelRatio: 1,
      mode: AppLayoutMode.expanded,
      isTabletLike: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox.expand(
            child: WorkbenchDesktopSurface(
              child: ResizableWorkbenchLayout(
                metrics: metrics,
                leftPane: const WorkbenchPaneShell(
                  sectionId: WorkbenchDesktopSectionId.navigation,
                  showLeftOuterBorder: true,
                  child: SizedBox.expand(
                    key: Key('left-pane'),
                    child: Center(child: Text('left-pane')),
                  ),
                ),
                documentPane: const WorkbenchPaneShell(
                  sectionId: WorkbenchDesktopSectionId.primaryCanvas,
                  child: SizedBox.expand(
                    key: Key('document-pane'),
                    child: Center(child: Text('document-pane')),
                  ),
                ),
                conversationPane: const WorkbenchPaneShell(
                  sectionId: WorkbenchDesktopSectionId.collaboration,
                  showRightOuterBorder: true,
                  child: SizedBox.expand(
                    key: Key('conversation-pane'),
                    child: Center(child: Text('conversation-pane')),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(WorkbenchDesktopSurface), findsOneWidget);
    expect(find.byType(WorkbenchPaneShell), findsNWidgets(3));
    expect(find.byType(PaneResizeDivider), findsNWidgets(2));
    expect(find.text('left-pane'), findsOneWidget);
    expect(find.text('document-pane'), findsOneWidget);
    expect(find.text('conversation-pane'), findsOneWidget);

    expect(
      tester.getSize(find.byKey(PaneResizeDivider.shellKey).first).width,
      WorkbenchPaneLayoutPolicy.dividerWidth,
    );
    expect(
      tester.getSize(find.byKey(PaneResizeDivider.hitAreaKey).first).width,
      WorkbenchPaneLayoutPolicy.dividerHitWidth,
    );

    final leftPaneRight = tester.getTopRight(
      find.byKey(const Key('left-pane')),
    );
    final dividerLeft = tester.getTopLeft(
      find.byKey(PaneResizeDivider.lineKey).first,
    );
    final dividerRight = tester.getTopRight(
      find.byKey(PaneResizeDivider.lineKey).first,
    );
    final documentPaneLeft = tester.getTopLeft(
      find.byKey(const Key('document-pane')),
    );

    expect(dividerLeft.dx, closeTo(leftPaneRight.dx, 0.1));
    expect(documentPaneLeft.dx, closeTo(dividerRight.dx, 0.1));
  });

  test(
    'desktop pane layout policy keeps document pane dominant by default',
    () {
      final metrics = AppLayoutMetrics(
        size: const Size(1600, 1000),
        shortestSide: 1000,
        orientation: Orientation.landscape,
        viewInsetsBottom: 0,
        devicePixelRatio: 1,
        mode: AppLayoutMode.expanded,
        isTabletLike: true,
      );
      const totalWidth = 1600.0;
      final leftWidth = WorkbenchPaneLayoutPolicy.defaultLeftWidth(
        totalWidth,
        metrics,
      );
      final conversationWidth =
          WorkbenchPaneLayoutPolicy.defaultConversationWidth(
            totalWidth,
            metrics,
          );
      final documentWidth =
          totalWidth -
          leftWidth -
          conversationWidth -
          WorkbenchPaneLayoutPolicy.dividerWidth * 2;

      expect(leftWidth, inInclusiveRange(252, 312));
      expect(conversationWidth, inInclusiveRange(360, 456));
      expect(documentWidth, greaterThan(560));
      expect(documentWidth, greaterThan(conversationWidth));
    },
  );
}
