import 'package:novel_agent_core/novel_agent_core.dart';

import 'llm_reference_extraction_prompt_builder_service.dart';
import 'llm_reference_extraction_response_parser_service.dart';

class LlmReferenceExtractionProposalGenerator
    implements ReferenceExtractionProposalGenerator {
  LlmReferenceExtractionProposalGenerator({
    required LlmGateway llmGateway,
    required String modelId,
    LlmReferenceExtractionPromptBuilderService? promptBuilderService,
    LlmReferenceExtractionResponseParserService? responseParserService,
  }) : _llmGateway = llmGateway,
       _modelId = modelId,
       _promptBuilderService =
           promptBuilderService ??
           const LlmReferenceExtractionPromptBuilderService(),
       _responseParserService =
           responseParserService ??
           const LlmReferenceExtractionResponseParserService();

  final LlmGateway _llmGateway;
  final String _modelId;
  final LlmReferenceExtractionPromptBuilderService _promptBuilderService;
  final LlmReferenceExtractionResponseParserService _responseParserService;

  @override
  Future<ReferenceExtractionProposalGenerationResult> generateProposals(
    ReferenceExtractionProposalGeneratorRequest request,
  ) async {
    final proposalPolicy =
        request.groupResolution.executionProfile.strategyProfile.proposalPolicy;
    final generationPolicy = request
        .groupResolution
        .executionProfile
        .strategyProfile
        .generationPolicy;
    final outputCoverageContract = request
        .groupResolution
        .executionProfile
        .strategyProfile
        .outputCoverageContract;
    final prompt = _promptBuilderService.build(request);
    var content = await _requestProposalContent(
      prompt: prompt,
      generationPolicy: generationPolicy,
      includeResponseFormat: true,
    );
    late final LlmReferenceExtractionParsedResponse parsedResponse;
    try {
      parsedResponse = _responseParserService.parseStructuredResponse(content);
    } on FormatException catch (_) {
      content = await _requestProposalContent(
        prompt:
            '$prompt\n\n补充要求：如果上一次 structured output 失败，请直接返回 JSON 对象本体，并修复所有字符串里的引号转义。',
        generationPolicy: generationPolicy,
        includeResponseFormat: false,
      );
      parsedResponse = _responseParserService.parseStructuredResponse(content);
    } on StateError {
      content = await _requestProposalContent(
        prompt:
            '$prompt\n\n补充要求：如果上一次 structured output 失败，请直接返回 JSON 对象本体，不要留空。',
        generationPolicy: generationPolicy,
        includeResponseFormat: false,
      );
      parsedResponse = _responseParserService.parseStructuredResponse(content);
    }
    final seedEntryById = <String, ReferenceEntryRecord>{
      for (final entry in request.seedSnapshot.entries) entry.entryId: entry,
    };
    final allowedCoverageDimensionIds = outputCoverageContract.dimensionIds
        .toSet();
    final proposals = <ReferenceExtractionProposal>[];
    for (final proposalMap in parsedResponse.proposals) {
      final seedEntryIds = ValueReaders.stringList(
        proposalMap['seed_entry_ids'],
      ).where(seedEntryById.containsKey).toList(growable: false);
      if (seedEntryIds.isEmpty) {
        continue;
      }
      final sourceRefs = <InformationSourceRef>[];
      final evidenceRefs = <NarrativeEvidenceRef>[];
      for (final seedEntryId in seedEntryIds) {
        final seedEntry = seedEntryById[seedEntryId];
        if (seedEntry == null) {
          continue;
        }
        sourceRefs.addAll(seedEntry.sourceRefs);
        evidenceRefs.addAll(seedEntry.evidenceRefs);
      }
      final proposalId = ValueReaders.stringValue(
        proposalMap['proposal_id'],
      ).trim();
      final entryId = ValueReaders.stringValue(proposalMap['entry_id']).trim();
      final entryKind = ValueReaders.stringValue(
        proposalMap['entry_kind'],
      ).trim();
      final title = ValueReaders.stringValue(proposalMap['title']).trim();
      final summary = ValueReaders.stringValue(proposalMap['summary']).trim();
      final coverageDimensionIds =
          ValueReaders.stringList(proposalMap['coverage_dimension_ids'])
              .where((dimensionId) {
                return allowedCoverageDimensionIds.contains(dimensionId.trim());
              })
              .toSet()
              .toList(growable: false);
      if (proposalId.isEmpty ||
          entryId.isEmpty ||
          entryKind.isEmpty ||
          !proposalPolicy.allowedEntryKinds.contains(entryKind) ||
          title.isEmpty ||
          summary.isEmpty ||
          (outputCoverageContract.requireExplicitCoverageSignals &&
              coverageDimensionIds.isEmpty)) {
        continue;
      }
      proposals.add(
        ReferenceExtractionProposal(
          proposalId: proposalId,
          entryId: entryId,
          entryNamespace: ValueReaders.stringValue(
            proposalMap['entry_namespace'],
            'semantic_extraction',
          ).trim(),
          entryKind: entryKind,
          title: title,
          summary: summary,
          payload: <String, Object?>{
            'seed_entry_ids': seedEntryIds,
            'generator': 'llm_reference_extraction',
            'batch_id': request.batch.batchId,
            'batch_index': request.batch.batchIndex,
          },
          sourceRefs: List<InformationSourceRef>.unmodifiable(sourceRefs),
          evidenceRefs: List<NarrativeEvidenceRef>.unmodifiable(evidenceRefs),
          tags: ValueReaders.stringList(proposalMap['tags']),
          coverageDimensionIds: coverageDimensionIds,
          confidence: ValueReaders.doubleValue(proposalMap['confidence']),
          metadata: <String, Object?>{
            'selected_group_id': request.groupResolution.selectedGroup.id,
            'instruction_profile_id':
                request.groupResolution.executionProfile.instructionProfileId,
            'batch_id': request.batch.batchId,
            'batch_index': request.batch.batchIndex,
          },
        ),
      );
    }
    final omissionReport = _buildOmissionReport(
      parsedResponse.omissionReport,
      request: request,
      outputCoverageContract: outputCoverageContract,
    );
    final continuationRequest = _buildContinuationRequest(
      parsedResponse.continuationRequest,
      request: request,
      outputCoverageContract: outputCoverageContract,
    );
    if (proposals.isEmpty &&
        omissionReport == null &&
        continuationRequest == null &&
        !_isExplicitNoOpContractResponse(parsedResponse)) {
      throw StateError(
        'reference extraction generator returned no usable proposals or continuation signals.',
      );
    }
    final capped = proposals.length <= proposalPolicy.maxProposalCount
        ? proposals
        : proposals
              .take(proposalPolicy.maxProposalCount)
              .toList(growable: false);
    return ReferenceExtractionProposalGenerationResult(
      proposals: List<ReferenceExtractionProposal>.unmodifiable(capped),
      omissionReport: omissionReport,
      continuationRequest: continuationRequest,
    );
  }

  Future<String> _requestProposalContent({
    required String prompt,
    required ReferenceExtractionGenerationPolicy generationPolicy,
    required bool includeResponseFormat,
  }) async {
    final options = <String, Object?>{
      'stream': false,
      'temperature': generationPolicy.temperature,
    };
    if (includeResponseFormat) {
      options['response_format'] = <String, Object?>{
        'type': generationPolicy.responseFormatType,
      };
    }
    final response = await _llmGateway.requestChat(
      request: ChatRequest.textPrompt(
        prompt: prompt,
        modelId: _modelId,
        options: options,
      ),
    );
    return ValueReaders.stringValue(response['content']);
  }

  OmissionReport? _buildOmissionReport(
    JsonMap json, {
    required ReferenceExtractionProposalGeneratorRequest request,
    required OutputCoverageContract outputCoverageContract,
  }) {
    if (json.isEmpty) {
      return null;
    }
    final omittedDimensionIds =
        ValueReaders.stringList(json['omitted_dimension_ids'])
            .where(outputCoverageContract.dimensionIds.contains)
            .toList(growable: false);
    final reasonCode = ValueReaders.stringValue(json['reason_code']).trim();
    final summary = ValueReaders.stringValue(json['summary']).trim();
    if (omittedDimensionIds.isEmpty && reasonCode.isEmpty && summary.isEmpty) {
      return null;
    }
    final reportId = ValueReaders.stringValue(json['report_id']).trim();
    final report = OmissionReport(
      reportId: reportId.isEmpty
          ? '${request.runId}_${request.batch.batchId}_omission'
          : reportId,
      contractId: outputCoverageContract.contractId,
      omittedDimensionIds: omittedDimensionIds,
      reasonCode: reasonCode,
      summary: summary,
      recommendedNextFocus: ValueReaders.stringValue(
        json['recommended_next_focus'],
      ).trim(),
      metadata: <String, Object?>{
        'batch_id': request.batch.batchId,
        'batch_index': request.batch.batchIndex,
      },
    );
    return report.isActionable ? report : null;
  }

  ContinuationRequest? _buildContinuationRequest(
    JsonMap json, {
    required ReferenceExtractionProposalGeneratorRequest request,
    required OutputCoverageContract outputCoverageContract,
  }) {
    if (json.isEmpty) {
      return null;
    }
    final missingDimensionIds =
        ValueReaders.stringList(json['missing_dimension_ids'])
            .where(outputCoverageContract.dimensionIds.contains)
            .toList(growable: false);
    final continuationReason = ValueReaders.stringValue(
      json['continuation_reason'],
    ).trim();
    final recommendedNextFocus = ValueReaders.stringValue(
      json['recommended_next_focus'],
    ).trim();
    final suggestedSlotCount = ValueReaders.intValue(
      json['suggested_slot_count'],
    );
    if (missingDimensionIds.isEmpty &&
        continuationReason.isEmpty &&
        recommendedNextFocus.isEmpty &&
        suggestedSlotCount <= 0) {
      return null;
    }
    final requestId = ValueReaders.stringValue(json['request_id']).trim();
    final continuationRequest = ContinuationRequest(
      requestId: requestId.isEmpty
          ? '${request.runId}_${request.batch.batchId}_continuation'
          : requestId,
      contractId: outputCoverageContract.contractId,
      continuationReason: continuationReason,
      missingDimensionIds: missingDimensionIds,
      recommendedNextFocus: recommendedNextFocus,
      suggestedSlotCount: suggestedSlotCount,
      metadata: <String, Object?>{
        'batch_id': request.batch.batchId,
        'batch_index': request.batch.batchIndex,
      },
    );
    return continuationRequest.isActionable ? continuationRequest : null;
  }

  bool _isExplicitNoOpContractResponse(
    LlmReferenceExtractionParsedResponse parsedResponse,
  ) {
    final omissionReport = parsedResponse.omissionReport;
    final continuationRequest = parsedResponse.continuationRequest;
    final omissionReasonCode = ValueReaders.stringValue(
      omissionReport['reason_code'],
    ).trim().toLowerCase();
    final continuationReason = ValueReaders.stringValue(
      continuationRequest['continuation_reason'],
    ).trim().toLowerCase();
    return omissionReasonCode == OmissionReasonCodes.noOmission ||
        continuationReason == ContinuationReasonCodes.noContinuation;
  }
}
