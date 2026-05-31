import 'package:flutter/foundation.dart';

class AppShellCompactDrawerController extends ChangeNotifier {
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  void open() {
    // 中文注释: 抽拉栏状态单独托管，避免紧凑布局把显隐 bool 再塞回根壳层或页面组件。
    _setOpen(true);
  }

  void close() {
    // 中文注释: 关闭动作既服务导航完成后的收口，也服务点空白区域时的快速收起。
    _setOpen(false);
  }

  void toggle() {
    // 中文注释: 紧凑布局入口只关心切换开闭，不直接触摸具体页面结构。
    _setOpen(!_isOpen);
  }

  void _setOpen(bool nextValue) {
    if (_isOpen == nextValue) {
      return;
    }
    _isOpen = nextValue;
    notifyListeners();
  }
}
