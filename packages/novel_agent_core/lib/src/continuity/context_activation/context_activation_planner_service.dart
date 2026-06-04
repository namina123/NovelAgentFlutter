import '../../common/value_readers.dart';
import 'context_activation_item.dart';
import 'context_activation_plan.dart';
import 'context_activation_reason_codes.dart';
import 'context_activation_report.dart';

class ContextActivationPlannerService {
  const ContextActivationPlannerService();

  ContextActivationReport buildReport({
    required ContextActivationPlan plan,
    String reportId = '',
    String source = 'context_activation_planner',
  }) {
    final availableBudget = _availableBudget(plan);
    var remainingBudget = availableBudget;
    final orderedItems = plan.items.toList()
      ..sort((left, right) => _compareItems(left, right));

    final reportItems = <ContextActivationItem>[];
    final selectedItemIds = <String>[];
    final omittedItemIds = <String>[];
    final truncatedItemIds = <String>[];
    var usedChars = 0;
    var omittedChars = 0;

    for (final item in orderedItems) {
      final required = _isRequired(item);
      final pinned = _isPinned(item);
      final requestedChars = item.requestedChars;
      final effectiveRequestedChars = requestedChars < 0 ? 0 : requestedChars;

      if (effectiveRequestedChars == 0) {
        final selectedItem = item.copyWith(
          includedChars: 0,
          selected: true,
          omitted: false,
          truncated: false,
          omissionReason: '',
          truncationReason: '',
          metadata: _augmentedMetadata(
            item,
            required: required,
            pinned: pinned,
            weight: _weightOf(item),
            decision: 'selected_zero_cost',
          ),
        );
        reportItems.add(selectedItem);
        selectedItemIds.add(selectedItem.itemId);
        continue;
      }

      if (remainingBudget >= effectiveRequestedChars) {
        final selectedItem = item.copyWith(
          includedChars: effectiveRequestedChars,
          selected: true,
          omitted: false,
          truncated: false,
          omissionReason: '',
          truncationReason: '',
          metadata: _augmentedMetadata(
            item,
            required: required,
            pinned: pinned,
            weight: _weightOf(item),
            decision: 'selected_full',
          ),
        );
        reportItems.add(selectedItem);
        selectedItemIds.add(selectedItem.itemId);
        usedChars += effectiveRequestedChars;
        remainingBudget -= effectiveRequestedChars;
        continue;
      }

      if (remainingBudget > 0) {
        final truncatedItem = item.copyWith(
          includedChars: remainingBudget,
          selected: true,
          omitted: false,
          truncated: true,
          omissionReason: '',
          truncationReason: required
              ? 'required_budget_clip'
              : pinned
              ? 'pinned_budget_clip'
              : 'budget_clip',
          metadata: _augmentedMetadata(
            item,
            required: required,
            pinned: pinned,
            weight: _weightOf(item),
            decision: 'selected_truncated',
          ),
        );
        reportItems.add(truncatedItem);
        selectedItemIds.add(truncatedItem.itemId);
        truncatedItemIds.add(truncatedItem.itemId);
        usedChars += remainingBudget;
        remainingBudget = 0;
        continue;
      }

      if (required) {
        final requiredItem = item.copyWith(
          includedChars: 0,
          selected: true,
          omitted: false,
          truncated: true,
          omissionReason: '',
          truncationReason: 'required_budget_exhausted',
          metadata: _augmentedMetadata(
            item,
            required: required,
            pinned: pinned,
            weight: _weightOf(item),
            decision: 'selected_required_without_budget',
          ),
        );
        reportItems.add(requiredItem);
        selectedItemIds.add(requiredItem.itemId);
        truncatedItemIds.add(requiredItem.itemId);
        continue;
      }

      final omittedItem = item.copyWith(
        includedChars: 0,
        selected: false,
        omitted: true,
        truncated: false,
        omissionReason: pinned ? 'pinned_budget_exhausted' : 'budget_exhausted',
        truncationReason: '',
        metadata: _augmentedMetadata(
          item,
          required: required,
          pinned: pinned,
          weight: _weightOf(item),
          decision: 'omitted_budget_exhausted',
        ),
      );
      reportItems.add(omittedItem);
      omittedItemIds.add(omittedItem.itemId);
      omittedChars += effectiveRequestedChars;
    }

    return ContextActivationReport(
      reportId: reportId.trim().isEmpty ? '${plan.planId}.report' : reportId,
      planId: plan.planId,
      source: source,
      budgetChars: availableBudget,
      usedChars: usedChars,
      omittedChars: omittedChars,
      items: reportItems,
      selectedItemIds: selectedItemIds,
      omittedItemIds: omittedItemIds,
      truncatedItemIds: truncatedItemIds,
      summary: _buildSummary(
        selectedCount: selectedItemIds.length,
        omittedCount: omittedItemIds.length,
        truncatedCount: truncatedItemIds.length,
        availableBudget: availableBudget,
        usedChars: usedChars,
      ),
      schemaVersion: plan.schemaVersion,
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        ...plan.metadata,
        'task_type': plan.taskType,
        'reserved_output_chars': plan.reservedOutputChars,
        'available_budget_chars': availableBudget,
      }),
    );
  }

  int _compareItems(ContextActivationItem left, ContextActivationItem right) {
    final requiredCompare = _boolRank(
      _isRequired(right),
    ).compareTo(_boolRank(_isRequired(left)));
    if (requiredCompare != 0) {
      return requiredCompare;
    }
    final pinnedCompare = _boolRank(
      _isPinned(right),
    ).compareTo(_boolRank(_isPinned(left)));
    if (pinnedCompare != 0) {
      return pinnedCompare;
    }
    final weightCompare = _weightOf(right).compareTo(_weightOf(left));
    if (weightCompare != 0) {
      return weightCompare;
    }
    final reasonCompare = right.activationReasons.length.compareTo(
      left.activationReasons.length,
    );
    if (reasonCompare != 0) {
      return reasonCompare;
    }
    final requestedCompare = left.requestedChars.compareTo(
      right.requestedChars,
    );
    if (requestedCompare != 0) {
      return requestedCompare;
    }
    return left.itemId.compareTo(right.itemId);
  }

  int _availableBudget(ContextActivationPlan plan) {
    final remaining = plan.budgetChars - plan.reservedOutputChars;
    return remaining < 0 ? 0 : remaining;
  }

  bool _isPinned(ContextActivationItem item) {
    if (item.activationReasons.contains(
      ContextActivationReasonCodes.manualPin,
    )) {
      return true;
    }
    return ValueReaders.boolValue(item.reasonDetails['pinned']) ||
        ValueReaders.boolValue(item.reasonDetails['pin']) ||
        ValueReaders.boolValue(item.metadata['pinned']) ||
        ValueReaders.boolValue(item.metadata['pin']);
  }

  bool _isRequired(ContextActivationItem item) {
    return ValueReaders.boolValue(item.reasonDetails['required']) ||
        ValueReaders.boolValue(item.reasonDetails['is_required']) ||
        ValueReaders.boolValue(item.metadata['required']) ||
        ValueReaders.boolValue(item.metadata['is_required']);
  }

  int _weightOf(ContextActivationItem item) {
    final explicitWeight = _firstDefinedWeight(
      item.reasonDetails['weight'],
      item.metadata['weight'],
      item.reasonDetails['priority_weight'],
      item.metadata['priority_weight'],
    );
    if (explicitWeight != null) {
      return explicitWeight;
    }

    var score = 0;
    for (final reason in item.activationReasons) {
      switch (reason) {
        case ContextActivationReasonCodes.manualPin:
          score += 1000;
        case ContextActivationReasonCodes.profilePolicy:
          score += 300;
        case ContextActivationReasonCodes.ref:
          score += 220;
        case ContextActivationReasonCodes.claim:
          score += 200;
        case ContextActivationReasonCodes.taskType:
          score += 120;
        case ContextActivationReasonCodes.semanticRetrieval:
          score += 80;
        case ContextActivationReasonCodes.keyword:
          score += 40;
        default:
          score += 20;
      }
    }
    if (item.refs.isNotEmpty) {
      score += 10;
    }
    return score;
  }

  int? _firstDefinedWeight(
    Object? first,
    Object? second,
    Object? third,
    Object? fourth,
  ) {
    for (final candidate in <Object?>[first, second, third, fourth]) {
      if (candidate == null) {
        continue;
      }
      if (candidate is num) {
        return candidate.round();
      }
      final text = candidate.toString().trim();
      if (text.isEmpty) {
        continue;
      }
      final parsed = int.tryParse(text);
      if (parsed != null) {
        return parsed;
      }
      final parsedDouble = double.tryParse(text);
      if (parsedDouble != null) {
        return parsedDouble.round();
      }
    }
    return null;
  }

  int _boolRank(bool value) => value ? 1 : 0;

  String _buildSummary({
    required int selectedCount,
    required int omittedCount,
    required int truncatedCount,
    required int availableBudget,
    required int usedChars,
  }) {
    return 'selected $selectedCount, omitted $omittedCount, truncated $truncatedCount, budget $usedChars/$availableBudget chars.';
  }

  Map<String, Object?> _augmentedMetadata(
    ContextActivationItem item, {
    required bool required,
    required bool pinned,
    required int weight,
    required String decision,
  }) {
    return <String, Object?>{
      ...item.metadata,
      'planner_required': required,
      'planner_pinned': pinned,
      'planner_weight': weight,
      'planner_decision': decision,
    };
  }
}
