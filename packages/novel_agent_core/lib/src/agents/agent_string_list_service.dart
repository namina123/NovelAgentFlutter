import '../common/value_readers.dart';

class AgentStringListService {
  List<String> normalize(Object? rawValue) {
    // 中文注释: 智能体配置既可能来自数组，也可能是逗号分隔字符串，这里统一做去空和去重。
    if (rawValue is String) {
      return _normalizeTokens(
        rawValue.replaceAll('，', ',').replaceAll('、', ',').split(','),
      );
    }
    return _normalizeTokens(ValueReaders.objectList(rawValue));
  }

  List<String> _normalizeTokens(List<Object?> rawValues) {
    final result = <String>[];
    for (final rawValue in rawValues) {
      final text = ValueReaders.stringValue(rawValue).trim();
      if (text.isNotEmpty && !result.contains(text)) {
        result.add(text);
      }
    }
    return result;
  }
}
