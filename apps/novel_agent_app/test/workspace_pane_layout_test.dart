import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/scroll/app_scroll_behavior.dart';
import 'package:novel_agent_app/shared/widgets/workspace_pane_layout.dart';

void main() {
  test('app scroll behavior supports mouse and touch dragging', () {
    const behavior = AppScrollBehavior();

    expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
    expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
  });

  testWidgets(
    'workspace pane layout adds horizontal overflow scrolling when panes exceed width',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 420,
              child: WorkspacePaneLayout(
                breakpoint: 600,
                leadingPaneWidth: 280,
                trailingPaneWidth: 340,
                mainPaneMinWidth: 560,
                leadingPane: ColoredBox(color: Colors.red),
                mainPane: ColoredBox(color: Colors.green),
                trailingPane: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Scrollbar), findsOneWidget);
    },
  );
}
