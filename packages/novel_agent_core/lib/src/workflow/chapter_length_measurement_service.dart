class ChapterLengthMeasurementService {
  const ChapterLengthMeasurementService();

  int measureVisibleCharacters(String text) {
    // 中文注释: 当前阶段统一按“非空白可见字符数”计量，兼容 Markdown 项目和纯文本正文。
    if (text.trim().isEmpty) {
      return 0;
    }
    var count = 0;
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (char.trim().isEmpty) {
        continue;
      }
      count += 1;
    }
    return count;
  }
}
