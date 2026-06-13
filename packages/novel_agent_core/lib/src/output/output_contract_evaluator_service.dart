import 'output_contract_models.dart';

class OutputContractEvaluation {
  const OutputContractEvaluation({
    required this.coverageLedger,
    required this.compressionRisk,
    required this.completionStatus,
  });

  final OutputCoverageLedger coverageLedger;
  final OutputCompressionRisk compressionRisk;
  final String completionStatus;
}

class OutputContractEvaluatorService {
  const OutputContractEvaluatorService();

  OutputContractEvaluation evaluate({
    required OutputBudgetPolicy budgetPolicy,
    required OutputCoverageContract coverageContract,
    required List<OutputCoverageSignal> generatedSignals,
    List<OutputCoverageSignal> acceptedSignals = const <OutputCoverageSignal>[],
    List<OmissionReport> omissionReports = const <OmissionReport>[],
    List<ContinuationRequest> continuationRequests =
        const <ContinuationRequest>[],
  }) {
    final dimensionById = <String, OutputCoverageDimension>{
      for (final dimension in coverageContract.dimensions)
        if (dimension.dimensionId.trim().isNotEmpty)
          dimension.dimensionId: dimension,
    };
    final generatedCounts = _countByDimension(generatedSignals, dimensionById);
    final acceptedCounts = _countByDimension(acceptedSignals, dimensionById);
    final omissionCounts = <String, int>{};
    for (final report in omissionReports) {
      for (final dimensionId in report.omittedDimensionIds) {
        if (!dimensionById.containsKey(dimensionId)) {
          continue;
        }
        omissionCounts[dimensionId] = (omissionCounts[dimensionId] ?? 0) + 1;
      }
    }

    var coveredDimensionCount = 0;
    var acceptedCoveredDimensionCount = 0;
    final ledgerDimensions = <OutputCoverageLedgerDimension>[];
    for (final dimension in coverageContract.dimensions) {
      final generatedCount = generatedCounts[dimension.dimensionId] ?? 0;
      final acceptedCount = acceptedCounts[dimension.dimensionId] ?? 0;
      final omissionCount = omissionCounts[dimension.dimensionId] ?? 0;
      final generatedCovered = generatedCount >= dimension.minItemCount;
      final acceptedCovered = acceptedCount >= dimension.minItemCount;
      if (generatedCovered) {
        coveredDimensionCount += 1;
      }
      if (acceptedCovered) {
        acceptedCoveredDimensionCount += 1;
      }
      final status = _resolveDimensionStatus(
        generatedCount: generatedCount,
        acceptedCount: acceptedCount,
        omissionCount: omissionCount,
        minItemCount: dimension.minItemCount,
      );
      ledgerDimensions.add(
        OutputCoverageLedgerDimension(
          dimensionId: dimension.dimensionId,
          label: dimension.label,
          required: dimension.required,
          minItemCount: dimension.minItemCount,
          generatedSlotCount: generatedCount,
          acceptedSlotCount: acceptedCount,
          omissionCount: omissionCount,
          status: status,
        ),
      );
    }

    final generatedSlotIds = generatedSignals
        .map((signal) => signal.slotId.trim())
        .where((slotId) => slotId.isNotEmpty)
        .toSet();
    final acceptedSlotIds = acceptedSignals
        .map((signal) => signal.slotId.trim())
        .where((slotId) => slotId.isNotEmpty)
        .toSet();
    final summaryCharCounts = generatedSignals
        .map((signal) => signal.summaryCharCount)
        .where((count) => count > 0)
        .toList(growable: false);
    final unresolvedOmissionReports = _unresolvedOmissionReports(
      omissionReports: omissionReports,
      coverageContract: coverageContract,
      coverageLedgerDimensions: ledgerDimensions,
      coveredDimensionCount: coveredDimensionCount,
    );
    final unresolvedContinuationRequests = _unresolvedContinuationRequests(
      continuationRequests: continuationRequests,
      coverageContract: coverageContract,
      coverageLedgerDimensions: ledgerDimensions,
      coveredDimensionCount: coveredDimensionCount,
    );
    final compressionRisk = _buildCompressionRisk(
      budgetPolicy: budgetPolicy,
      coverageContract: coverageContract,
      dimensions: ledgerDimensions,
      totalGeneratedSlots: generatedSlotIds.length,
      summaryCharCounts: summaryCharCounts,
      omissionReports: unresolvedOmissionReports,
      continuationRequests: unresolvedContinuationRequests,
      coveredDimensionCount: coveredDimensionCount,
    );
    final completionStatus = _resolveCompletionStatus(
      coverageContract: coverageContract,
      coverageLedgerDimensions: ledgerDimensions,
      coveredDimensionCount: coveredDimensionCount,
      compressionRisk: compressionRisk,
      omissionReports: unresolvedOmissionReports,
      continuationRequests: unresolvedContinuationRequests,
    );
    final coverageLedger = OutputCoverageLedger(
      contractId: coverageContract.contractId,
      totalGeneratedSlots: generatedSlotIds.length,
      totalAcceptedSlots: acceptedSlotIds.length,
      coveredDimensionCount: coveredDimensionCount,
      acceptedCoveredDimensionCount: acceptedCoveredDimensionCount,
      completionStatus: completionStatus,
      dimensions: List<OutputCoverageLedgerDimension>.unmodifiable(
        ledgerDimensions,
      ),
      metadata: <String, Object?>{
        'min_covered_dimensions': coverageContract.minCoveredDimensions,
        'required_dimension_ids': coverageContract.dimensions
            .where((dimension) => dimension.required)
            .map((dimension) => dimension.dimensionId)
            .toList(growable: false),
      },
    );
    return OutputContractEvaluation(
      coverageLedger: coverageLedger,
      compressionRisk: compressionRisk,
      completionStatus: completionStatus,
    );
  }

  List<OmissionReport> _unresolvedOmissionReports({
    required List<OmissionReport> omissionReports,
    required OutputCoverageContract coverageContract,
    required List<OutputCoverageLedgerDimension> coverageLedgerDimensions,
    required int coveredDimensionCount,
  }) {
    if (omissionReports.isEmpty) {
      return const <OmissionReport>[];
    }
    final dimensionById = <String, OutputCoverageLedgerDimension>{
      for (final dimension in coverageLedgerDimensions)
        if (dimension.dimensionId.trim().isNotEmpty)
          dimension.dimensionId: dimension,
    };
    return omissionReports.where((report) {
      if (!report.isActionable) {
        return false;
      }
      return _referencesBlockingCoverageGap(
        dimensionIds: report.omittedDimensionIds,
        coverageContract: coverageContract,
        dimensionById: dimensionById,
        coveredDimensionCount: coveredDimensionCount,
      );
    }).toList(growable: false);
  }

  List<ContinuationRequest> _unresolvedContinuationRequests({
    required List<ContinuationRequest> continuationRequests,
    required OutputCoverageContract coverageContract,
    required List<OutputCoverageLedgerDimension> coverageLedgerDimensions,
    required int coveredDimensionCount,
  }) {
    if (continuationRequests.isEmpty) {
      return const <ContinuationRequest>[];
    }
    final dimensionById = <String, OutputCoverageLedgerDimension>{
      for (final dimension in coverageLedgerDimensions)
        if (dimension.dimensionId.trim().isNotEmpty)
          dimension.dimensionId: dimension,
    };
    return continuationRequests.where((request) {
      if (!request.isActionable) {
        return false;
      }
      return _referencesBlockingCoverageGap(
        dimensionIds: request.missingDimensionIds,
        coverageContract: coverageContract,
        dimensionById: dimensionById,
        coveredDimensionCount: coveredDimensionCount,
      );
    }).toList(growable: false);
  }

  bool _referencesBlockingCoverageGap({
    required List<String> dimensionIds,
    required OutputCoverageContract coverageContract,
    required Map<String, OutputCoverageLedgerDimension> dimensionById,
    required int coveredDimensionCount,
  }) {
    if (dimensionIds.isEmpty) {
      return true;
    }
    for (final dimensionId in dimensionIds) {
      if (_isBlockingCoverageGap(
        dimension: dimensionById[dimensionId],
        coveredDimensionCount: coveredDimensionCount,
        minCoveredDimensions: coverageContract.minCoveredDimensions,
      )) {
        return true;
      }
    }
    return false;
  }

  bool _isBlockingCoverageGap({
    required OutputCoverageLedgerDimension? dimension,
    required int coveredDimensionCount,
    required int minCoveredDimensions,
  }) {
    if (dimension == null) {
      return true;
    }
    if (dimension.status == OutputCoverageStatuses.covered) {
      return false;
    }
    if (dimension.required) {
      return true;
    }
    return coveredDimensionCount < minCoveredDimensions;
  }

  Map<String, int> _countByDimension(
    List<OutputCoverageSignal> signals,
    Map<String, OutputCoverageDimension> dimensionById,
  ) {
    final dimensionSlots = <String, Set<String>>{};
    final dimensionCounts = <String, int>{};
    for (final signal in signals) {
      final dimensionId = signal.dimensionId.trim();
      if (dimensionId.isEmpty || !dimensionById.containsKey(dimensionId)) {
        continue;
      }
      final slotId = signal.slotId.trim();
      if (slotId.isEmpty) {
        dimensionCounts[dimensionId] = (dimensionCounts[dimensionId] ?? 0) + 1;
        continue;
      }
      final slots = dimensionSlots.putIfAbsent(dimensionId, () => <String>{});
      slots.add(slotId);
    }
    for (final entry in dimensionSlots.entries) {
      dimensionCounts[entry.key] = entry.value.length;
    }
    return dimensionCounts;
  }

  String _resolveDimensionStatus({
    required int generatedCount,
    required int acceptedCount,
    required int omissionCount,
    required int minItemCount,
  }) {
    if (acceptedCount >= minItemCount) {
      return OutputCoverageStatuses.covered;
    }
    if (generatedCount > 0 || acceptedCount > 0) {
      return OutputCoverageStatuses.partial;
    }
    if (omissionCount > 0) {
      return OutputCoverageStatuses.omitted;
    }
    return OutputCoverageStatuses.uncovered;
  }

  OutputCompressionRisk _buildCompressionRisk({
    required OutputBudgetPolicy budgetPolicy,
    required OutputCoverageContract coverageContract,
    required List<OutputCoverageLedgerDimension> dimensions,
    required int totalGeneratedSlots,
    required List<int> summaryCharCounts,
    required List<OmissionReport> omissionReports,
    required List<ContinuationRequest> continuationRequests,
    required int coveredDimensionCount,
  }) {
    final signalCodes = <String>[];
    final hasBelowMinOutputSlots =
        totalGeneratedSlots < budgetPolicy.minOutputSlots;
    if (hasBelowMinOutputSlots) {
      signalCodes.add(OutputCompressionSignalCodes.belowMinOutputSlots);
    }
    if (summaryCharCounts.any(
      (count) => count > budgetPolicy.maxSummaryCharsPerItem,
    )) {
      signalCodes.add(OutputCompressionSignalCodes.oversizedItemSummary);
    }
    if (dimensions.any(
      (dimension) =>
          dimension.required &&
          dimension.acceptedSlotCount < dimension.minItemCount,
    )) {
      signalCodes.add(OutputCompressionSignalCodes.uncoveredRequiredDimension);
    }
    if (coveredDimensionCount < coverageContract.minCoveredDimensions) {
      signalCodes.add(
        OutputCompressionSignalCodes.insufficientCoveredDimensions,
      );
    }
    if (omissionReports.isNotEmpty) {
      signalCodes.add(OutputCompressionSignalCodes.omissionReported);
    }
    if (continuationRequests.isNotEmpty) {
      signalCodes.add(OutputCompressionSignalCodes.continuationRequested);
    }
    final level = _resolveCompressionRiskLevel(signalCodes);
    return OutputCompressionRisk(
      level: level,
      signalCodes: List<String>.unmodifiable(signalCodes),
      summary: _buildCompressionRiskSummary(
        level: level,
        signalCodes: signalCodes,
        totalGeneratedSlots: totalGeneratedSlots,
        minOutputSlots: budgetPolicy.minOutputSlots,
      ),
      metadata: <String, Object?>{
        'max_summary_chars_per_item': budgetPolicy.maxSummaryCharsPerItem,
      },
    );
  }

  String _resolveCompressionRiskLevel(List<String> signalCodes) {
    if (signalCodes.isEmpty) {
      return OutputCompressionRiskLevels.none;
    }
    final hasHighSignal =
        signalCodes.contains(
          OutputCompressionSignalCodes.uncoveredRequiredDimension,
        ) ||
        signalCodes.contains(
          OutputCompressionSignalCodes.continuationRequested,
        ) ||
        (signalCodes.contains(
              OutputCompressionSignalCodes.belowMinOutputSlots,
            ) &&
            signalCodes.contains(
              OutputCompressionSignalCodes.insufficientCoveredDimensions,
            ));
    if (hasHighSignal) {
      return OutputCompressionRiskLevels.high;
    }
    if (signalCodes.length >= 2) {
      return OutputCompressionRiskLevels.medium;
    }
    return OutputCompressionRiskLevels.low;
  }

  String _buildCompressionRiskSummary({
    required String level,
    required List<String> signalCodes,
    required int totalGeneratedSlots,
    required int minOutputSlots,
  }) {
    if (level == OutputCompressionRiskLevels.none) {
      return '输出覆盖和预算信号正常。';
    }
    if (signalCodes.contains(
      OutputCompressionSignalCodes.belowMinOutputSlots,
    )) {
      return '当前输出仅生成 $totalGeneratedSlots 个槽位，低于最低期望 $minOutputSlots，存在压缩风险。';
    }
    if (signalCodes.contains(
      OutputCompressionSignalCodes.continuationRequested,
    )) {
      return '当前输出显式请求续提，说明本轮未完成完整交付。';
    }
    return '当前输出存在覆盖或压缩信号，需要额外复核。';
  }

  String _resolveCompletionStatus({
    required OutputCoverageContract coverageContract,
    required List<OutputCoverageLedgerDimension> coverageLedgerDimensions,
    required int coveredDimensionCount,
    required OutputCompressionRisk compressionRisk,
    required List<OmissionReport> omissionReports,
    required List<ContinuationRequest> continuationRequests,
  }) {
    if (continuationRequests.isNotEmpty &&
        coverageContract.allowContinuationWhenIncomplete) {
      return OutputCompletionStatuses.continuationRecommended;
    }
    if (coverageLedgerDimensions.any(
          (dimension) =>
              dimension.required &&
              dimension.acceptedSlotCount < dimension.minItemCount,
        ) ||
        coveredDimensionCount < coverageContract.minCoveredDimensions ||
        omissionReports.isNotEmpty) {
      return OutputCompletionStatuses.coverageInsufficient;
    }
    if (compressionRisk.level == OutputCompressionRiskLevels.medium ||
        compressionRisk.level == OutputCompressionRiskLevels.high) {
      return OutputCompletionStatuses.compressed;
    }
    return OutputCompletionStatuses.completed;
  }
}
