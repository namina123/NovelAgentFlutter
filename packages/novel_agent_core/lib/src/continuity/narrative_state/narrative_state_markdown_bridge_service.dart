import 'dart:convert';

import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../packages/frontmatter_metadata_reader_service.dart';
import 'narrative_constraint_binding_codec_service.dart';
import 'narrative_constraint_binding_proposal.dart';
import 'narrative_profile_codec_service.dart';
import 'narrative_profile_proposal.dart';
import 'narrative_semantic_review.dart';
import 'narrative_semantic_review_codec_service.dart';
import 'narrative_state_claim.dart';
import 'narrative_state_claim_codec_service.dart';
import 'narrative_state_markdown_projection_service.dart';
import 'narrative_state_projection_draft_bundle.dart';
import 'narrative_state_projection_document.dart';

class NarrativeStateMarkdownBridgeService {
  NarrativeStateMarkdownBridgeService({
    FrontmatterMetadataReaderService? frontmatterMetadataReaderService,
    NarrativeProfileCodecService? profileCodecService,
    NarrativeStateClaimCodecService? claimCodecService,
    NarrativeConstraintBindingCodecService? bindingCodecService,
    NarrativeSemanticReviewCodecService? semanticReviewCodecService,
  }) : _frontmatterMetadataReaderService =
           frontmatterMetadataReaderService ??
           FrontmatterMetadataReaderService(),
       _profileCodecService =
           profileCodecService ?? const NarrativeProfileCodecService(),
       _claimCodecService =
           claimCodecService ?? const NarrativeStateClaimCodecService(),
       _bindingCodecService =
           bindingCodecService ??
           const NarrativeConstraintBindingCodecService(),
       _semanticReviewCodecService =
           semanticReviewCodecService ??
           const NarrativeSemanticReviewCodecService();

  final FrontmatterMetadataReaderService _frontmatterMetadataReaderService;
  final NarrativeProfileCodecService _profileCodecService;
  final NarrativeStateClaimCodecService _claimCodecService;
  final NarrativeConstraintBindingCodecService _bindingCodecService;
  final NarrativeSemanticReviewCodecService _semanticReviewCodecService;

  NarrativeStateProjectionDraftBundle parseDocument(
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
    return NarrativeStateProjectionDraftBundle(
      projectionId: projectionId,
      relativePath: relativePath,
      projectionOnly: ValueReaders.boolValue(
        frontmatter['projection_only'],
        true,
      ),
      profileProposalDrafts: _parseProfileProposalDrafts(codeBlocks, warnings),
      claimDrafts: _parseClaimDrafts(codeBlocks, warnings),
      constraintBindingDrafts: _parseBindingDrafts(codeBlocks, warnings),
      semanticReviewDrafts: _parseSemanticReviewDrafts(codeBlocks, warnings),
      warnings: warnings,
    );
  }

  List<NarrativeProfileProposal> _parseProfileProposalDrafts(
    List<_MarkdownCodeBlock> codeBlocks,
    List<String> warnings,
  ) {
    return _parseListBlock(
      codeBlocks,
      NarrativeStateMarkdownProjectionService.profileProposalDraftBlockId,
      warnings,
      parser: (json) => _profileCodecService.proposalFromJson(json),
      label: 'profile proposal draft',
    );
  }

  List<NarrativeStateClaim> _parseClaimDrafts(
    List<_MarkdownCodeBlock> codeBlocks,
    List<String> warnings,
  ) {
    return _parseListBlock(
      codeBlocks,
      NarrativeStateMarkdownProjectionService.claimDraftBlockId,
      warnings,
      parser: (json) => _claimCodecService.fromJson(json),
      label: 'claim draft',
    );
  }

  List<NarrativeConstraintBindingProposal> _parseBindingDrafts(
    List<_MarkdownCodeBlock> codeBlocks,
    List<String> warnings,
  ) {
    return _parseListBlock(
      codeBlocks,
      NarrativeStateMarkdownProjectionService.bindingDraftBlockId,
      warnings,
      parser: (json) => _bindingCodecService.proposalFromJson(json),
      label: 'binding draft',
    );
  }

  List<NarrativeSemanticReview> _parseSemanticReviewDrafts(
    List<_MarkdownCodeBlock> codeBlocks,
    List<String> warnings,
  ) {
    return _parseListBlock(
      codeBlocks,
      NarrativeStateMarkdownProjectionService.semanticReviewDraftBlockId,
      warnings,
      parser: (json) => _semanticReviewCodecService.fromJson(json),
      label: 'semantic review draft',
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
      case NarrativeStateProjectionDocument.rulesRelativePath:
        return NarrativeStateProjectionDocument.rulesProjectionId;
      case NarrativeStateProjectionDocument.recentChangesRelativePath:
        return NarrativeStateProjectionDocument.recentChangesProjectionId;
      case NarrativeStateProjectionDocument.constraintSummaryRelativePath:
        return NarrativeStateProjectionDocument.constraintSummaryProjectionId;
      case NarrativeStateProjectionDocument.semanticReviewSummaryRelativePath:
        return NarrativeStateProjectionDocument
            .semanticReviewSummaryProjectionId;
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
