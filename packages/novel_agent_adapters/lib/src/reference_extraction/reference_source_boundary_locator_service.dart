import 'package:novel_agent_core/src/reference_substrate/reference_source_document_models.dart';
import 'package:novel_agent_core/src/reference_substrate/reference_source_document_structure_service.dart';

class ReferenceSourceBoundaryLocatorService {
  const ReferenceSourceBoundaryLocatorService({
    ReferenceSourceDocumentStructureService? structureService,
  }) : _structureService =
           structureService ?? const ReferenceSourceDocumentStructureService();

  final ReferenceSourceDocumentStructureService _structureService;

  ReferenceSourceBoundaryLocation locateNearTarget({
    required String sourceText,
    int targetChars = 1000000,
    int chapterToleranceChars = 24000,
    int paragraphSearchWindowChars = 16000,
  }) {
    final normalized = _normalize(sourceText);
    if (normalized.isEmpty) {
      return const ReferenceSourceBoundaryLocation(
        targetChars: 1000000,
        sourceLength: 0,
        boundaryOffset: 0,
        boundaryKind: ReferenceSourceBoundaryKinds.emptySource,
        distanceFromTarget: 1000000,
      );
    }
    final effectiveTarget = targetChars.clamp(0, normalized.length);
    if (normalized.length <= targetChars) {
      return _buildLocation(
        normalized: normalized,
        targetChars: targetChars,
        boundaryOffset: normalized.length,
        boundaryKind: ReferenceSourceBoundaryKinds.belowTarget,
        section: null,
      );
    }

    final structure = _structureService.analyze(normalized);
    final chapterBoundary = _nearestChapterBoundary(
      structure: structure,
      effectiveTarget: effectiveTarget,
      toleranceChars: chapterToleranceChars,
    );
    if (chapterBoundary != null) {
      return _buildLocation(
        normalized: normalized,
        targetChars: targetChars,
        boundaryOffset: chapterBoundary.boundaryOffset,
        boundaryKind: chapterBoundary.boundaryKind,
        section: chapterBoundary.section,
      );
    }

    final paragraphBoundary = _nearestParagraphBoundary(
      normalized: normalized,
      effectiveTarget: effectiveTarget,
      searchWindowChars: paragraphSearchWindowChars,
    );
    return _buildLocation(
      normalized: normalized,
      targetChars: targetChars,
      boundaryOffset: paragraphBoundary.$1,
      boundaryKind: paragraphBoundary.$2,
      section: null,
    );
  }

  _ChapterBoundaryCandidate? _nearestChapterBoundary({
    required ReferenceSourceDocumentStructure structure,
    required int effectiveTarget,
    required int toleranceChars,
  }) {
    if (structure.structureKind !=
            ReferenceSourceDocumentStructureKinds.explicitChapter ||
        structure.sections.isEmpty) {
      return null;
    }
    _ChapterBoundaryCandidate? bestCandidate;
    for (final section in structure.sections) {
      final candidates = <_ChapterBoundaryCandidate>[
        _ChapterBoundaryCandidate(
          section: section,
          boundaryOffset: section.startOffset,
          boundaryKind: ReferenceSourceBoundaryKinds.chapterStart,
        ),
        _ChapterBoundaryCandidate(
          section: section,
          boundaryOffset: section.endOffset,
          boundaryKind: ReferenceSourceBoundaryKinds.chapterEnd,
        ),
      ];
      for (final candidate in candidates) {
        if (bestCandidate == null ||
            _distance(candidate.boundaryOffset, effectiveTarget) <
                _distance(bestCandidate.boundaryOffset, effectiveTarget)) {
          bestCandidate = candidate;
        }
      }
    }
    if (bestCandidate == null) {
      return null;
    }
    if (_distance(bestCandidate.boundaryOffset, effectiveTarget) >
        toleranceChars) {
      return null;
    }
    return bestCandidate;
  }

  (int, String) _nearestParagraphBoundary({
    required String normalized,
    required int effectiveTarget,
    required int searchWindowChars,
  }) {
    final searchStart = (effectiveTarget - searchWindowChars).clamp(
      0,
      normalized.length,
    );
    final searchEnd = (effectiveTarget + searchWindowChars).clamp(
      0,
      normalized.length,
    );
    final window = normalized.substring(searchStart, searchEnd);
    final paragraphBreakMatches = RegExp(
      r'\n\s*\n',
    ).allMatches(window).toList(growable: false);
    if (paragraphBreakMatches.isNotEmpty) {
      final best = paragraphBreakMatches.reduce(
        (left, right) =>
            _distance(searchStart + left.start, effectiveTarget) <=
                _distance(searchStart + right.start, effectiveTarget)
            ? left
            : right,
      );
      return (
        searchStart + best.start,
        ReferenceSourceBoundaryKinds.paragraphBreak,
      );
    }
    final newlineMatches = RegExp(
      r'\n',
    ).allMatches(window).toList(growable: false);
    if (newlineMatches.isNotEmpty) {
      final best = newlineMatches.reduce(
        (left, right) =>
            _distance(searchStart + left.start, effectiveTarget) <=
                _distance(searchStart + right.start, effectiveTarget)
            ? left
            : right,
      );
      return (searchStart + best.start, ReferenceSourceBoundaryKinds.lineBreak);
    }
    final punctuationMatches = RegExp(
      r'[。！？.!?]',
    ).allMatches(window).toList(growable: false);
    if (punctuationMatches.isNotEmpty) {
      final best = punctuationMatches.reduce(
        (left, right) =>
            _distance(searchStart + left.end, effectiveTarget) <=
                _distance(searchStart + right.end, effectiveTarget)
            ? left
            : right,
      );
      return (
        searchStart + best.end,
        ReferenceSourceBoundaryKinds.sentenceBreak,
      );
    }
    return (effectiveTarget, ReferenceSourceBoundaryKinds.windowFallback);
  }

  ReferenceSourceBoundaryLocation _buildLocation({
    required String normalized,
    required int targetChars,
    required int boundaryOffset,
    required String boundaryKind,
    required ReferenceSourceDocumentSection? section,
  }) {
    final safeOffset = boundaryOffset.clamp(0, normalized.length);
    const previewRadius = 220;
    final previewBeforeStart = (safeOffset - previewRadius).clamp(
      0,
      normalized.length,
    );
    final previewAfterEnd = (safeOffset + previewRadius).clamp(
      0,
      normalized.length,
    );
    return ReferenceSourceBoundaryLocation(
      targetChars: targetChars,
      sourceLength: normalized.length,
      boundaryOffset: safeOffset,
      boundaryKind: boundaryKind,
      distanceFromTarget: _distance(safeOffset, targetChars),
      sectionId: section?.sectionId ?? '',
      sectionHeading: section?.heading ?? '',
      previewBefore: normalized
          .substring(previewBeforeStart, safeOffset)
          .trim(),
      previewAfter: normalized.substring(safeOffset, previewAfterEnd).trim(),
    );
  }

  int _distance(int left, int right) => (left - right).abs();

  String _normalize(String sourceText) {
    return sourceText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }
}

abstract final class ReferenceSourceBoundaryKinds {
  static const String chapterStart = 'chapter_start';
  static const String chapterEnd = 'chapter_end';
  static const String paragraphBreak = 'paragraph_break';
  static const String lineBreak = 'line_break';
  static const String sentenceBreak = 'sentence_break';
  static const String windowFallback = 'window_fallback';
  static const String belowTarget = 'below_target';
  static const String emptySource = 'empty_source';
}

class ReferenceSourceBoundaryLocation {
  const ReferenceSourceBoundaryLocation({
    required this.targetChars,
    required this.sourceLength,
    required this.boundaryOffset,
    required this.boundaryKind,
    required this.distanceFromTarget,
    this.sectionId = '',
    this.sectionHeading = '',
    this.previewBefore = '',
    this.previewAfter = '',
  });

  final int targetChars;
  final int sourceLength;
  final int boundaryOffset;
  final String boundaryKind;
  final int distanceFromTarget;
  final String sectionId;
  final String sectionHeading;
  final String previewBefore;
  final String previewAfter;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'target_chars': targetChars,
      'source_length': sourceLength,
      'boundary_offset': boundaryOffset,
      'boundary_kind': boundaryKind,
      'distance_from_target': distanceFromTarget,
      'section_id': sectionId,
      'section_heading': sectionHeading,
      'preview_before': previewBefore,
      'preview_after': previewAfter,
    };
  }
}

class _ChapterBoundaryCandidate {
  const _ChapterBoundaryCandidate({
    required this.section,
    required this.boundaryOffset,
    required this.boundaryKind,
  });

  final ReferenceSourceDocumentSection section;
  final int boundaryOffset;
  final String boundaryKind;
}
