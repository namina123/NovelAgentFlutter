import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

class LlmReferenceExtractionPromptBuilderService {
  const LlmReferenceExtractionPromptBuilderService();

  String build(ReferenceExtractionProposalGeneratorRequest request) {
    final proposalPolicy =
        request.groupResolution.executionProfile.strategyProfile.proposalPolicy;
    final outputBudgetPolicy = request
        .groupResolution
        .executionProfile
        .strategyProfile
        .outputBudgetPolicy;
    final outputCoverageContract = request
        .groupResolution
        .executionProfile
        .strategyProfile
        .outputCoverageContract;
    final continuationContext = request.continuationContext;
    final relevantSeedEntries = request.seedSnapshot.entries
        .where((entry) {
          final payload = entry.payload;
          final sectionIndex = ValueReaders.intValue(payload['section_index']);
          return request.batch.sectionIndexes.contains(sectionIndex);
        })
        .take(proposalPolicy.seedEntryLimit)
        .map(
          (entry) => <String, Object?>{
            'entry_id': entry.entryId,
            'entry_namespace': entry.entryNamespace,
            'entry_kind': entry.entryKind,
            'title': entry.title,
            'summary': entry.summary,
            'tags': entry.tags,
            'payload': entry.payload,
          },
        )
        .toList(growable: false);
    final seedEntries = relevantSeedEntries.isEmpty
        ? request.seedSnapshot.entries
              .take(proposalPolicy.seedEntryLimit)
              .map(
                (entry) => <String, Object?>{
                  'entry_id': entry.entryId,
                  'entry_namespace': entry.entryNamespace,
                  'entry_kind': entry.entryKind,
                  'title': entry.title,
                  'summary': entry.summary,
                  'tags': entry.tags,
                  'payload': entry.payload,
                },
              )
              .toList(growable: false)
        : relevantSeedEntries;
    return '''
你正在执行 NovelAgent 的 reference_extraction.proposal_generation 阶段。

任务：
针对当前 source batch 的原文与 seed scaffolding，为《${request.sourceDocumentTitle}》生成 ${proposalPolicy.minProposalCount} 到 ${proposalPolicy.maxProposalCount} 条“可进入正式提取审核”的候选条目，并按输出完整性合同诚实报告遗漏与续提需求。

硬性要求：
1. 只能返回一个 JSON 对象，不要 markdown，不要解释，不要代码块。
2. JSON 顶层格式必须是：
{
  "proposals": [
    {
      "proposal_id": "...",
      "entry_id": "...",
      "entry_namespace": "...",
      "entry_kind": "...",
      "title": "...",
      "summary": "...",
      "seed_entry_ids": ["..."],
      "coverage_dimension_ids": ["..."],
      "tags": ["..."],
      "confidence": 0.0
    }
  ],
  "omission_report": {
    "report_id": "...",
    "contract_id": "${outputCoverageContract.contractId}",
    "omitted_dimension_ids": ["..."],
    "reason_code": "...",
    "summary": "...",
    "recommended_next_focus": "..."
  },
  "continuation_request": {
    "request_id": "...",
    "contract_id": "${outputCoverageContract.contractId}",
    "continuation_reason": "...",
    "missing_dimension_ids": ["..."],
    "recommended_next_focus": "...",
    "suggested_slot_count": 0
  }
}
3. omission_report 和 continuation_request 都是可选字段；只有真的存在遗漏或需要续提时才填写，否则请保留空对象或不填写具体内容。
4. title 和 summary 必须用${proposalPolicy.outputLanguage == 'zh-CN' ? '中文' : proposalPolicy.outputLanguage}。
5. 每条 summary 必须尽量控制在 ${outputBudgetPolicy.maxSummaryCharsPerItem} 字以内，优先保留覆盖广度，不要用单条大概括吞掉多个独立事实。
6. seed_entry_ids 只能引用下面 seed_entries 中真实存在的 entry_id；如果当前 batch 能找到对应 seed，至少引用 1 个。
7. coverage_dimension_ids 只能引用下面 coverage_dimensions 中真实存在的 dimension_id；每条 proposal 至少给 1 个。
8. confidence 为 0 到 1 的小数；只有证据很稳时才允许 >= 0.80。
9. 不要编造当前 batch 原文中不存在的具体剧情、世界设定或风格结论。
10. entry_kind 只允许：
${proposalPolicy.allowedEntryKinds.map((kind) => '   - $kind').join('\n')}
11. summary 应体现当前 batch 的真实证据，而不是只复述 seed 标题。
12. 如果当前 batch 因输出预算、证据局限或本轮范围原因无法覆盖合同维度，必须显式填写 omission_report，而不是静默省略。
13. 如果当前轮装不下，但还有明确应继续补提的维度，必须填写 continuation_request；这不是失败，而是正常续提信号。

偏好：
1. 优先提取能直接复用的角色/地点/世界事实。
2. 优先提取命名、象征、叙事结构、笔法习惯。
3. 若涉及引用边界、使用范围或版权风险，允许输出 reference_work_boundary。
4. 避免只重复 seed 片段标题；应给出“提炼后的条目”。
5. 如果当前 batch 明显只是局部，不要把整书级结论说满；可以保留局部性。
6. 当输出预算紧张时，优先拆成多个较短条目，不要把多个维度压成一条“总括”。

运行信息：
- source_language=${request.sourceLanguage}
- target_language=${request.targetLanguage}
- proposal_output_language=${proposalPolicy.outputLanguage}
- selected_group=${request.groupResolution.selectedGroup.id}
- instruction_profile=${request.groupResolution.executionProfile.instructionProfileId}
- tool_permission_profile=${request.groupResolution.executionProfile.toolPermissionProfileId}
- strategy_profile=${request.groupResolution.executionProfile.strategyProfile.profileId}
- batch_id=${request.batch.batchId}
- batch_index=${request.batch.batchIndex}
- batch_structure_mode=${request.batch.structureMode}
- batch_split_mode=${request.batch.splitMode}
- batch_headings=${request.batch.headings.join(' | ')}
- batch_char_count=${request.batch.charCount}
- batch_coverage=${request.batchProgress.completedBatchCount}/${request.batchPlan.batches.length}
- execution_concurrency_mode=${request.groupResolution.executionProfile.strategyProfile.executionDiscipline.concurrencyMode}
- output_contract_id=${outputCoverageContract.contractId}
- output_target_density=${outputBudgetPolicy.targetOutputDensity}
- output_min_slots=${outputBudgetPolicy.minOutputSlots}
- output_max_slots=${outputBudgetPolicy.maxOutputSlots}
- output_must_report_omissions=${outputBudgetPolicy.mustReportOmissions}
- output_continuation_allowed=${outputBudgetPolicy.continuationAllowed}
- output_compression_fallback_mode=${outputBudgetPolicy.compressionFallbackMode}
- continuation_round=${continuationContext?.roundIndex ?? 0}
- continuation_target_batches=${continuationContext?.targetBatchIds.join(' | ') ?? ''}
- continuation_focus_dimensions=${continuationContext?.focusDimensionIds.join(' | ') ?? ''}
- continuation_recommended_focus=${continuationContext?.recommendedNextFocus ?? ''}

seed_entries=
${const JsonEncoder.withIndent('  ').convert(seedEntries)}

coverage_dimensions=
${const JsonEncoder.withIndent('  ').convert(outputCoverageContract.dimensions.map((dimension) => <String, Object?>{'dimension_id': dimension.dimensionId, 'label': dimension.label, 'description': dimension.description, 'min_item_count': dimension.minItemCount, 'required': dimension.required}).toList(growable: false))}

source_batch_text=
${request.batch.sourceText}

${continuationContext == null ? '' : '''
continuation_context=
${const JsonEncoder.withIndent('  ').convert(continuationContext.toJson())}

续提补充要求：
1. 这是一轮 continuation，不要简单重复上一轮已经提过的概括条目。
2. 优先覆盖 continuation_context 中的 focus_dimension_ids 与 recommended_next_focus。
3. 若上一轮已经有局部覆盖，本轮应补缺口、拆细节、推进覆盖，而不是原样重述。
'''}
''';
  }
}
