class OpenDocumentState {
  const OpenDocumentState({
    required this.id,
    required this.title,
    required this.relativePath,
    required this.content,
    this.isDirty = false,
    this.isRendered = false,
  });

  final String id;
  final String title;
  final String relativePath;
  final String content;
  final bool isDirty;
  final bool isRendered;

  bool get canRender {
    final lowerPath = relativePath.toLowerCase();
    return lowerPath.endsWith('.md') || lowerPath.endsWith('.markdown');
  }

  OpenDocumentState copyWith({
    String? id,
    String? title,
    String? relativePath,
    String? content,
    bool? isDirty,
    bool? isRendered,
  }) {
    // 中文注释: 打开文档状态需要频繁做局部变更，这里统一提供最小 copy 能力。
    return OpenDocumentState(
      id: id ?? this.id,
      title: title ?? this.title,
      relativePath: relativePath ?? this.relativePath,
      content: content ?? this.content,
      isDirty: isDirty ?? this.isDirty,
      isRendered: isRendered ?? this.isRendered,
    );
  }
}
