import 'dart:convert';

import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../packages/frontmatter_metadata_reader_service.dart';
import 'design_element_card.dart';
import 'information_markdown_projection_service.dart';
import 'information_projection_document.dart';
import 'information_projection_draft_bundle.dart';
import 'project_knowledge_card.dart';
import 'reference_work_record.dart';
import 'research_note.dart';

class InformationMarkdownBridgeService {
  InformationMarkdownBridgeService({
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
  }) : _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService();

  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;

  InformationProjectionDraftBundle parseDocument(
    String markdown, {
    required String relativePath,
  }) {
    final frontmatter = _frontmatterMetadataReaderService.readMetadata(
      markdown,
    );
    final projectionId = ValueReaders.stringValue(
      frontmatter['projection_id'],
      _fallbackProjectionId(relativePath),
    ).trim();
    final warnings = <String>[];
    final codeBlocks = _extractCodeBlocks(markdown);
    return InformationProjectionDraftBundle(
      projectionId: projectionId,
      relativePath: relativePath,
      projectionOnly: ValueReaders.boolValue(
        frontmatter['projection_only'],
        true,
      ),
      knowledgeCardDrafts: _parseListBlock(
        codeBlocks,
        InformationMarkdownProjectionService.knowledgeDraftBlockId,
        warnings,
        parser: ProjectKnowledgeCard.fromJson,
        label: 'knowledge draft',
      ),
      designElementDrafts: _parseListBlock(
        codeBlocks,
        InformationMarkdownProjectionService.designDraftBlockId,
        warnings,
        parser: DesignElementCard.fromJson,
        label: 'design draft',
      ),
      researchNoteDrafts: _parseListBlock(
        codeBlocks,
        InformationMarkdownProjectionService.researchDraftBlockId,
        warnings,
        parser: ResearchNote.fromJson,
        label: 'research draft',
      ),
      referenceWorkDrafts: _parseListBlock(
        codeBlocks,
        InformationMarkdownProjectionService.referenceWorkDraftBlockId,
        warnings,
        parser: ReferenceWorkRecord.fromJson,
        label: 'reference work draft',
      ),
      warnings: warnings,
    );
  }

  List<T> _parseListBlock<T>(
    List<_MarkdownCodeBlock> codeBlocks,
    String blockId,
    List<String> warnings, {
    required T Function(JsonMap json) parser,
    required String label,
  }) {
    final block = codeBlocks
        .where((item) => item.info.contains(blockId))
        .lastOrNull;
    if (block == null || block.content.trim().isEmpty) {
      return <T>[];
    }
    try {
      final decoded = jsonDecode(block.content);
      final list = ValueReaders.mapList(decoded);
      return list.map(parser).toList(growable: false);
    } catch (_) {
      warnings.add('无法解析 $label block：$blockId');
      return <T>[];
    }
  }

  List<_MarkdownCodeBlock> _extractCodeBlocks(String markdown) {
    final lines = markdown
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');
    final result = <_MarkdownCodeBlock>[];
    String? info;
    final buffer = <String>[];
    for (final line in lines) {
      final trimmed = line.trimRight();
      if (info == null) {
        if (trimmed.startsWith('```')) {
          info = trimmed.substring(3).trim();
          buffer.clear();
        }
        continue;
      }
      if (trimmed.startsWith('```')) {
        result.add(_MarkdownCodeBlock(info: info, content: buffer.join('\n')));
        info = null;
        buffer.clear();
        continue;
      }
      buffer.add(line);
    }
    return result;
  }

  String _fallbackProjectionId(String relativePath) {
    switch (relativePath) {
      case InformationProjectionDocument.knowledgeSummaryRelativePath:
        return InformationProjectionDocument.knowledgeSummaryProjectionId;
      case InformationProjectionDocument.designSummaryRelativePath:
        return InformationProjectionDocument.designSummaryProjectionId;
      case InformationProjectionDocument.researchSummaryRelativePath:
        return InformationProjectionDocument.researchSummaryProjectionId;
      case InformationProjectionDocument.referenceBoundaryRelativePath:
        return InformationProjectionDocument.referenceBoundaryProjectionId;
      default:
        return relativePath.trim().isEmpty
            ? 'unknown_projection'
            : relativePath;
    }
  }
}

class _MarkdownCodeBlock {
  const _MarkdownCodeBlock({required this.info, required this.content});

  final String info;
  final String content;
}

extension on Iterable<_MarkdownCodeBlock> {
  _MarkdownCodeBlock? get lastOrNull {
    _MarkdownCodeBlock? result;
    for (final item in this) {
      result = item;
    }
    return result;
  }
}
