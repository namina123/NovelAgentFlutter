class SseEventTextParser {
  SseEventTextParser({this.ignoreEventFields = false});

  final bool ignoreEventFields;
  final StringBuffer _eventBuffer = StringBuffer();
  String _lineBuffer = '';

  List<String> addChunk(String chunk) {
    final events = <String>[];
    _lineBuffer += chunk;
    while (true) {
      final lineBreakIndex = _lineBuffer.indexOf('\n');
      if (lineBreakIndex < 0) {
        break;
      }
      final rawLine = _lineBuffer.substring(0, lineBreakIndex);
      _lineBuffer = _lineBuffer.substring(lineBreakIndex + 1);
      _consumeLine(rawLine, events);
    }
    return events;
  }

  List<String> close() {
    final events = <String>[];
    if (_lineBuffer.isNotEmpty) {
      _consumeLine(_lineBuffer, events);
      _lineBuffer = '';
    }
    if (_eventBuffer.isNotEmpty) {
      events.add(_eventBuffer.toString());
      _eventBuffer.clear();
    }
    return events;
  }

  void _consumeLine(String line, List<String> events) {
    final normalized = line.endsWith('\r')
        ? line.substring(0, line.length - 1)
        : line;
    if (normalized.isEmpty) {
      if (_eventBuffer.isNotEmpty) {
        events.add(_eventBuffer.toString());
        _eventBuffer.clear();
      }
      return;
    }
    if (ignoreEventFields && normalized.startsWith('event:')) {
      return;
    }
    if (!normalized.startsWith('data:')) {
      return;
    }
    final payload = normalized.substring(5).trimLeft();
    if (_eventBuffer.isNotEmpty) {
      _eventBuffer.write('\n');
    }
    _eventBuffer.write(payload);
  }
}
