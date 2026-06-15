class BookDeconstructionSourceTextMetadataService {
  const BookDeconstructionSourceTextMetadataService();

  String resolveSourceTitle({
    required String sourceTitle,
    required String sourceAbsolutePath,
    required String sourceContent,
  }) {
    // 中文注释: 标题推断只做纯字符串收束，不读取文件系统，也不依赖运行态状态。
    final cleanTitle = sourceTitle.trim();
    if (cleanTitle.isNotEmpty) {
      return cleanTitle;
    }
    final cleanPath = sourceAbsolutePath.trim().replaceAll('\\', '/');
    if (cleanPath.isNotEmpty) {
      final fileName = cleanPath.split('/').last;
      final separatorIndex = fileName.lastIndexOf('.');
      if (separatorIndex > 0) {
        return fileName.substring(0, separatorIndex);
      }
      return fileName;
    }
    final firstLine = sourceContent
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '未命名拆书源');
    return _truncate(firstLine, 36);
  }

  String mediaTypeOf(String sourceAbsolutePath) {
    // 中文注释: 这里仅做扩展名到媒体类型的纯映射，后续 reader / adapter 再负责真正的读取。
    final lower = sourceAbsolutePath.trim().toLowerCase();
    if (lower.endsWith('.md') || lower.endsWith('.markdown')) {
      return 'text/markdown';
    }
    if (lower.endsWith('.epub')) {
      return 'application/epub+zip';
    }
    return 'text/plain';
  }

  String _truncate(String value, int maxLength) {
    final clean = value.trim();
    if (clean.length <= maxLength) {
      return clean;
    }
    return '${clean.substring(0, maxLength)}...';
  }
}
