import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

class OpenNarrativeStateJsonlDocumentService {
  const OpenNarrativeStateJsonlDocumentService({
    required ProjectWorkspacePort workspacePort,
  }) : _workspacePort = workspacePort;

  final ProjectWorkspacePort _workspacePort;

  Future<List<JsonMap>> readJsonLines(
    String rootPath,
    String relativePath,
  ) async {
    final content = await _workspacePort.readTextFile(rootPath, relativePath);
    if (content == null || content.trim().isEmpty) {
      return const <JsonMap>[];
    }
    final result = <JsonMap>[];
    for (final line in const LineSplitter().convert(content)) {
      final cleanLine = line.trim();
      if (cleanLine.isEmpty) {
        continue;
      }
      try {
        result.add(ValueReaders.mapValue(jsonDecode(cleanLine)));
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  Future<void> appendJsonLine(
    String rootPath,
    String relativePath,
    JsonMap document,
  ) async {
    final encodedLine = jsonEncode(document);
    final existing = await _workspacePort.readTextFile(rootPath, relativePath);
    final normalizedExisting = (existing ?? '').trimRight();
    final nextContent = normalizedExisting.isEmpty
        ? '$encodedLine\n'
        : '$normalizedExisting\n$encodedLine\n';
    await _workspacePort.writeTextFile(rootPath, relativePath, nextContent);
  }
}
