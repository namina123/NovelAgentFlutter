import 'package:flutter/foundation.dart';

import '../domain/command.dart';
import 'command_registry.dart';
import 'command_search.dart';

/// 命令面板的视图状态控制器。
///
/// 持有当前查询、命中列表与选中下标，通过 [notifyListeners] 驱动面板重建。
/// 面板每次打开都新建一个实例并在 [open] 时重置；关闭后即可 [dispose]。
class CommandPaletteController extends ChangeNotifier {
  CommandPaletteController(this._registry);

  final CommandRegistry _registry;

  String _query = '';
  List<ScoredCommand> _results = const <ScoredCommand>[];
  int _selectedIndex = 0;
  bool _isOpen = false;

  /// 当前查询字符串。
  String get query => _query;

  /// 当前命中结果（已排序）。
  List<ScoredCommand> get results => _results;

  /// 当前选中项下标。
  int get selectedIndex => _selectedIndex;

  /// 面板是否处于打开状态。
  bool get isOpen => _isOpen;

  /// 命中结果数量。
  int get resultCount => _results.length;

  /// 面板打开时重置查询并计算初始命中（全部可用命令）。
  void open() {
    _isOpen = true;
    _query = '';
    _selectedIndex = 0;
    _results = searchCommands(_registry.all, '');
    notifyListeners();
  }

  /// 更新查询并重新计算命中与选中下标。
  void setQuery(String query) {
    _query = query;
    _selectedIndex = 0;
    _results = searchCommands(_registry.all, query);
    notifyListeners();
  }

  /// 将选中下标移动 [delta]（通常 +1 / -1）；列表首尾回绕。
  void moveSelection(int delta) {
    if (_results.isEmpty) return;
    final length = _results.length;
    // 中文注释: 两次取模保证任意 delta（含负数）都落到 [0, length)。
    _selectedIndex = ((_selectedIndex + delta) % length + length) % length;
    notifyListeners();
  }

  /// 直接设定选中下标（来自鼠标悬停）；越界时自动夹取。
  void selectIndex(int index) {
    if (_results.isEmpty) return;
    final clamped = index.clamp(0, _results.length - 1);
    if (_selectedIndex == clamped) return;
    _selectedIndex = clamped;
    notifyListeners();
  }

  /// 当前选中的命令；列表为空或下标越界时返回 null。
  AppCommand? get selectedCommand {
    if (_results.isEmpty || _selectedIndex >= _results.length) {
      return null;
    }
    return _results[_selectedIndex].command;
  }
}
