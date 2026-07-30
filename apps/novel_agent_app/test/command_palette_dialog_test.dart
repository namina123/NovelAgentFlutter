import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/app/theme/app_theme.dart';
import 'package:novel_agent_app/features/command_palette/application/command_palette_controller.dart';
import 'package:novel_agent_app/features/command_palette/application/command_registry.dart';
import 'package:novel_agent_app/features/command_palette/domain/command.dart';
import 'package:novel_agent_app/features/command_palette/presentation/command_palette_dialog.dart';

CommandRegistry _registry(List<String> invoked) {
  return CommandRegistry()
    ..register(AppCommand(
      id: 'settings',
      title: '前往：设置',
      category: CommandCategory.navigation,
      keywords: const ['设置', 'settings'],
      invoke: () => invoked.add('settings'),
    ))
    ..register(AppCommand(
      id: 'save',
      title: '保存当前文档',
      category: CommandCategory.document,
      keywords: const ['save'],
      invoke: () => invoked.add('save'),
    ));
}

Widget _harness(CommandPaletteController controller) {
  return MaterialApp(
    theme: AppTheme.themeDataFor('builtin.light'),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showCommandPalette(context, controller: controller),
            child: const Text('open-palette'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openPalette(WidgetTester tester) async {
  await tester.tap(find.text('open-palette'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('打开即展示全部命令，输入过滤，回车执行并关闭面板', (tester) async {
    final invoked = <String>[];
    final controller = CommandPaletteController(_registry(invoked));
    await tester.pumpWidget(_harness(controller));
    await _openPalette(tester);

    // 中文注释: 空 query 展示全部命令；导航类（index 0）排在前。
    expect(find.text('前往：设置'), findsOneWidget);
    expect(find.text('保存当前文档'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);

    // 输入「设置」收窄到一条。
    await tester.enterText(find.byType(TextField), '设置');
    await tester.pump();
    expect(find.text('前往：设置'), findsOneWidget);
    expect(find.text('保存当前文档'), findsNothing);

    // 回车执行当前选中（前往：设置）并关闭面板。
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(invoked, ['settings']);
    expect(find.text('输入命令名或关键词…'), findsNothing);
  });

  testWidgets('上下方向键移动选中并在首尾回绕', (tester) async {
    final invoked = <String>[];
    final controller = CommandPaletteController(_registry(invoked));
    await tester.pumpWidget(_harness(controller));
    await _openPalette(tester);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    expect(find.text('1/2'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.text('2/2'), findsOneWidget);

    // 再次向下回绕回第一项。
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.text('1/2'), findsOneWidget);

    // 在第一项按上方向键，回绕到末尾。
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(find.text('2/2'), findsOneWidget);
    expect(invoked, isEmpty);
  });

  testWidgets('Home/End 直接跳到首尾', (tester) async {
    final invoked = <String>[];
    final controller = CommandPaletteController(_registry(invoked));
    await tester.pumpWidget(_harness(controller));
    await _openPalette(tester);

    expect(find.text('1/2'), findsOneWidget);
    // 中文注释: End 跳到末尾、Home 跳回首，覆盖新增的整页跳转键。
    await tester.sendKeyDownEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(find.text('2/2'), findsOneWidget);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(find.text('1/2'), findsOneWidget);
    expect(invoked, isEmpty);
  });

  testWidgets('Escape 关闭面板且不执行任何命令', (tester) async {
    final invoked = <String>[];
    final controller = CommandPaletteController(_registry(invoked));
    await tester.pumpWidget(_harness(controller));
    await _openPalette(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('输入命令名或关键词…'), findsNothing);
    expect(invoked, isEmpty);
  });

  testWidgets('点击命中项直接执行该命令', (tester) async {
    final invoked = <String>[];
    final controller = CommandPaletteController(_registry(invoked));
    await tester.pumpWidget(_harness(controller));
    await _openPalette(tester);

    await tester.tap(find.text('保存当前文档'));
    await tester.pumpAndSettle();
    expect(invoked, ['save']);
    expect(find.text('输入命令名或关键词…'), findsNothing);
  });

  testWidgets('无匹配时展示空态', (tester) async {
    final invoked = <String>[];
    final controller = CommandPaletteController(_registry(invoked));
    await tester.pumpWidget(_harness(controller));
    await _openPalette(tester);

    await tester.enterText(find.byType(TextField), '完全不存在的命令xyz');
    await tester.pump();
    expect(find.text('没有匹配的命令'), findsOneWidget);
    expect(find.text('无结果'), findsOneWidget);
  });
}
