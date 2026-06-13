import 'reference_source_document_models.dart';

class ReferenceSourceDocumentStructureService {
  const ReferenceSourceDocumentStructureService();

  static final RegExp _chapterHeadingPattern = RegExp(
    r'^[^A-Za-z\u4E00-\u9FFF]{0,12}(chapter\s+[^\n]+|第[一二三四五六七八九十百千0-9]+章[^\n]*)\s*$',
    multiLine: true,
    caseSensitive: false,
  );

  ReferenceSourceDocumentStructure analyze(String sourceText) {
    final normalized = _normalize(sourceText);
    final chapterSections = _extractChapterSections(normalized);
    if (chapterSections.isNotEmpty) {
      return ReferenceSourceDocumentStructure(
        sourceTextLength: normalized.length,
        structureKind: ReferenceSourceDocumentStructureKinds.explicitChapter,
        sections: chapterSections,
      );
    }
    final paragraphSections = _extractParagraphClusters(normalized);
    return ReferenceSourceDocumentStructure(
      sourceTextLength: normalized.length,
      structureKind: ReferenceSourceDocumentStructureKinds.paragraphCluster,
      sections: paragraphSections,
    );
  }

  List<ReferenceSourceDocumentSection> splitOversizedSection({
    required ReferenceSourceDocumentSection section,
    required int maxChars,
    required int minChars,
  }) {
    if (section.charCount <= maxChars) {
      return <ReferenceSourceDocumentSection>[section];
    }
    final paragraphs = section.content
        .split(RegExp(r'\n\s*\n'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (paragraphs.length <= 1) {
      return _splitByWindow(section: section, maxChars: maxChars);
    }
    final chunks = <ReferenceSourceDocumentSection>[];
    final buffer = StringBuffer();
    var chunkStartOffset = section.startOffset;
    var chunkIndex = 1;
    var cursorOffset = section.startOffset;
    for (final paragraph in paragraphs) {
      final separatorLength = buffer.isEmpty ? 0 : 2;
      final nextLength = buffer.length + separatorLength + paragraph.length;
      if (buffer.isNotEmpty &&
          nextLength > maxChars &&
          buffer.length >= minChars) {
        chunks.add(
          _buildSyntheticChunk(
            section: section,
            chunkIndex: chunkIndex,
            startOffset: chunkStartOffset,
            endOffset: cursorOffset,
            content: buffer.toString().trim(),
          ),
        );
        chunkIndex += 1;
        buffer.clear();
        chunkStartOffset = cursorOffset;
      }
      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
        cursorOffset += 2;
      }
      buffer.write(paragraph);
      cursorOffset += paragraph.length;
    }
    final trailing = buffer.toString().trim();
    if (trailing.isNotEmpty) {
      chunks.add(
        _buildSyntheticChunk(
          section: section,
          chunkIndex: chunkIndex,
          startOffset: chunkStartOffset,
          endOffset: section.endOffset,
          content: trailing,
        ),
      );
    }
    return chunks.isEmpty
        ? _splitByWindow(section: section, maxChars: maxChars)
        : chunks;
  }

  List<ReferenceSourceDocumentSection> _extractChapterSections(
    String normalized,
  ) {
    final matches = _chapterHeadingPattern
        .allMatches(normalized)
        .toList(growable: false);
    if (matches.isEmpty) {
      return const <ReferenceSourceDocumentSection>[];
    }
    final sections = <ReferenceSourceDocumentSection>[];
    for (var index = 0; index < matches.length; index += 1) {
      final current = matches[index];
      final nextStart = index + 1 < matches.length
          ? matches[index + 1].start
          : normalized.length;
      final contentRange = _trimRange(normalized, current.end, nextStart);
      final content = normalized
          .substring(contentRange.$1, contentRange.$2)
          .trim();
      if (content.isEmpty) {
        continue;
      }
      final sectionIndex = sections.length + 1;
      final heading = _normalizeHeadingText(current.group(1) ?? '');
      sections.add(
        ReferenceSourceDocumentSection(
          sectionId: 'section_${sectionIndex.toString().padLeft(3, '0')}',
          sectionIndex: sectionIndex,
          heading: heading,
          content: content,
          keywords: _keywordsFromText('$heading $content'),
          startOffset: contentRange.$1,
          endOffset: contentRange.$2,
          structureKind: ReferenceSourceDocumentStructureKinds.explicitChapter,
        ),
      );
    }
    return sections;
  }

  List<ReferenceSourceDocumentSection> _extractParagraphClusters(
    String normalized,
  ) {
    final sections = <ReferenceSourceDocumentSection>[];
    final paragraphPattern = RegExp(
      r'[^\n]+(?:\n(?!\n)[^\n]+)*',
      multiLine: true,
    );
    final paragraphs = paragraphPattern
        .allMatches(normalized)
        .where((match) => match.group(0)?.trim().isNotEmpty ?? false)
        .toList(growable: false);
    final buffer = StringBuffer();
    var bufferStart = 0;
    var currentIndex = 1;
    for (final paragraph in paragraphs) {
      final paragraphText = paragraph.group(0)?.trim() ?? '';
      if (paragraphText.isEmpty) {
        continue;
      }
      if (buffer.isEmpty) {
        bufferStart = paragraph.start;
      }
      final separatorLength = buffer.isEmpty ? 0 : 2;
      if (buffer.isNotEmpty &&
          buffer.length + separatorLength + paragraphText.length > 2200) {
        final content = buffer.toString().trim();
        if (content.isNotEmpty) {
          sections.add(
            ReferenceSourceDocumentSection(
              sectionId: 'section_${currentIndex.toString().padLeft(3, '0')}',
              sectionIndex: currentIndex,
              heading: '',
              content: content,
              keywords: _keywordsFromText(content),
              startOffset: bufferStart,
              endOffset: paragraph.start,
              structureKind:
                  ReferenceSourceDocumentStructureKinds.paragraphCluster,
            ),
          );
          currentIndex += 1;
        }
        buffer.clear();
        bufferStart = paragraph.start;
      }
      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
      }
      buffer.write(paragraphText);
      if (sections.length >= 11) {
        break;
      }
    }
    final trailing = buffer.toString().trim();
    if (trailing.isNotEmpty && sections.length < 12) {
      sections.add(
        ReferenceSourceDocumentSection(
          sectionId: 'section_${currentIndex.toString().padLeft(3, '0')}',
          sectionIndex: currentIndex,
          heading: '',
          content: trailing,
          keywords: _keywordsFromText(trailing),
          startOffset: bufferStart,
          endOffset: normalized.length,
          structureKind: ReferenceSourceDocumentStructureKinds.paragraphCluster,
        ),
      );
    }
    return sections;
  }

  List<ReferenceSourceDocumentSection> _splitByWindow({
    required ReferenceSourceDocumentSection section,
    required int maxChars,
  }) {
    final chunks = <ReferenceSourceDocumentSection>[];
    var chunkIndex = 1;
    for (var start = 0; start < section.content.length; start += maxChars) {
      final end = (start + maxChars).clamp(0, section.content.length);
      final content = section.content.substring(start, end).trim();
      if (content.isEmpty) {
        continue;
      }
      chunks.add(
        _buildSyntheticChunk(
          section: section,
          chunkIndex: chunkIndex,
          startOffset: section.startOffset + start,
          endOffset: section.startOffset + end,
          content: content,
        ),
      );
      chunkIndex += 1;
    }
    return chunks;
  }

  ReferenceSourceDocumentSection _buildSyntheticChunk({
    required ReferenceSourceDocumentSection section,
    required int chunkIndex,
    required int startOffset,
    required int endOffset,
    required String content,
  }) {
    final label = section.heading.trim().isEmpty
        ? 'Part $chunkIndex'
        : '${section.heading} / Part $chunkIndex';
    return ReferenceSourceDocumentSection(
      sectionId: '${section.sectionId}_part_$chunkIndex',
      sectionIndex: section.sectionIndex,
      heading: label,
      content: content,
      keywords: _keywordsFromText('${section.heading} $content'),
      startOffset: startOffset,
      endOffset: endOffset,
      structureKind: section.structureKind,
      synthetic: true,
      parentSectionId: section.sectionId,
    );
  }

  String _normalize(String sourceText) {
    return sourceText.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }

  String _normalizeHeadingText(String rawHeading) {
    return rawHeading.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _keywordsFromText(String text) {
    final matches = RegExp(r'\b[A-Z][a-z]{2,}\b').allMatches(text);
    final keywords = <String>{};
    for (final match in matches) {
      final value = match.group(0)?.trim() ?? '';
      if (value.isNotEmpty) {
        keywords.add(value);
      }
      if (keywords.length >= 6) {
        break;
      }
    }
    return keywords.toList(growable: false);
  }

  (int, int) _trimRange(String text, int start, int end) {
    var resolvedStart = start;
    var resolvedEnd = end;
    while (resolvedStart < resolvedEnd &&
        _isTrimWhitespace(text.codeUnitAt(resolvedStart))) {
      resolvedStart += 1;
    }
    while (resolvedEnd > resolvedStart &&
        _isTrimWhitespace(text.codeUnitAt(resolvedEnd - 1))) {
      resolvedEnd -= 1;
    }
    return (resolvedStart, resolvedEnd);
  }

  bool _isTrimWhitespace(int codeUnit) {
    return codeUnit == 9 || codeUnit == 10 || codeUnit == 13 || codeUnit == 32;
  }
}
