class SourceDocumentFormatCatalogService {
  const SourceDocumentFormatCatalogService();

  static const String plainTextFormatId = 'plain_text';
  static const String markdownFormatId = 'markdown';
  static const String epubFormatId = 'epub';

  List<SourceDocumentFormatDescriptor> get knownFormats {
    // 中文注释: 格式目录集中表达 reader 可处理的文件类型，后续扩展只需增加 descriptor，不要在各处硬编码扩展名。
    return const <SourceDocumentFormatDescriptor>[
      SourceDocumentFormatDescriptor(
        formatId: plainTextFormatId,
        mediaType: 'text/plain',
        fileExtensions: <String>['.txt'],
        readerKind: plainTextFormatId,
      ),
      SourceDocumentFormatDescriptor(
        formatId: markdownFormatId,
        mediaType: 'text/markdown',
        fileExtensions: <String>['.md', '.markdown'],
        readerKind: plainTextFormatId,
      ),
      SourceDocumentFormatDescriptor(
        formatId: epubFormatId,
        mediaType: 'application/epub+zip',
        fileExtensions: <String>['.epub'],
        readerKind: epubFormatId,
      ),
    ];
  }

  SourceDocumentFormatDescriptor? resolveByPath(String sourceFilePath) {
    // 中文注释: 这里只按文件扩展名路由格式，不在这里做内容嗅探，避免 discovery 与 reader 之间互相反转职责。
    final normalized = _normalizedPath(sourceFilePath);
    for (final descriptor in knownFormats) {
      if (descriptor.matchesPath(normalized)) {
        return descriptor;
      }
    }
    return null;
  }

  bool supportsPath(String sourceFilePath) {
    // 中文注释: 支持判断集中在格式目录里，directory scan 和 picker filter 都从同一处取真相。
    return resolveByPath(sourceFilePath) != null;
  }

  String mediaTypeForPath(String sourceFilePath) {
    // 中文注释: 媒体类型由格式目录统一提供，避免调用方自己根据扩展名拼字符串。
    return resolveByPath(sourceFilePath)?.mediaType ?? '';
  }

  String readerKindForPath(String sourceFilePath) {
    // 中文注释: readerKind 用于把文件路由到具体 reader 实现，后续新增格式时只需要扩展目录与 reader 绑定。
    return resolveByPath(sourceFilePath)?.readerKind ?? '';
  }

  String buildOpenFileDialogFilter() {
    // 中文注释: 桌面文件选择器复用统一格式目录，确保 UI 提示和后端可读格式保持一致。
    final segments = <String>[
      '文本与 Markdown|*.txt;*.md;*.markdown',
      'EPUB|*.epub',
      '所有文件|*.*',
    ];
    return segments.join('|');
  }

  String _normalizedPath(String sourceFilePath) {
    // 中文注释: 路径仅做轻量归一化，避免目录目录扫描时被平台分隔符干扰。
    return sourceFilePath.replaceAll('\\', '/').trim().toLowerCase();
  }
}

class SourceDocumentFormatDescriptor {
  const SourceDocumentFormatDescriptor({
    required this.formatId,
    required this.mediaType,
    required this.fileExtensions,
    required this.readerKind,
  });

  final String formatId;
  final String mediaType;
  final List<String> fileExtensions;
  final String readerKind;

  bool matchesPath(String sourceFilePath) {
    // 中文注释: descriptor 只根据扩展名判断是否匹配，实际内容解析交给具体 reader。
    final normalized = sourceFilePath
        .replaceAll('\\', '/')
        .trim()
        .toLowerCase();
    return fileExtensions.any(normalized.endsWith);
  }
}
