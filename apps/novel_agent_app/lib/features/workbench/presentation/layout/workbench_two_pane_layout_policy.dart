import '../../../../app/layout/app_layout_metrics.dart';

class WorkbenchTwoPaneLayoutPolicy {
  const WorkbenchTwoPaneLayoutPolicy._();

  static double conversationWidth(
    AppLayoutMetrics metrics,
    double totalWidth, {
    double? preferredWidth,
  }) {
    // 中文注释: 双栏模式下的会话栏宽度独立成策略，后续改窄屏横屏体验时只需调整这里。
    final targetWidth =
        preferredWidth ?? (metrics.isTabletLike ? 380.0 : 344.0);
    final minWidth = metrics.isTabletLike ? 336.0 : 316.0;
    final maxWidth = metrics.isTabletLike ? 412.0 : 376.0;
    final widthByRatio = totalWidth * 0.355;
    final resolvedMax = widthByRatio < minWidth ? minWidth : widthByRatio;
    final upperBound = resolvedMax > maxWidth ? maxWidth : resolvedMax;
    if (targetWidth < minWidth) {
      return minWidth;
    }
    if (targetWidth > upperBound) {
      return upperBound;
    }
    return targetWidth;
  }
}
