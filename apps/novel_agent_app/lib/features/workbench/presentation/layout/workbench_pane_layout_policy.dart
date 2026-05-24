import '../../../../app/layout/app_layout_metrics.dart';

class WorkbenchPaneLayoutPolicy {
  static const double dividerWidth = 10;

  static const double _desktopMinLeftWidth = 236;
  static const double _desktopMinDocumentWidth = 520;
  static const double _desktopMinConversationWidth = 380;
  static const double _desktopMaxConversationWidth = 480;
  static const double _desktopMaxConversationRatio = 0.34;

  static const double _compactWideMinLeftWidth = 272;
  static const double _compactWideMaxLeftWidth = 336;
  static const double _compactWideMinDocumentWidth = 440;
  static const double _compactWideMinConversationWidth = 460;
  static const double _compactWideMaxConversationWidth = 560;
  static const double _compactWideMaxConversationRatio = 0.35;

  const WorkbenchPaneLayoutPolicy._();

  static bool useCompactWideLayout(AppLayoutMetrics metrics) {
    // 中文注释: 横屏小屏设备在三栏模式下需要更保守的宽度约束，避免聊天栏和正文栏都被压得太碎。
    return metrics.isLandscape && !metrics.isTabletLike;
  }

  static double minLeftWidth(AppLayoutMetrics metrics) {
    // 中文注释: 左栏最小宽度优先保证项目树和工具按钮能稳定显示，不因拖拽变成不可用窄条。
    return useCompactWideLayout(metrics)
        ? _compactWideMinLeftWidth
        : _desktopMinLeftWidth;
  }

  static double maxLeftWidth(double totalWidth, AppLayoutMetrics metrics) {
    // 中文注释: 左栏最大宽度做上限，避免资源栏吞掉正文区的主要阅读和编辑空间。
    if (useCompactWideLayout(metrics)) {
      return _clamp(
        totalWidth * 0.24,
        _compactWideMinLeftWidth,
        _compactWideMaxLeftWidth,
      );
    }
    return _clamp(totalWidth * 0.28, _desktopMinLeftWidth, totalWidth);
  }

  static double minDocumentWidth(AppLayoutMetrics metrics) {
    // 中文注释: 正文区最小宽度集中在这里约束，让桌面和横屏移动端都能保持可读的正文列宽。
    return useCompactWideLayout(metrics)
        ? _compactWideMinDocumentWidth
        : _desktopMinDocumentWidth;
  }

  static double minConversationWidth(AppLayoutMetrics metrics) {
    // 中文注释: 会话栏最小宽度需要保证模型、选项和输入区都还能正常摆开。
    return useCompactWideLayout(metrics)
        ? _compactWideMinConversationWidth
        : _desktopMinConversationWidth;
  }

  static double maxConversationWidth(
    double totalWidth,
    AppLayoutMetrics metrics,
  ) {
    // 中文注释: 会话栏最大宽度使用比例和绝对值双重约束，避免右栏在超宽桌面上过胖。
    if (useCompactWideLayout(metrics)) {
      return _clamp(
        totalWidth * _compactWideMaxConversationRatio,
        _compactWideMinConversationWidth,
        _compactWideMaxConversationWidth,
      );
    }
    return _clamp(
      totalWidth * _desktopMaxConversationRatio,
      _desktopMinConversationWidth,
      _desktopMaxConversationWidth,
    );
  }

  static double defaultLeftWidth(double totalWidth, AppLayoutMetrics metrics) {
    // 中文注释: 默认左栏宽度取旧项目理念里的“可扫读但不喧宾夺主”区间，用来初始化和重置布局。
    final target = useCompactWideLayout(metrics) ? 296.0 : 252.0;
    return _clamp(
      target,
      minLeftWidth(metrics),
      maxLeftWidth(totalWidth, metrics),
    );
  }

  static double defaultConversationWidth(
    double totalWidth,
    AppLayoutMetrics metrics,
  ) {
    // 中文注释: 默认右栏宽度优先保证会话与输入舒适，再由正文区吃掉剩余空间。
    final target = useCompactWideLayout(metrics) ? 500.0 : 420.0;
    return _clamp(
      target,
      minConversationWidth(metrics),
      maxConversationWidth(totalWidth, metrics),
    );
  }

  static double clampLeftWidth(
    double proposedWidth,
    double totalWidth,
    AppLayoutMetrics metrics, {
    required double rightWidth,
  }) {
    // 中文注释: 左栏拖拽时要为正文区和右栏预留最小空间，防止拖拽把布局带进死角。
    final maxWidth =
        totalWidth - rightWidth - minDocumentWidth(metrics) - dividerWidth * 2;
    return _clamp(
      proposedWidth,
      minLeftWidth(metrics),
      maxWidth < minLeftWidth(metrics) ? minLeftWidth(metrics) : maxWidth,
    );
  }

  static double clampConversationWidth(
    double proposedWidth,
    double totalWidth,
    AppLayoutMetrics metrics, {
    required double leftWidth,
  }) {
    // 中文注释: 右栏拖拽时同样要为正文区和左栏留足空间，同时遵守右栏自身的上限策略。
    final maxWidthByDocument =
        totalWidth - leftWidth - minDocumentWidth(metrics) - dividerWidth * 2;
    final maxWidth = maxWidthByDocument < minConversationWidth(metrics)
        ? minConversationWidth(metrics)
        : maxWidthByDocument;
    return _clamp(
      proposedWidth,
      minConversationWidth(metrics),
      _clamp(
        maxWidth,
        minConversationWidth(metrics),
        maxConversationWidth(totalWidth, metrics),
      ),
    );
  }

  static double _clamp(double value, double min, double max) {
    // 中文注释: 简单数值夹取统一收口，避免布局策略到处散落重复的边界判断。
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}
