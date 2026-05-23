class DocumentsWorkspaceLayoutPolicy {
  const DocumentsWorkspaceLayoutPolicy._();

  static double minNavigationWidth(double totalWidth) {
    // 中文注释: 文档工作区的资源栏宽度独立成策略，便于以后按设备族继续细分。
    return totalWidth < 780 ? 220.0 : 248.0;
  }

  static double maxNavigationWidth(double totalWidth) {
    final candidate = totalWidth < 780 ? totalWidth * 0.44 : 320.0;
    final minWidth = minNavigationWidth(totalWidth);
    return candidate < minWidth ? minWidth : candidate;
  }

  static double defaultNavigationWidth(double totalWidth) {
    final preferredWidth = totalWidth < 780 ? 240.0 : 272.0;
    final minWidth = minNavigationWidth(totalWidth);
    final maxWidth = maxNavigationWidth(totalWidth);
    if (preferredWidth < minWidth) {
      return minWidth;
    }
    if (preferredWidth > maxWidth) {
      return maxWidth;
    }
    return preferredWidth;
  }
}
