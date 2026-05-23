import 'package:flutter/widgets.dart';

import 'app_layout_metrics.dart';

class AppLayoutScope extends InheritedWidget {
  const AppLayoutScope({
    super.key,
    required this.metrics,
    required super.child,
  });

  final AppLayoutMetrics metrics;

  static AppLayoutMetrics of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLayoutScope>();
    assert(scope != null, 'AppLayoutScope not found in context');
    return scope!.metrics;
  }

  @override
  bool updateShouldNotify(AppLayoutScope oldWidget) {
    // 中文注释: 只有布局指标变化时才通知依赖者，避免普通状态刷新导致所有自适应组件重复重建。
    return metrics != oldWidget.metrics;
  }
}
