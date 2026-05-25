import '../common/json_types.dart';
import '../common/value_readers.dart';

class SessionMessageService {
  List<JsonMap> normalizeMessages(Object? value) {
    // 中文注释: 会话消息数组统一在这里规范化，确保后续摘要、压缩和导出逻辑面对稳定结构。
    return ValueReaders.objectList(value)
        .map(ValueReaders.mapValue)
        .where((entry) => entry.isNotEmpty)
        .map(ValueReaders.deepCopyMap)
        .toList(growable: true);
  }

  int messagesChars(List<Object?> messages) {
    // 中文注释: 消息字符数统计是压缩阈值的直接依据，因此集中在消息服务里复用。
    var total = 0;
    for (final raw in messages) {
      final message = ValueReaders.mapValue(raw);
      total += ValueReaders.stringValue(message['content']).length;
    }
    return total;
  }

  List<JsonMap> collapseConsecutiveDuplicates(List<Object?> messages) {
    // 中文注释: 连续重复消息会放大上下文噪声，这里先去重再交给压缩和渲染层使用。
    final result = <JsonMap>[];
    var lastRole = '';
    var lastContent = '';
    for (final raw in messages) {
      final message = ValueReaders.mapValue(raw);
      final role = ValueReaders.stringValue(message['role']).trim();
      final content = ValueReaders.stringValue(message['content']).trim();
      if (role == lastRole && content == lastContent) {
        continue;
      }
      result.add(ValueReaders.deepCopyMap(message));
      lastRole = role;
      lastContent = content;
    }
    return result;
  }

  List<JsonMap> messagesForContext(
    List<Object?> rawMessages, {
    String excludeLatestUserContent = '',
  }) {
    // 中文注释: 生成上下文时可以排除刚发送的用户输入，避免同一内容在 prompt 里重复出现。
    final messages = collapseConsecutiveDuplicates(rawMessages);
    final cleanExclude = excludeLatestUserContent.trim();
    if (cleanExclude.isEmpty || messages.isEmpty) {
      return messages;
    }
    final result = List<JsonMap>.from(messages);
    for (var index = result.length - 1; index >= 0; index -= 1) {
      final message = result[index];
      if (ValueReaders.stringValue(message['role']) != 'user') {
        continue;
      }
      if (ValueReaders.stringValue(message['content']).trim() == cleanExclude) {
        result.removeAt(index);
      }
      break;
    }
    return result;
  }
}
