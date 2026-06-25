import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/agent_ecosystem/presentation/widgets/ecosystem_member_select_dialog.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';

const List<SelectorOptionViewData> _skills = <SelectorOptionViewData>[
  SelectorOptionViewData(id: 'summarize', label: '章节摘要', note: 'summarize'),
  SelectorOptionViewData(id: 'continuity', label: '连续性检查', note: 'continuity'),
  SelectorOptionViewData(id: 'world_consistency', label: '世界一致性', note: 'world_consistency'),
];

void main() {
  testWidgets('shows options, honors initial selection, confirms toggled set', (
    WidgetTester tester,
  ) async {
    Set<String>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showEcosystemMemberSelectDialog(
                    context: context,
                    title: '技能列表',
                    options: _skills,
                    initiallySelected: const <String>{'summarize'},
                    emptyHint: '无',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 初始选中 summarize。
    expect(find.text('已选 1 / 共 3'), findsOneWidget);
    expect(find.text('章节摘要'), findsOneWidget);
    expect(find.text('连续性检查'), findsOneWidget);

    // 勾选"连续性检查"。
    await tester.tap(find.text('连续性检查'));
    await tester.pump();
    expect(find.text('已选 2 / 共 3'), findsOneWidget);

    // 确认 → 返回两个。
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    expect(result, <String>{'summarize', 'continuity'});
  });

  testWidgets('cancel returns the original selection unchanged', (
    WidgetTester tester,
  ) async {
    Set<String>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showEcosystemMemberSelectDialog(
                    context: context,
                    title: '技能列表',
                    options: _skills,
                    initiallySelected: const <String>{'summarize'},
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // 改了选择，但点取消 → 应回到原选中。
    await tester.tap(find.text('连续性检查'));
    await tester.pump();
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(result, <String>{'summarize'});
  });

  testWidgets('shows empty hint when there are no options', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => showEcosystemMemberSelectDialog(
                  context: context,
                  title: '技能列表',
                  options: const <SelectorOptionViewData>[],
                  initiallySelected: const <String>{},
                  emptyHint: '还没有可用的技能',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('还没有可用的技能'), findsOneWidget);
  });
}
