import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

class LlmReferenceExtractionResponseParserService {
  const LlmReferenceExtractionResponseParserService();

  LlmReferenceExtractionParsedResponse parseStructuredResponse(String content) {
    final normalized = content.trim();
    if (normalized.isEmpty) {
      throw StateError('reference extraction proposal response is empty.');
    }
    final fencedMatch = RegExp(
      r'```(?:json)?\s*([\s\S]*?)```',
    ).firstMatch(normalized);
    final candidate = fencedMatch == null
        ? normalized
        : fencedMatch.group(1)!.trim();
    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start < 0 || end < start) {
      throw StateError('reference extraction response is not a JSON object.');
    }
    final jsonText = candidate.substring(start, end + 1);
    final decoded = _decodeJsonObject(jsonText);
    final root = ValueReaders.mapValue(decoded);
    final proposals = ValueReaders.mapList(root['proposals']);
    final omissionReport = ValueReaders.mapValue(root['omission_report']);
    final continuationRequest = ValueReaders.mapValue(
      root['continuation_request'],
    );
    if (proposals.isEmpty &&
        omissionReport.isEmpty &&
        continuationRequest.isEmpty) {
      throw StateError(
        'reference extraction response does not contain proposals or output contract signals.',
      );
    }
    return LlmReferenceExtractionParsedResponse(
      proposals: proposals.toList(growable: false),
      omissionReport: omissionReport,
      continuationRequest: continuationRequest,
    );
  }

  Object? _decodeJsonObject(String jsonText) {
    try {
      return jsonDecode(jsonText);
    } on FormatException {
      return jsonDecode(_escapeLikelyBareQuotes(jsonText));
    }
  }

  String _escapeLikelyBareQuotes(String text) {
    final buffer = StringBuffer();
    var inString = false;
    var escaping = false;
    for (var index = 0; index < text.length; index += 1) {
      final char = text[index];
      if (!inString) {
        buffer.write(char);
        if (char == '"') {
          inString = true;
        }
        continue;
      }
      if (escaping) {
        buffer.write(char);
        escaping = false;
        continue;
      }
      if (char == r'\') {
        buffer.write(char);
        escaping = true;
        continue;
      }
      if (char == '"') {
        final next = _nextNonWhitespace(text, index + 1);
        if (next.isEmpty || ',}] :'.contains(next)) {
          buffer.write(char);
          inString = false;
        } else {
          buffer.write(r'\"');
        }
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  String _nextNonWhitespace(String text, int start) {
    for (var index = start; index < text.length; index += 1) {
      final char = text[index];
      if (char.trim().isNotEmpty) {
        return char;
      }
    }
    return '';
  }
}

class LlmReferenceExtractionParsedResponse {
  const LlmReferenceExtractionParsedResponse({
    this.proposals = const <JsonMap>[],
    this.omissionReport = const <String, Object?>{},
    this.continuationRequest = const <String, Object?>{},
  });

  final List<JsonMap> proposals;
  final JsonMap omissionReport;
  final JsonMap continuationRequest;
}
