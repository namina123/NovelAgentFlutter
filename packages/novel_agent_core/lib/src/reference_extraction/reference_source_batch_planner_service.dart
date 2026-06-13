import '../reference_substrate/reference_source_document_models.dart';
import '../reference_substrate/reference_source_document_structure_service.dart';
import 'reference_ingestion_budget_policy.dart';
import 'reference_source_batch_models.dart';

class ReferenceSourceBatchPlannerService {
  ReferenceSourceBatchPlannerService({
    ReferenceSourceDocumentStructureService? structureService,
  }) : _structureService =
           structureService ?? const ReferenceSourceDocumentStructureService();

  final ReferenceSourceDocumentStructureService _structureService;

  ReferenceSourceBatchPlan plan({
    required String planId,
    required ReferenceSourceDocumentStructure structure,
    required ReferenceIngestionBudgetResolution budgetResolution,
    required ReferenceIngestionBudgetPolicy budgetPolicy,
  }) {
    final structureFallbackUsed =
        structure.structureKind !=
            ReferenceSourceDocumentStructureKinds.explicitChapter &&
        budgetResolution.planningMode ==
            ReferenceSourceBatchPlanningModes.chapterFirst;
    final units = <ReferenceSourceDocumentSection>[];
    var oversizeSplitApplied = false;
    for (final section in structure.sections) {
      if (section.charCount <= budgetResolution.maxSourceChars) {
        units.add(section);
        continue;
      }
      oversizeSplitApplied = true;
      units.addAll(
        _structureService.splitOversizedSection(
          section: section,
          maxChars: budgetResolution.maxSourceChars,
          minChars: budgetPolicy.oversizeSectionMinChars,
        ),
      );
    }

    final batches =
        budgetResolution.planningMode ==
                ReferenceSourceBatchPlanningModes.chapterFirst &&
            structure.structureKind ==
                ReferenceSourceDocumentStructureKinds.explicitChapter
        ? _chapterFirstBatches(units, structure.structureKind)
        : _structureFirstBatches(
            units,
            structure.structureKind,
            budgetResolution,
          );
    return ReferenceSourceBatchPlan(
      planId: planId,
      structureMode: structure.structureKind,
      totalSourceChars: structure.sourceTextLength,
      totalSectionCount: structure.sections.length,
      budgetResolution: budgetResolution,
      batches: batches,
      planningMode: budgetResolution.planningMode,
      batchGoalKind: budgetResolution.batchGoalKind,
      structureFallbackUsed: structureFallbackUsed,
      oversizeSplitApplied: oversizeSplitApplied,
    );
  }

  List<ReferenceSourceBatch> _structureFirstBatches(
    List<ReferenceSourceDocumentSection> units,
    String structureMode,
    ReferenceIngestionBudgetResolution budgetResolution,
  ) {
    final batches = <ReferenceSourceBatch>[];
    final currentUnits = <ReferenceSourceDocumentSection>[];
    var batchIndex = 1;
    var currentChars = 0;
    for (final unit in units) {
      final nextChars =
          currentChars + (currentUnits.isEmpty ? 0 : 2) + unit.charCount;
      final shouldFlush =
          currentUnits.isNotEmpty &&
          ((nextChars > budgetResolution.targetSourceChars &&
                  currentChars >= budgetResolution.minSourceChars) ||
              currentUnits.length >= budgetResolution.maxSectionsPerBatch);
      if (shouldFlush) {
        batches.add(_buildBatch(batchIndex, structureMode, currentUnits));
        batchIndex += 1;
        currentUnits.clear();
        currentChars = 0;
      }
      currentUnits.add(unit);
      currentChars += (currentUnits.length == 1 ? 0 : 2) + unit.charCount;
    }
    if (currentUnits.isNotEmpty) {
      batches.add(_buildBatch(batchIndex, structureMode, currentUnits));
    }
    return batches;
  }

  List<ReferenceSourceBatch> _chapterFirstBatches(
    List<ReferenceSourceDocumentSection> units,
    String structureMode,
  ) {
    return units
        .asMap()
        .entries
        .map(
          (entry) => _buildBatch(
            entry.key + 1,
            structureMode,
            <ReferenceSourceDocumentSection>[entry.value],
          ),
        )
        .toList(growable: false);
  }

  ReferenceSourceBatch _buildBatch(
    int batchIndex,
    String structureMode,
    List<ReferenceSourceDocumentSection> units,
  ) {
    final sourceText = units
        .map((entry) {
          final heading = entry.heading.trim();
          return heading.isEmpty
              ? entry.content.trim()
              : '$heading\n${entry.content.trim()}';
        })
        .join('\n\n');
    final splitMode = units.any((entry) => entry.synthetic)
        ? ReferenceSourceBatchSplitModes.oversizedSectionSplit
        : structureMode == ReferenceSourceDocumentStructureKinds.explicitChapter
        ? ReferenceSourceBatchSplitModes.sectionAligned
        : ReferenceSourceBatchSplitModes.structureFallback;
    return ReferenceSourceBatch(
      batchId: 'batch_${batchIndex.toString().padLeft(3, '0')}',
      batchIndex: batchIndex,
      structureMode: structureMode,
      splitMode: splitMode,
      sourceText: sourceText,
      sectionIds: units.map((entry) => entry.sectionId).toList(growable: false),
      sectionIndexes: units
          .map((entry) => entry.sectionIndex)
          .toList(growable: false),
      headings: units
          .map((entry) => entry.heading.trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false),
      syntheticSplit: units.any((entry) => entry.synthetic),
      parentSectionIds: units
          .map((entry) => entry.parentSectionId)
          .where((entry) => entry.isNotEmpty)
          .toSet()
          .toList(growable: false),
    );
  }
}
