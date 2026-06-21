import 'package:novel_agent_core/novel_agent_core.dart';

class GatewayContentExtractor {
  const GatewayContentExtractor._();

  static String textFromContent(Object? value) {
    if (value is String) {
      return value;
    }
    if (value is List) {
      final buffer = StringBuffer();
      for (final part in value) {
        final text = textFromContentPart(ValueReaders.mapValue(part));
        if (text.isEmpty) {
          continue;
        }
        if (buffer.isNotEmpty) {
          buffer.writeln();
        }
        buffer.write(text);
      }
      return buffer.toString();
    }
    return ValueReaders.stringValue(value);
  }

  static String textFromContentPart(JsonMap part) {
    return ValueReaders.stringValue(part['text']);
  }

  static String reasoningFromContentParts(
    Iterable<Object?> parts, {
    String textKey = 'thinking',
  }) {
    final buffer = StringBuffer();
    for (final rawPart in parts) {
      final part = ValueReaders.mapValue(rawPart);
      final type = ValueReaders.stringValue(part['type']);
      if (type != 'thinking' && type != 'reasoning') {
        continue;
      }
      final text = ValueReaders.stringValue(
        part[textKey],
        ValueReaders.stringValue(
          part['reasoning'],
          ValueReaders.stringValue(part['text']),
        ),
      );
      if (text.isEmpty) {
        continue;
      }
      if (buffer.isNotEmpty) {
        buffer.writeln();
      }
      buffer.write(text);
    }
    return buffer.toString();
  }
}
