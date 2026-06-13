import 'reference_ingestion_budget_policy.dart';

class ReferenceIngestionBudgetResolverService {
  const ReferenceIngestionBudgetResolverService();

  ReferenceIngestionBudgetResolution resolve({
    required ReferenceIngestionBudgetPolicy policy,
    int? availableContextChars,
  }) {
    final resolvedContextChars =
        (availableContextChars ?? policy.defaultAvailableContextChars).clamp(
          4000,
          200000,
        );
    final instructionReserveChars =
        (resolvedContextChars * policy.instructionReserveRatio).round();
    final carryForwardReserveChars =
        (resolvedContextChars * policy.carryForwardReserveRatio).round();
    final responseReserveChars =
        (resolvedContextChars * policy.responseReserveRatio).round();
    final safetyReserveChars =
        (resolvedContextChars * policy.safetyReserveRatio).round();
    final remainingSourceBudget =
        resolvedContextChars -
        instructionReserveChars -
        carryForwardReserveChars -
        responseReserveChars -
        safetyReserveChars;
    final maxSourceChars = remainingSourceBudget.clamp(
      policy.minSourceChars,
      policy.maxSourceChars,
    );
    final targetSourceChars = (resolvedContextChars * policy.sourceWindowRatio)
        .round()
        .clamp(policy.minSourceChars, maxSourceChars);
    return ReferenceIngestionBudgetResolution(
      availableContextChars: resolvedContextChars,
      targetSourceChars: targetSourceChars,
      minSourceChars: policy.minSourceChars.clamp(400, targetSourceChars),
      maxSourceChars: maxSourceChars,
      minSectionsPerBatch: policy.minSectionsPerBatch.clamp(1, 32),
      maxSectionsPerBatch: policy.maxSectionsPerBatch.clamp(1, 32),
      instructionReserveChars: instructionReserveChars,
      carryForwardReserveChars: carryForwardReserveChars,
      responseReserveChars: responseReserveChars,
      safetyReserveChars: safetyReserveChars,
      planningMode: policy.planningMode,
      oversizeSectionSplitPolicy: policy.oversizeSectionSplitPolicy,
      batchGoalKind: policy.batchGoalKind,
      allowStructureFallback: policy.allowStructureFallback,
    );
  }
}
