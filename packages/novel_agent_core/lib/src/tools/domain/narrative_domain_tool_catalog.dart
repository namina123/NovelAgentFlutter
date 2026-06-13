import '../../common/json_types.dart';
import '../../common/open_json_contract_codec_service.dart';
import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
import '../../information.dart';
import '../../runtime/tool_round_evidence.dart';
import 'domain_tool_request.dart';
import 'narrative_domain_tool_definition.dart';
import 'narrative_domain_tool_names.dart';
import 'narrative_domain_tool_parse_issue.dart';
import 'narrative_domain_tool_parse_result.dart';
import 'narrative_domain_tool_validation_codes.dart';

class NarrativeDomainToolCatalog {
  NarrativeDomainToolCatalog({
    ChapterNarrativeSubmissionCodecService? submissionCodecService,
    NarrativeStateClaimCodecService? claimCodecService,
    NarrativeSemanticReviewCodecService? semanticReviewCodecService,
    NarrativeProfileCodecService? profileCodecService,
    NarrativeConstraintBindingCodecService? constraintBindingCodecService,
    ChapterNarrativeSubmissionValidator? submissionValidator,
    NarrativeProfileProposalValidator? profileProposalValidator,
  }) : _submissionCodecService =
           submissionCodecService ??
           const ChapterNarrativeSubmissionCodecService(),
       _claimCodecService =
           claimCodecService ?? const NarrativeStateClaimCodecService(),
       _semanticReviewCodecService =
           semanticReviewCodecService ??
           const NarrativeSemanticReviewCodecService(),
       _profileCodecService =
           profileCodecService ?? const NarrativeProfileCodecService(),
       _constraintBindingCodecService =
           constraintBindingCodecService ??
           const NarrativeConstraintBindingCodecService(),
       _submissionValidator =
           submissionValidator ?? const ChapterNarrativeSubmissionValidator(),
       _profileProposalValidator =
           profileProposalValidator ??
           const NarrativeProfileProposalValidator();

  final ChapterNarrativeSubmissionCodecService _submissionCodecService;
  final NarrativeStateClaimCodecService _claimCodecService;
  final NarrativeSemanticReviewCodecService _semanticReviewCodecService;
  final NarrativeProfileCodecService _profileCodecService;
  final NarrativeConstraintBindingCodecService _constraintBindingCodecService;
  final ChapterNarrativeSubmissionValidator _submissionValidator;
  final NarrativeProfileProposalValidator _profileProposalValidator;

  static const OpenJsonContractCodecService _codecService =
      OpenJsonContractCodecService();

  static const List<NarrativeDomainToolDefinition>
  definitions = <NarrativeDomainToolDefinition>[
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.submitChapterDelivery,
      displayName: '提交章节交付',
      description:
          '一次性提交章节正文、目标路径和结构化提交包，用统一交付合同替代零散文件写入。提交前必须满足当前执行约束；如果本章形成了稳定 continuity/state 变化，可在 submission.claims 或顶层 claims 中一并提交。连续章节建议至少填写 submission.summary，并在 submission.final_state_summary 中记录章末状态与下一章承接锚点，避免下一章开头倒带重演。若上下文列出表达风险信号，应先自行改写 chapter_content，避免带风险信号交付。',
      parametersSchema: _submitChapterDeliverySchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.submitNarrativeStateClaims,
      displayName: '提交叙事状态声明',
      description: '提交开放叙事状态 claims，保留未知 namespace 和 payload，不做文学语义判断。',
      parametersSchema: _submitNarrativeStateClaimsSchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
      displayName: '提出项目叙事解释器更新',
      description: '提出项目级 narrative profile 更新提案，只做开放结构校验，不直接改长期规则。',
      parametersSchema: _proposeNarrativeProfileUpdateSchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.submitSemanticReview,
      displayName: '提交语义复核',
      description: '提交 reviewer 的结构化 findings 和 disposition 建议，建议不等于最终调度。',
      parametersSchema: _submitSemanticReviewSchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.proposeConstraintBinding,
      displayName: '提出约束绑定',
      description: '提出项目级或阶段级约束绑定，保留开放 constraint payload，不内置题材枚举。',
      parametersSchema: _proposeConstraintBindingSchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.requestProfileClarification,
      displayName: '请求规则澄清',
      description: '在缺少关键信息时提出一个小而具体的澄清问题，不把普通偏好展开成大型表单。',
      parametersSchema: _requestProfileClarificationSchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.requestExternalResearch,
      displayName: '请求外部研究',
      description: '提出受控的外部研究请求，只形成结构化 request，不在 core 直接联网。',
      parametersSchema: _requestExternalResearchSchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.submitResearchNote,
      displayName: '提交研究笔记',
      description:
          '提交结构化 research note，保留来源、citation、usable facts 和 creative suggestions。',
      parametersSchema: _submitResearchNoteSchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.proposeKnowledgeCard,
      displayName: '提出知识卡',
      description: '提出项目知识卡提案，保持开放 payload，不把未知题材或文化类型写死成枚举。',
      parametersSchema: _proposeKnowledgeCardSchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.proposeDesignElement,
      displayName: '提出设计元素',
      description: '提出作品巧思、符号系统或结构设计提案，保持开放 payload 和 linked refs。',
      parametersSchema: _proposeDesignElementSchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.linkInformationEvidence,
      displayName: '链接信息证据',
      description:
          '在 knowledge/design/research/reference/claim 之间建立结构化链路，不直接解释正文语义。',
      parametersSchema: _linkInformationEvidenceSchema,
    ),
    NarrativeDomainToolDefinition(
      toolName: NarrativeDomainToolNames.proposeReferenceWork,
      displayName: '提出引用作品边界',
      description: '提出引用作品或来源作品边界记录，支持开放 relationship 字符串和风险备注。',
      parametersSchema: _proposeReferenceWorkSchema,
    ),
  ];

  List<JsonMap> buildOpenAiSchemas([List<String>? toolNames]) {
    final allowed = (toolNames == null || toolNames.isEmpty)
        ? NarrativeDomainToolNames.all.toSet()
        : toolNames.map((entry) => entry.trim()).toSet();
    return definitions
        .where((definition) => allowed.contains(definition.toolName))
        .map((definition) => definition.toOpenAiSchema())
        .toList(growable: false);
  }

  NarrativeDomainToolDefinition? definitionFor(String toolName) {
    final normalized = toolName.trim();
    for (final definition in definitions) {
      if (definition.toolName == normalized) {
        return definition;
      }
    }
    return null;
  }

  NarrativeDomainToolParseResult parseRequest({
    required String callId,
    required String toolName,
    required NarrativeSourceRef source,
    required JsonMap arguments,
    ToolRoundEvidence? toolRoundEvidence,
    String schemaVersion = '',
  }) {
    final issues = <NarrativeDomainToolParseIssue>[];
    final definition = definitionFor(toolName);
    if (definition == null) {
      issues.add(
        const NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.unknownToolName,
          fieldPath: 'tool_name',
          message: '未知领域工具名。',
        ),
      );
      return NarrativeDomainToolParseResult(toolName: toolName, issues: issues);
    }

    final normalizedPayload = _normalizedPayloadFor(
      toolName: definition.toolName,
      source: source,
      arguments: arguments,
      issues: issues,
    );
    if (issues.isNotEmpty || normalizedPayload == null) {
      return NarrativeDomainToolParseResult(
        toolName: definition.toolName,
        issues: issues,
      );
    }

    return NarrativeDomainToolParseResult(
      toolName: definition.toolName,
      request: DomainToolRequest(
        callId: callId,
        toolName: definition.toolName,
        source: source,
        requestPayload: normalizedPayload,
        toolRoundEvidence: toolRoundEvidence,
        schemaVersion: schemaVersion,
      ),
    );
  }

  JsonMap? _normalizedPayloadFor({
    required String toolName,
    required NarrativeSourceRef source,
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    switch (toolName) {
      case NarrativeDomainToolNames.submitChapterDelivery:
        return _parseSubmitChapterDelivery(
          source: source,
          arguments: arguments,
          issues: issues,
        );
      case NarrativeDomainToolNames.submitNarrativeStateClaims:
        return _parseSubmitNarrativeStateClaims(
          source: source,
          arguments: arguments,
          issues: issues,
        );
      case NarrativeDomainToolNames.proposeNarrativeProfileUpdate:
        return _parseProposeNarrativeProfileUpdate(
          source: source,
          arguments: arguments,
          issues: issues,
        );
      case NarrativeDomainToolNames.submitSemanticReview:
        return _parseSubmitSemanticReview(
          source: source,
          arguments: arguments,
          issues: issues,
        );
      case NarrativeDomainToolNames.proposeConstraintBinding:
        return _parseProposeConstraintBinding(
          source: source,
          arguments: arguments,
          issues: issues,
        );
      case NarrativeDomainToolNames.requestProfileClarification:
        return _parseRequestProfileClarification(
          arguments: arguments,
          issues: issues,
        );
      case NarrativeDomainToolNames.requestExternalResearch:
        return _parseRequestExternalResearch(
          arguments: arguments,
          issues: issues,
        );
      case NarrativeDomainToolNames.submitResearchNote:
        return _parseSubmitResearchNote(arguments: arguments, issues: issues);
      case NarrativeDomainToolNames.proposeKnowledgeCard:
        return _parseProposeKnowledgeCard(arguments: arguments, issues: issues);
      case NarrativeDomainToolNames.proposeDesignElement:
        return _parseProposeDesignElement(arguments: arguments, issues: issues);
      case NarrativeDomainToolNames.linkInformationEvidence:
        return _parseLinkInformationEvidence(
          arguments: arguments,
          issues: issues,
        );
      case NarrativeDomainToolNames.proposeReferenceWork:
        return _parseProposeReferenceWork(arguments: arguments, issues: issues);
    }
    return null;
  }

  JsonMap? _parseSubmitChapterDelivery({
    required NarrativeSourceRef source,
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final chapterPath = _requiredString(arguments, 'chapter_path', issues);
    final chapterContent = _requiredString(
      arguments,
      'chapter_content',
      issues,
    );
    if (chapterPath == null || chapterContent == null) {
      return null;
    }

    final topLevelClaims = _canonicalClaims(
      rawClaims: arguments['claims'],
      source: source,
      fieldPath: 'claims',
      issues: issues,
    );
    if (issues.isNotEmpty) {
      return null;
    }
    final submissionJson = _optionalMap(arguments, 'submission', issues);
    ChapterNarrativeSubmission? submission;
    if (submissionJson != null || topLevelClaims.isNotEmpty) {
      final chapterRef = <String, Object?>{
        'ref_type': NarrativeRefTypes.chapter,
        'ref_id': ValueReaders.stringValue(
          ValueReaders.mapValue(submissionJson)['chapter_id'],
          ValueReaders.stringValue(
            ValueReaders.mapValue(
              ValueReaders.mapValue(submissionJson)['chapter_ref'],
            )['ref_id'],
            chapterPath,
          ),
        ).trim(),
        'relative_path': chapterPath,
      };
      final canonicalSubmission = <String, Object?>{
        ...ValueReaders.mapValue(submissionJson),
        'submission_id': ValueReaders.stringValue(
          ValueReaders.mapValue(submissionJson)['submission_id'],
          'submission:$chapterPath',
        ),
        'chapter_ref': chapterRef,
        if (topLevelClaims.isNotEmpty)
          'claims': _claimCodecService.toJsonList(topLevelClaims),
      };
      submission = _submissionCodecService.fromJson(canonicalSubmission);
    }

    final metadata = _metadataWithUnknowns(
      arguments,
      knownFields: const <String>{
        'chapter_path',
        'chapter_content',
        'title',
        'claims',
        'submission',
        'constraint_coverage',
        'confidence',
        'metadata',
      },
    );
    return <String, Object?>{
      'chapter_path': chapterPath,
      'chapter_content': chapterContent,
      'title': ValueReaders.stringValue(arguments['title']).trim(),
      'submission': submission?.toJson() ?? <String, Object?>{},
      'constraint_coverage': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(arguments['constraint_coverage']),
      ),
      'confidence': _doubleValue(arguments['confidence']),
      'metadata': ValueReaders.deepCopyMap(<String, Object?>{
        ...metadata,
        if (submission != null &&
            _submissionValidator.validate(submission).isNotEmpty)
          'submission_validation_errors': _submissionValidator.validate(
            submission,
          ),
      }),
    };
  }

  JsonMap? _parseSubmitNarrativeStateClaims({
    required NarrativeSourceRef source,
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final sourceHint = ValueReaders.stringValue(arguments['source']).trim();
    final canonicalClaims = _canonicalClaims(
      rawClaims: arguments['claims'],
      source: source.copyWith(
        sourceType: sourceHint.isEmpty ? source.sourceType : sourceHint,
      ),
      fieldPath: 'claims',
      issues: issues,
    );
    if (issues.isNotEmpty) {
      return null;
    }
    final metadata = _metadataWithUnknowns(
      arguments,
      knownFields: const <String>{'source', 'claims', 'metadata'},
    );
    return <String, Object?>{
      'source': sourceHint,
      'claims': _claimCodecService.toJsonList(canonicalClaims),
      'metadata': metadata,
    };
  }

  List<NarrativeStateClaim> _canonicalClaims({
    required Object? rawClaims,
    required NarrativeSourceRef source,
    required String fieldPath,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    if (rawClaims == null) {
      return const <NarrativeStateClaim>[];
    }
    if (rawClaims is! List) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidArrayField,
          fieldPath: fieldPath,
          message: 'claims 必须是对象数组。',
        ),
      );
      return const <NarrativeStateClaim>[];
    }
    final canonicalClaims = <NarrativeStateClaim>[];
    for (var index = 0; index < rawClaims.length; index += 1) {
      final claimMap = ValueReaders.mapValue(rawClaims[index]);
      if (claimMap.isEmpty) {
        issues.add(
          NarrativeDomainToolParseIssue(
            code: NarrativeDomainToolValidationCodes.invalidObjectField,
            fieldPath: '$fieldPath[$index]',
            message: 'claim 必须是对象。',
          ),
        );
        continue;
      }
      final canonicalClaim = <String, Object?>{
        ...claimMap,
        'source': ValueReaders.mapValue(claimMap['source']).isNotEmpty
            ? ValueReaders.mapValue(claimMap['source'])
            : source.toJson(),
      };
      final claim = _claimCodecService.fromJson(canonicalClaim);
      final validationErrors = claim.validateBasics();
      if (validationErrors.isNotEmpty) {
        issues.add(
          NarrativeDomainToolParseIssue(
            code: NarrativeDomainToolValidationCodes.invalidNestedContract,
            fieldPath: '$fieldPath[$index]',
            message: validationErrors.join(', '),
          ),
        );
        continue;
      }
      canonicalClaims.add(claim);
    }
    return canonicalClaims;
  }

  JsonMap? _parseProposeNarrativeProfileUpdate({
    required NarrativeSourceRef source,
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final proposalId = _requiredString(arguments, 'proposal_id', issues);
    final profilePatch = _requiredMap(arguments, 'profile_patch', issues);
    if (proposalId == null || profilePatch == null) {
      return null;
    }
    final patchLabel = ValueReaders.stringValue(
      profilePatch['patch_label'],
      ValueReaders.stringValue(
        profilePatch['display_name'],
        ValueReaders.stringValue(profilePatch['label']),
      ),
    ).trim();
    final proposalJson = <String, Object?>{
      'proposal_id': proposalId,
      'proposal_status': 'proposed',
      'profile_patch': <String, Object?>{
        'patch_id': ValueReaders.stringValue(
          profilePatch['patch_id'],
          'patch:$proposalId',
        ),
        'patch_label': patchLabel,
        'patch_payload': ValueReaders.deepCopyMap(profilePatch),
        'patch_extensions': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(profilePatch['patch_extensions']),
        ),
        'source': source.toJson(),
      },
      'source': source.toJson(),
      'target_profile_id': ValueReaders.stringValue(
        arguments['target_profile_id'],
      ).trim(),
      'base_profile_id': ValueReaders.stringValue(
        arguments['base_profile_id'],
      ).trim(),
      'requires_user_confirmation': ValueReaders.boolValue(
        arguments['requires_user_confirmation'],
      ),
      'reason': ValueReaders.stringValue(arguments['reason']).trim(),
      'confidence': _doubleValue(arguments['confidence']),
      'schema_version': ValueReaders.stringValue(
        arguments['schema_version'],
      ).trim(),
      'metadata': _metadataWithUnknowns(
        arguments,
        knownFields: const <String>{
          'proposal_id',
          'reason',
          'profile_patch',
          'evidence_refs',
          'confidence',
          'uncertainty',
          'requires_user_confirmation',
          'target_profile_id',
          'base_profile_id',
          'schema_version',
          'metadata',
        },
      ),
    };
    final proposal = _profileCodecService.proposalFromJson(proposalJson);
    final validationErrors = _profileProposalValidator.validate(proposal);
    if (validationErrors.isNotEmpty) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidNestedContract,
          fieldPath: 'profile_patch',
          message: validationErrors.join(', '),
        ),
      );
      return null;
    }
    return <String, Object?>{
      ...proposal.toJson(),
      'evidence_refs': _canonicalEvidenceRefs(
        arguments['evidence_refs'],
        fieldPath: 'evidence_refs',
        issues: issues,
      ),
      'uncertainty': ValueReaders.stringValue(arguments['uncertainty']).trim(),
    };
  }

  JsonMap? _parseSubmitSemanticReview({
    required NarrativeSourceRef source,
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final reviewId = _requiredString(arguments, 'review_id', issues);
    if (reviewId == null) {
      return null;
    }
    final reviewJson = <String, Object?>{
      'review_id': reviewId,
      'source': source.toJson(),
      'recommended_disposition': ValueReaders.stringValue(
        arguments['recommended_disposition'],
      ).trim(),
      'target_refs': _canonicalRefs(
        arguments['target_refs'],
        fieldPath: 'target_refs',
        issues: issues,
      ),
      'accepted_claim_ids': ValueReaders.stringList(
        arguments['accepted_claim_ids'] ?? arguments['accepted_claims'],
      ),
      'questioned_claim_ids': ValueReaders.stringList(
        arguments['questioned_claim_ids'] ?? arguments['questioned_claims'],
      ),
      'suggested_claims': _canonicalClaimJsonList(
        arguments['suggested_claims'],
        fallbackSourceType: source.sourceType,
        fieldPath: 'suggested_claims',
        issues: issues,
      ),
      'findings': _canonicalFindings(
        arguments['findings'],
        fieldPath: 'findings',
        issues: issues,
      ),
      'summary': ValueReaders.stringValue(arguments['summary']).trim(),
      'confidence': _doubleValue(arguments['confidence']),
      'schema_version': ValueReaders.stringValue(
        arguments['schema_version'],
      ).trim(),
      'metadata': _metadataWithUnknowns(
        arguments,
        knownFields: const <String>{
          'review_id',
          'target_refs',
          'accepted_claim_ids',
          'accepted_claims',
          'questioned_claim_ids',
          'questioned_claims',
          'suggested_claims',
          'findings',
          'summary',
          'confidence',
          'recommended_disposition',
          'schema_version',
          'metadata',
        },
      ),
    };
    if (issues.isNotEmpty) {
      return null;
    }
    final review = _semanticReviewCodecService.fromJson(reviewJson);
    final validationErrors = review.validateBasics();
    if (validationErrors.isNotEmpty) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidNestedContract,
          fieldPath: 'review',
          message: validationErrors.join(', '),
        ),
      );
      return null;
    }
    return review.toJson();
  }

  JsonMap? _parseProposeConstraintBinding({
    required NarrativeSourceRef source,
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final bindingId = _requiredString(arguments, 'binding_id', issues);
    if (bindingId == null) {
      return null;
    }
    final scopeRef = ValueReaders.stringValue(arguments['scope_ref']).trim();
    final bindingScopeArg = arguments.containsKey('binding_scope')
        ? arguments['binding_scope']
        : arguments['scope'];
    final scopeJson = ValueReaders.mapValue(bindingScopeArg);
    final canonicalScope = scopeJson.isNotEmpty
        ? scopeJson
        : <String, Object?>{
            'applies_to': ValueReaders.objectList(arguments['applies_to']),
            'target_refs': scopeRef.isEmpty
                ? const <Object?>[]
                : <Object?>[
                    <String, Object?>{'ref_type': 'scope', 'ref_id': scopeRef},
                  ],
          };
    final bindingPolicyArg = arguments.containsKey('binding_policy')
        ? arguments['binding_policy']
        : <String, Object?>{
            'hard_execution_policy': arguments['hard_execution_policy'],
            'soft_review_policy': arguments['soft_review_policy'],
            'requires_user_confirmation':
                arguments['requires_user_confirmation'],
          };
    final canonicalPolicy = ValueReaders.mapValue(bindingPolicyArg);
    final constraintType = ValueReaders.stringValue(
      arguments['constraint_type'],
      ValueReaders.stringValue(arguments['constraint_ref']),
    ).trim();
    final proposalJson = <String, Object?>{
      'binding_id': bindingId,
      'constraint_type': constraintType,
      'constraint_id': ValueReaders.stringValue(
        arguments['constraint_id'],
        ValueReaders.stringValue(arguments['constraint_ref']),
      ).trim(),
      'constraint_label': ValueReaders.stringValue(
        arguments['constraint_label'],
      ).trim(),
      'constraint_origin': ValueReaders.stringValue(
        arguments['constraint_origin'],
      ).trim(),
      'constraint_payload': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(arguments['constraint_payload']),
      ),
      'binding_scope': canonicalScope,
      'binding_policy': canonicalPolicy,
      'source': source.toJson(),
      'reason': ValueReaders.stringValue(arguments['reason']).trim(),
      'confidence': _doubleValue(arguments['confidence']),
      'schema_version': ValueReaders.stringValue(
        arguments['schema_version'],
      ).trim(),
      'metadata': _metadataWithUnknowns(
        arguments,
        knownFields: const <String>{
          'binding_id',
          'constraint_type',
          'constraint_ref',
          'constraint_id',
          'constraint_label',
          'constraint_origin',
          'constraint_payload',
          'scope_ref',
          'applies_to',
          'binding_scope',
          'scope',
          'binding_policy',
          'hard_execution_policy',
          'soft_review_policy',
          'requires_user_confirmation',
          'reason',
          'confidence',
          'schema_version',
          'metadata',
        },
      ),
    };
    final proposal = _constraintBindingCodecService.proposalFromJson(
      proposalJson,
    );
    final validationErrors = proposal.validateBasics();
    if (validationErrors.isNotEmpty) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidNestedContract,
          fieldPath: 'constraint_binding',
          message: validationErrors.join(', '),
        ),
      );
      return null;
    }
    return proposal.toJson();
  }

  JsonMap? _parseRequestProfileClarification({
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final question = _requiredString(arguments, 'question', issues);
    final rawOptions = arguments['options'];
    if (rawOptions is! List) {
      issues.add(
        const NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidArrayField,
          fieldPath: 'options',
          message: 'options 必须是对象数组。',
        ),
      );
      return null;
    }
    final canonicalOptions = <JsonMap>[];
    for (var index = 0; index < rawOptions.length; index += 1) {
      final option = ValueReaders.mapValue(rawOptions[index]);
      if (option.isEmpty) {
        issues.add(
          NarrativeDomainToolParseIssue(
            code: NarrativeDomainToolValidationCodes.invalidObjectField,
            fieldPath: 'options[$index]',
            message: 'option 必须是对象。',
          ),
        );
        continue;
      }
      final label = ValueReaders.stringValue(
        option['label'],
        ValueReaders.stringValue(option['title']),
      ).trim();
      if (label.isEmpty) {
        issues.add(
          NarrativeDomainToolParseIssue(
            code: NarrativeDomainToolValidationCodes.missingRequiredField,
            fieldPath: 'options[$index].label',
            message: '澄清选项至少要有 label/title。',
          ),
        );
        continue;
      }
      canonicalOptions.add(
        ValueReaders.deepCopyMap(<String, Object?>{...option, 'label': label}),
      );
    }
    if (question == null || issues.isNotEmpty) {
      return null;
    }
    return <String, Object?>{
      'question': question,
      'options': canonicalOptions,
      'freeform_allowed': ValueReaders.boolValue(arguments['freeform_allowed']),
      'reason': ValueReaders.stringValue(arguments['reason']).trim(),
      'blocking': ValueReaders.boolValue(arguments['blocking'], true),
      'metadata': _metadataWithUnknowns(
        arguments,
        knownFields: const <String>{
          'question',
          'options',
          'freeform_allowed',
          'reason',
          'blocking',
          'metadata',
        },
      ),
    };
  }

  JsonMap? _parseRequestExternalResearch({
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final query = _requiredString(arguments, 'query', issues);
    if (query == null) {
      return null;
    }
    final metadata = _metadataWithUnknowns(
      arguments,
      knownFields: const <String>{
        'query',
        'purpose',
        'requested_depth',
        'reference_relationship',
        'collection_mode',
        'information_domain',
        'target_refs',
        'user_granted_network_access',
        'source_requirements',
        'extraction_policy',
        'metadata',
      },
    );
    return <String, Object?>{
      'query': query,
      'purpose': ValueReaders.stringValue(arguments['purpose']).trim(),
      'requested_depth': ValueReaders.stringValue(
        arguments['requested_depth'],
      ).trim(),
      'reference_relationship': ValueReaders.stringValue(
        arguments['reference_relationship'],
      ).trim(),
      'collection_mode': ValueReaders.stringValue(
        arguments['collection_mode'],
      ).trim(),
      'information_domain': ValueReaders.stringValue(
        arguments['information_domain'],
      ).trim(),
      'target_refs': _canonicalRefs(
        arguments['target_refs'],
        fieldPath: 'target_refs',
        issues: issues,
      ),
      'user_granted_network_access': ValueReaders.boolValue(
        arguments['user_granted_network_access'],
      ),
      'source_requirements': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(arguments['source_requirements']),
      ),
      'extraction_policy': ValueReaders.deepCopyMap(
        ValueReaders.mapValue(arguments['extraction_policy']),
      ),
      'metadata': metadata,
    };
  }

  JsonMap? _parseSubmitResearchNote({
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final note = ResearchNote.fromJson(arguments);
    final validationErrors = note.validateBasics();
    if (validationErrors.isNotEmpty) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidNestedContract,
          fieldPath: 'research_note',
          message: validationErrors.join(', '),
        ),
      );
      return null;
    }
    return note.toJson();
  }

  JsonMap? _parseProposeKnowledgeCard({
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final normalized = <String, Object?>{
      ...arguments,
      'lifecycle_status': ValueReaders.stringValue(
        arguments['lifecycle_status'],
        InformationLifecycleStatuses.proposed,
      ).trim(),
    };
    final card = ProjectKnowledgeCard.fromJson(normalized);
    final validationErrors = card.validateBasics();
    if (validationErrors.isNotEmpty) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidNestedContract,
          fieldPath: 'knowledge_card',
          message: validationErrors.join(', '),
        ),
      );
      return null;
    }
    return card.toJson();
  }

  JsonMap? _parseProposeDesignElement({
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final normalized = <String, Object?>{
      ...arguments,
      'lifecycle_status': ValueReaders.stringValue(
        arguments['lifecycle_status'],
        InformationLifecycleStatuses.proposed,
      ).trim(),
    };
    final card = DesignElementCard.fromJson(normalized);
    final validationErrors = card.validateBasics();
    if (validationErrors.isNotEmpty) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidNestedContract,
          fieldPath: 'design_element',
          message: validationErrors.join(', '),
        ),
      );
      return null;
    }
    return card.toJson();
  }

  JsonMap? _parseLinkInformationEvidence({
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final link = InformationLink.fromJson(arguments);
    final validationErrors = link.validateBasics();
    if (validationErrors.isNotEmpty) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidNestedContract,
          fieldPath: 'information_link',
          message: validationErrors.join(', '),
        ),
      );
      return null;
    }
    return link.toJson();
  }

  JsonMap? _parseProposeReferenceWork({
    required JsonMap arguments,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final record = ReferenceWorkRecord.fromJson(arguments);
    final validationErrors = record.validateBasics();
    if (validationErrors.isNotEmpty) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidNestedContract,
          fieldPath: 'reference_work',
          message: validationErrors.join(', '),
        ),
      );
      return null;
    }
    return record.toJson();
  }

  List<JsonMap> _canonicalClaimJsonList(
    Object? rawClaims, {
    required String fallbackSourceType,
    required String fieldPath,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final result = <JsonMap>[];
    for (
      var index = 0;
      index < ValueReaders.objectList(rawClaims).length;
      index += 1
    ) {
      final claimMap = ValueReaders.mapValue(
        ValueReaders.objectList(rawClaims)[index],
      );
      if (claimMap.isEmpty) {
        issues.add(
          NarrativeDomainToolParseIssue(
            code: NarrativeDomainToolValidationCodes.invalidObjectField,
            fieldPath: '$fieldPath[$index]',
            message: 'claim 必须是对象。',
          ),
        );
        continue;
      }
      final canonicalClaim = <String, Object?>{
        ...claimMap,
        'claim_id': ValueReaders.stringValue(
          claimMap['claim_id'],
          ValueReaders.stringValue(claimMap['id']),
        ).trim(),
        'claim_namespace': ValueReaders.stringValue(
          claimMap['claim_namespace'],
          ValueReaders.stringValue(claimMap['namespace']),
        ).trim(),
        'claim_label': ValueReaders.stringValue(
          claimMap['claim_label'],
          ValueReaders.stringValue(
            claimMap['label'],
            ValueReaders.stringValue(claimMap['title']),
          ),
        ).trim(),
        'claim_payload': ValueReaders.mapValue(
          claimMap['claim_payload'].runtimeType == Null
              ? claimMap['payload']
              : claimMap['claim_payload'],
        ),
        'source': ValueReaders.mapValue(claimMap['source']).isNotEmpty
            ? ValueReaders.mapValue(claimMap['source'])
            : <String, Object?>{'source_type': fallbackSourceType},
      };
      final claim = _claimCodecService.fromJson(canonicalClaim);
      final validationErrors = claim.validateBasics();
      if (validationErrors.isNotEmpty) {
        issues.add(
          NarrativeDomainToolParseIssue(
            code: NarrativeDomainToolValidationCodes.invalidNestedContract,
            fieldPath: '$fieldPath[$index]',
            message: validationErrors.join(', '),
          ),
        );
        continue;
      }
      result.add(claim.toJson());
    }
    return result;
  }

  List<JsonMap> _canonicalFindings(
    Object? rawFindings, {
    required String fieldPath,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final result = <JsonMap>[];
    final findings = ValueReaders.objectList(rawFindings);
    for (var index = 0; index < findings.length; index += 1) {
      final finding = ValueReaders.mapValue(findings[index]);
      if (finding.isEmpty) {
        issues.add(
          NarrativeDomainToolParseIssue(
            code: NarrativeDomainToolValidationCodes.invalidObjectField,
            fieldPath: '$fieldPath[$index]',
            message: 'finding 必须是对象。',
          ),
        );
        continue;
      }
      final evidenceOrReason = ValueReaders.stringValue(
        finding['evidence_or_unlocatable_reason'],
        ValueReaders.stringValue(
          finding['evidence'],
          ValueReaders.stringValue(finding['detail']),
        ),
      ).trim();
      final explicitReason = ValueReaders.stringValue(
        finding['unlocatable_reason'],
      ).trim();
      final canonicalFinding = <String, Object?>{
        ...finding,
        'finding_id': ValueReaders.stringValue(
          finding['finding_id'],
          ValueReaders.stringValue(finding['id']),
        ).trim(),
        'summary': ValueReaders.stringValue(
          finding['summary'],
          ValueReaders.stringValue(finding['title']),
        ).trim(),
        'suggested_action': ValueReaders.stringValue(
          finding['suggested_action'],
          ValueReaders.stringValue(
            finding['suggestedAction'],
            ValueReaders.stringValue(finding['action']),
          ),
        ).trim(),
        'unable_to_locate_evidence':
            ValueReaders.boolValue(finding['unable_to_locate_evidence']) ||
            explicitReason.isNotEmpty ||
            (ValueReaders.mapList(finding['evidence_refs']).isEmpty &&
                evidenceOrReason.isNotEmpty),
        'unlocatable_reason': explicitReason.isNotEmpty
            ? explicitReason
            : (ValueReaders.mapList(finding['evidence_refs']).isEmpty
                  ? evidenceOrReason
                  : ''),
      };
      result.add(canonicalFinding);
    }
    return result;
  }

  List<JsonMap> _canonicalEvidenceRefs(
    Object? rawRefs, {
    required String fieldPath,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final result = <JsonMap>[];
    final refs = ValueReaders.objectList(rawRefs);
    for (var index = 0; index < refs.length; index += 1) {
      final refMap = ValueReaders.mapValue(refs[index]);
      if (refMap.isEmpty) {
        issues.add(
          NarrativeDomainToolParseIssue(
            code: NarrativeDomainToolValidationCodes.invalidObjectField,
            fieldPath: '$fieldPath[$index]',
            message: 'evidence ref 必须是对象。',
          ),
        );
        continue;
      }
      result.add(NarrativeEvidenceRef.fromJson(refMap).toJson());
    }
    return result;
  }

  List<JsonMap> _canonicalRefs(
    Object? rawRefs, {
    required String fieldPath,
    required List<NarrativeDomainToolParseIssue> issues,
  }) {
    final result = <JsonMap>[];
    final refs = ValueReaders.objectList(rawRefs);
    for (var index = 0; index < refs.length; index += 1) {
      final refMap = ValueReaders.mapValue(refs[index]);
      if (refMap.isEmpty) {
        issues.add(
          NarrativeDomainToolParseIssue(
            code: NarrativeDomainToolValidationCodes.invalidObjectField,
            fieldPath: '$fieldPath[$index]',
            message: 'ref 必须是对象。',
          ),
        );
        continue;
      }
      result.add(NarrativeRef.fromJson(refMap).toJson());
    }
    return result;
  }

  String? _requiredString(
    JsonMap arguments,
    String key,
    List<NarrativeDomainToolParseIssue> issues,
  ) {
    if (!arguments.containsKey(key)) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.missingRequiredField,
          fieldPath: key,
          message: '$key 是必填字段。',
        ),
      );
      return null;
    }
    final rawValue = arguments[key];
    if (rawValue is! String) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.invalidStringField,
          fieldPath: key,
          message: '$key 必须是字符串。',
        ),
      );
      return null;
    }
    return rawValue.trim();
  }

  JsonMap? _requiredMap(
    JsonMap arguments,
    String key,
    List<NarrativeDomainToolParseIssue> issues,
  ) {
    if (!arguments.containsKey(key)) {
      issues.add(
        NarrativeDomainToolParseIssue(
          code: NarrativeDomainToolValidationCodes.missingRequiredField,
          fieldPath: key,
          message: '$key 是必填字段。',
        ),
      );
      return null;
    }
    final value = arguments[key];
    if (value is Map<String, Object?>) {
      return ValueReaders.deepCopyMap(value);
    }
    if (value is Map) {
      return ValueReaders.deepCopyMap(ValueReaders.mapValue(value));
    }
    issues.add(
      NarrativeDomainToolParseIssue(
        code: NarrativeDomainToolValidationCodes.invalidObjectField,
        fieldPath: key,
        message: '$key 必须是对象。',
      ),
    );
    return null;
  }

  JsonMap? _optionalMap(
    JsonMap arguments,
    String key,
    List<NarrativeDomainToolParseIssue> issues,
  ) {
    if (!arguments.containsKey(key) || arguments[key] == null) {
      return null;
    }
    return _requiredMap(arguments, key, issues);
  }

  double _doubleValue(Object? value) {
    return ValueReaders.doubleValue(value);
  }

  JsonMap _metadataWithUnknowns(
    JsonMap json, {
    required Set<String> knownFields,
  }) {
    return _codecService.readMetadataWithUnknownFields(
      json,
      knownFields: knownFields,
    );
  }

  static const JsonMap _submitChapterDeliverySchema = <String, Object?>{
    'type': 'object',
    'required': <String>['chapter_path', 'chapter_content'],
    'properties': <String, Object?>{
      'chapter_path': <String, Object?>{'type': 'string'},
      'chapter_content': <String, Object?>{
        'type': 'string',
        'description':
            '正式章节正文。连续章节第一段应直接承接上一章已落定状态，先推进新的回应、动作或结果，不要把上一章末尾已发生的寻路、敲门、到达、开门或发问整段倒带重演。',
      },
      'title': <String, Object?>{'type': 'string'},
      'claims': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'submission': <String, Object?>{
        'type': 'object',
        'description':
            '结构化章节 sidecar。连续章节至少应填写 summary，并在 final_state_summary 中写明章末位置、即时目标/动作、未完成悬念和下一章入口；不要提交空壳 submission。',
        'additionalProperties': true,
      },
      'constraint_coverage': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'confidence': <String, Object?>{'type': 'number'},
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _submitNarrativeStateClaimsSchema = <String, Object?>{
    'type': 'object',
    'required': <String>['claims'],
    'properties': <String, Object?>{
      'source': <String, Object?>{'type': 'string'},
      'claims': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _proposeNarrativeProfileUpdateSchema = <String, Object?>{
    'type': 'object',
    'required': <String>['proposal_id', 'profile_patch'],
    'properties': <String, Object?>{
      'proposal_id': <String, Object?>{'type': 'string'},
      'reason': <String, Object?>{'type': 'string'},
      'profile_patch': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'evidence_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'confidence': <String, Object?>{'type': 'number'},
      'uncertainty': <String, Object?>{'type': 'string'},
      'requires_user_confirmation': <String, Object?>{'type': 'boolean'},
      'target_profile_id': <String, Object?>{'type': 'string'},
      'base_profile_id': <String, Object?>{'type': 'string'},
      'schema_version': <String, Object?>{'type': 'string'},
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _submitSemanticReviewSchema = <String, Object?>{
    'type': 'object',
    'required': <String>['review_id', 'findings', 'recommended_disposition'],
    'properties': <String, Object?>{
      'review_id': <String, Object?>{'type': 'string'},
      'target_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'accepted_claim_ids': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{'type': 'string'},
      },
      'accepted_claims': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{'type': 'string'},
      },
      'questioned_claim_ids': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{'type': 'string'},
      },
      'questioned_claims': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{'type': 'string'},
      },
      'suggested_claims': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'findings': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'summary': <String, Object?>{'type': 'string'},
      'confidence': <String, Object?>{'type': 'number'},
      'recommended_disposition': <String, Object?>{'type': 'string'},
      'schema_version': <String, Object?>{'type': 'string'},
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _proposeConstraintBindingSchema = <String, Object?>{
    'type': 'object',
    'required': <String>['binding_id'],
    'properties': <String, Object?>{
      'binding_id': <String, Object?>{'type': 'string'},
      'constraint_type': <String, Object?>{'type': 'string'},
      'constraint_ref': <String, Object?>{'type': 'string'},
      'constraint_id': <String, Object?>{'type': 'string'},
      'constraint_label': <String, Object?>{'type': 'string'},
      'constraint_origin': <String, Object?>{'type': 'string'},
      'constraint_payload': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'scope_ref': <String, Object?>{'type': 'string'},
      'applies_to': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{'type': 'string'},
      },
      'binding_scope': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'scope': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'binding_policy': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'hard_execution_policy': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'soft_review_policy': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'requires_user_confirmation': <String, Object?>{'type': 'boolean'},
      'reason': <String, Object?>{'type': 'string'},
      'confidence': <String, Object?>{'type': 'number'},
      'schema_version': <String, Object?>{'type': 'string'},
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _requestProfileClarificationSchema = <String, Object?>{
    'type': 'object',
    'required': <String>['question', 'options'],
    'properties': <String, Object?>{
      'question': <String, Object?>{'type': 'string'},
      'options': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'freeform_allowed': <String, Object?>{'type': 'boolean'},
      'reason': <String, Object?>{'type': 'string'},
      'blocking': <String, Object?>{'type': 'boolean'},
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _requestExternalResearchSchema = <String, Object?>{
    'type': 'object',
    'required': <String>['query'],
    'properties': <String, Object?>{
      'query': <String, Object?>{'type': 'string'},
      'purpose': <String, Object?>{'type': 'string'},
      'requested_depth': <String, Object?>{'type': 'string'},
      'reference_relationship': <String, Object?>{'type': 'string'},
      'collection_mode': <String, Object?>{'type': 'string'},
      'information_domain': <String, Object?>{'type': 'string'},
      'target_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'user_granted_network_access': <String, Object?>{'type': 'boolean'},
      'source_requirements': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'extraction_policy': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _submitResearchNoteSchema = <String, Object?>{
    'type': 'object',
    'required': <String>[
      'research_id',
      'query',
      'source_kind',
      'source_url_or_ref',
      'citation',
      'summary',
      'created_by',
      'usage_policy',
    ],
    'properties': <String, Object?>{
      'research_id': <String, Object?>{'type': 'string'},
      'query': <String, Object?>{'type': 'string'},
      'source_kind': <String, Object?>{'type': 'string'},
      'source_url_or_ref': <String, Object?>{'type': 'string'},
      'citation': <String, Object?>{'type': 'string'},
      'summary': <String, Object?>{'type': 'string'},
      'usable_facts': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{},
      },
      'creative_suggestions': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{},
      },
      'uncertainty': <String, Object?>{'type': 'string'},
      'license_or_usage_note': <String, Object?>{'type': 'string'},
      'created_by': <String, Object?>{'type': 'string'},
      'linked_cards': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'usage_policy': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'schema_version': <String, Object?>{'type': 'string'},
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _proposeKnowledgeCardSchema = <String, Object?>{
    'type': 'object',
    'required': <String>[
      'card_id',
      'card_namespace',
      'card_type',
      'title',
      'content_payload',
      'source_refs',
      'activation_policy',
      'usage_policy',
    ],
    'properties': <String, Object?>{
      'card_id': <String, Object?>{'type': 'string'},
      'card_namespace': <String, Object?>{'type': 'string'},
      'card_type': <String, Object?>{'type': 'string'},
      'title': <String, Object?>{'type': 'string'},
      'summary': <String, Object?>{'type': 'string'},
      'content_payload': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'source_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'evidence_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'scope_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'activation_policy': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'usage_policy': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'confidence': <String, Object?>{'type': 'number'},
      'lifecycle_status': <String, Object?>{'type': 'string'},
      'schema_version': <String, Object?>{'type': 'string'},
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _proposeDesignElementSchema = <String, Object?>{
    'type': 'object',
    'required': <String>[
      'design_id',
      'design_namespace',
      'design_label',
      'design_payload',
      'source_refs',
      'activation_policy',
      'usage_policy',
    ],
    'properties': <String, Object?>{
      'design_id': <String, Object?>{'type': 'string'},
      'design_namespace': <String, Object?>{'type': 'string'},
      'design_label': <String, Object?>{'type': 'string'},
      'design_payload': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'source_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'evidence_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'scope_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'linked_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'activation_policy': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'usage_policy': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'confidence': <String, Object?>{'type': 'number'},
      'uncertainty': <String, Object?>{'type': 'string'},
      'lifecycle_status': <String, Object?>{'type': 'string'},
      'schema_version': <String, Object?>{'type': 'string'},
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _linkInformationEvidenceSchema = <String, Object?>{
    'type': 'object',
    'required': <String>['link_id', 'link_type', 'source_ref', 'target_ref'],
    'properties': <String, Object?>{
      'link_id': <String, Object?>{'type': 'string'},
      'link_type': <String, Object?>{'type': 'string'},
      'source_ref': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'target_ref': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
      'summary': <String, Object?>{'type': 'string'},
      'created_by': <String, Object?>{'type': 'string'},
      'schema_version': <String, Object?>{'type': 'string'},
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };

  static const JsonMap _proposeReferenceWorkSchema = <String, Object?>{
    'type': 'object',
    'required': <String>[
      'reference_work_id',
      'title',
      'source_refs',
      'relationship_to_project',
      'declared_usage_intent',
    ],
    'properties': <String, Object?>{
      'reference_work_id': <String, Object?>{'type': 'string'},
      'title': <String, Object?>{'type': 'string'},
      'creator': <String, Object?>{'type': 'string'},
      'version': <String, Object?>{'type': 'string'},
      'source_refs': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{
          'type': 'object',
          'additionalProperties': true,
        },
      },
      'relationship_to_project': <String, Object?>{'type': 'string'},
      'declared_usage_intent': <String, Object?>{'type': 'string'},
      'allowed_usage_summary': <String, Object?>{'type': 'string'},
      'risk_notes': <String, Object?>{
        'type': 'array',
        'items': <String, Object?>{},
      },
      'requires_confirmation': <String, Object?>{'type': 'boolean'},
      'schema_version': <String, Object?>{'type': 'string'},
      'metadata': <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
      },
    },
    'additionalProperties': true,
  };
}
