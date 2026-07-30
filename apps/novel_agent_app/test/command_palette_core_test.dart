import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/command_palette/application/command_palette_controller.dart';
import 'package:novel_agent_app/features/command_palette/application/command_registry.dart';
import 'package:novel_agent_app/features/command_palette/application/command_search.dart';
import 'package:novel_agent_app/features/command_palette/domain/command.dart';

AppCommand _cmd(
  String id,
  String title,
  CommandCategory category, {
  List<String> keywords = const <String>[],
  bool Function()? isEnabled,
}) {
  return AppCommand(
    id: id,
    title: title,
    category: category,
    keywords: keywords,
    isEnabled: isEnabled,
    invoke: () {},
  );
}

void main() {
  group('CommandRegistry', () {
    test('注册后可按 id 查找并出现在 all/visibleCommands', () {
      final registry = CommandRegistry()
        ..register(_cmd('a', '前往：设置', CommandCategory.navigation));
      expect(registry.findById('a'), isNotNull);
      expect(registry.length, 1);
      expect(registry.all.single.id, 'a');
      expect(registry.visibleCommands().single.id, 'a');
    });

    test('visibleCommands 过滤掉 enabled=false 的命令', () {
      final registry = CommandRegistry()
        ..register(_cmd('a', '可见', CommandCategory.navigation))
        ..register(_cmd(
          'b',
          '隐藏',
          CommandCategory.navigation,
          isEnabled: () => false,
        ));
      expect(registry.all.length, 2);
      expect(registry.visibleCommands().map((c) => c.id), ['a']);
    });

    test('同 id 注册后者覆盖前者', () {
      final registry = CommandRegistry()
        ..register(_cmd('a', '旧标题', CommandCategory.navigation))
        ..register(_cmd('a', '新标题', CommandCategory.navigation));
      expect(registry.length, 1);
      expect(registry.findById('a')!.title, '新标题');
    });
  });

  group('searchCommands', () {
    late List<AppCommand> cmds;

    setUp(() {
      cmds = [
        _cmd('save', '保存当前文档', CommandCategory.document, keywords: ['save']),
        _cmd('settings', '前往：设置', CommandCategory.navigation,
            keywords: ['设置', 'settings']),
        _cmd('new_file', '新建文件', CommandCategory.document,
            keywords: ['new file']),
      ];
    });

    test('空 query 返回全部可用，按「分类→标题」排序', () {
      // 导航(index 0)在前；文档(index 1)中按标题：保存 < 新建。
      final result = searchCommands(cmds, '');
      expect(result.map((e) => e.command.id), ['settings', 'save', 'new_file']);
    });

    test('标题完全相等得分最高且排在最前', () {
      final result = searchCommands(cmds, '保存当前文档');
      expect(result.single.command.id, 'save');
      expect(result.single.score, 1000);
    });

    test('前缀匹配优先于普通包含', () {
      final result = searchCommands(cmds, '前往');
      expect(result.single.command.id, 'settings');
      expect(result.single.score, 600);
    });

    test('中文包含命中', () {
      final result = searchCommands(cmds, '设置');
      expect(result.single.command.id, 'settings');
    });

    test('关键词完全相等命中', () {
      final result = searchCommands(cmds, 'settings');
      expect(result.single.command.id, 'settings');
      expect(result.single.score, 250);
    });

    test('子序列模糊命中（拉丁缩写）', () {
      // 'sa e' 作为 'save' 的子序列：s-a-v-e 中取 s,a,e。
      final result = searchCommands(cmds, 'sae');
      expect(result.single.command.id, 'save');
    });

    test('无任何匹配返回空列表', () {
      expect(searchCommands(cmds, 'zzz不存在的命令'), isEmpty);
    });

    test('不可用命令即使在空 query 下也被排除', () {
      final withDisabled = [
        ...cmds,
        _cmd('hidden', '隐藏命令', CommandCategory.navigation,
            isEnabled: () => false),
      ];
      final empty = searchCommands(withDisabled, '');
      expect(empty.map((e) => e.command.id), isNot(contains('hidden')));
      expect(searchCommands(withDisabled, '隐藏命令'), isEmpty);
    });
  });

  group('CommandPaletteController', () {
    late CommandRegistry registry;

    setUp(() {
      registry = CommandRegistry()
        ..register(_cmd('a', '前往：设置', CommandCategory.navigation))
        ..register(_cmd('b', '保存当前文档', CommandCategory.document))
        ..register(_cmd('c', '新建文件', CommandCategory.document));
    });

    test('open 重置查询并填充初始命中', () {
      final controller = CommandPaletteController(registry);
      controller.open();
      expect(controller.isOpen, isTrue);
      expect(controller.query, isEmpty);
      expect(controller.resultCount, 3);
      expect(controller.selectedIndex, 0);
    });

    test('setQuery 收窄命中并把选中重置到 0', () {
      final controller = CommandPaletteController(registry)..open();
      controller.setQuery('设置');
      expect(controller.resultCount, 1);
      expect(controller.selectedCommand!.id, 'a');
      controller.setQuery('');
      expect(controller.resultCount, 3);
      expect(controller.selectedIndex, 0);
    });

    test('moveSelection 上下移动并在首尾回绕', () {
      final controller = CommandPaletteController(registry)..open();
      expect(controller.selectedIndex, 0);
      controller.moveSelection(1);
      expect(controller.selectedIndex, 1);
      controller.moveSelection(1);
      expect(controller.selectedIndex, 2);
      controller.moveSelection(1); // 回绕到 0
      expect(controller.selectedIndex, 0);
      controller.moveSelection(-1); // 回绕到末尾
      expect(controller.selectedIndex, 2);
    });

    test('空结果时 moveSelection 不抛错也不改下标', () {
      final controller = CommandPaletteController(registry)
        ..open()
        ..setQuery('不存在的命令');
      expect(controller.resultCount, 0);
      controller.moveSelection(1);
      expect(controller.selectedIndex, 0);
      expect(controller.selectedCommand, isNull);
    });

    test('selectIndex 夹取越界值', () {
      final controller = CommandPaletteController(registry)..open();
      controller.selectIndex(100);
      expect(controller.selectedIndex, 2);
      controller.selectIndex(-5);
      expect(controller.selectedIndex, 0);
    });

    test('状态变化时通知监听器', () {
      final controller = CommandPaletteController(registry);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.open();
      controller.setQuery('设置');
      controller.moveSelection(1);
      expect(notifications, greaterThanOrEqualTo(3));
    });

    test('selectedCommand 返回当前选中项', () {
      final controller = CommandPaletteController(registry)..open();
      controller.moveSelection(2);
      expect(controller.selectedCommand!.id, 'c');
    });
  });
}
