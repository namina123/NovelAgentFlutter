import 'dart:convert';

import '../../packages/frontmatter_yaml_writer_service.dart';
import 'narrative_constraint_binding_proposal.dart';
import 'narrative_profile.dart';
import 'narrative_semantic_review.dart';
import 'narrative_state_claim.dart';
import 'narrative_state_ledger.dart';
import 'narrative_state_projection_document.dart';
import 'narrative_state_projection_source.dart';

class NarrativeStateMarkdownProjectionService {
  NarrativeStateMarkdownProjectionService({
    FrontmatterYamlWriterService? yamlWriterService,
  }) : _yamlWriterService =
           yamlWriterService ?? const FrontmatterYamlWriterService();

  static const String profileReferenceBlockId = 'narrative_profile_references';
  static const String profileProposalDraftBlockId =
      'narrative_profile_proposal_drafts';
  static const String claimReferenceBlockId =
      'narrative_state_claim_references';
  static const String ledgerReferenceBlockId =
      'narrative_state_ledger_references';
  static const String claimDraftBlockId = 'narrative_state_claim_drafts';
  static const String bindingReferenceBlockId =
      'narrative_constraint_binding_references';
  static const String bindingDraftBlockId =
      'narrative_constraint_binding_drafts';
  static const String semanticReviewReferenceBlockId =
      'narrative_semantic_review_references';
  static const String semanticReviewDraftBlockId =
      'narrative_semantic_review_drafts';

  final FrontmatterYamlWriterService _yamlWriterService;

  List<NarrativeStateProjectionDocument> buildDocuments(
    NarrativeStateProjectionSource source,
  ) {
    return <NarrativeStateProjectionDocument>[
      _buildRulesDocument(source),
      _buildRecentChangesDocument(source),
      _buildConstraintSummaryDocument(source),
      _buildSemanticReviewSummaryDocument(source),
    ];
  }

  NarrativeStateProjectionDocument _buildRulesDocument(
    NarrativeStateProjectionSource source,
  ) {
    final profiles = [...source.profiles]..sort(_compareProfiles);
    final lines = <String>[
      _frontmatter(
        projectionId: NarrativeStateProjectionDocument.rulesProjectionId,
        title: '叙事状态规则',
        sourceOfTruthPaths: <String>['.novel_agent/continuity/profiles/*.json'],
        editableDraftBlocks: <String>[profileProposalDraftBlockId],
      ),
      '# 叙事状态规则',
      '',
      '> 这份 Markdown 只是结构化事实源的可读投影，不是运行时真相。',
      '> 编辑后只能通过文末 draft block 生成 proposal draft，不能直接覆盖 JSON / JSONL。',
      '',
      '## 当前规则概览',
      '',
      '- 当前 profile 数：${profiles.length}',
      '- 事实源位置：`.novel_agent/continuity/profiles/*.json`',
      '- 删除这份投影不会删除底层事实源。',
      '',
      '## 当前规则明细',
      '',
    ];
    if (profiles.isEmpty) {
      lines.add('- 暂无已记录 profile。');
    } else {
      for (final profile in profiles) {
        lines.addAll(_profileSummary(profile));
      }
    }
    lines
      ..add('')
      ..add('## 结构化参考快照（只读参考）')
      ..add('')
      ..add(
        _jsonBlock(
          profileReferenceBlockId,
          profiles.map((item) => item.toJson()).toList(growable: false),
        ),
      )
      ..add('')
      ..add('## 可编辑 Proposal Draft')
      ..add('')
      ..add(_jsonBlock(profileProposalDraftBlockId, const <Object?>[]));
    return NarrativeStateProjectionDocument(
      projectionId: NarrativeStateProjectionDocument.rulesProjectionId,
      relativePath: NarrativeStateProjectionDocument.rulesRelativePath,
      title: '叙事状态规则',
      markdown: lines.join('\n').trimRight() + '\n',
    );
  }

  NarrativeStateProjectionDocument _buildRecentChangesDocument(
    NarrativeStateProjectionSource source,
  ) {
    final claims = [...source.claims]..sort(_compareClaims);
    final ledgers = [...source.ledgers]
      ..sort((left, right) => left.ledgerId.compareTo(right.ledgerId));
    final lines = <String>[
      _frontmatter(
        projectionId:
            NarrativeStateProjectionDocument.recentChangesProjectionId,
        title: '最近状态变化',
        sourceOfTruthPaths: <String>[
          '.novel_agent/continuity/claims/claims.jsonl',
          '.novel_agent/continuity/ledgers/*/entries.jsonl',
          '.novel_agent/continuity/ledgers/*/events.jsonl',
        ],
        editableDraftBlocks: <String>[claimDraftBlockId],
      ),
      '# 最近状态变化',
      '',
      '> 这份文档汇总最近可见的 claims 与 ledger 变化，便于人类和智能体快速浏览。',
      '> 如需人工修订，请在文末 claim draft block 中提交结构化草案。',
      '',
      '## 当前变化概览',
      '',
      '- 当前 claim 数：${claims.length}',
      '- 当前 ledger 数：${ledgers.length}',
      '- 删除这份投影不会删除底层 JSONL 审计流。',
      '',
      '## Claims 摘要',
      '',
    ];
    if (claims.isEmpty) {
      lines.add('- 暂无 claims。');
    } else {
      for (final claim in claims) {
        lines.addAll(_claimSummary(claim));
      }
    }
    lines
      ..add('')
      ..add('## Ledger 摘要')
      ..add('');
    if (ledgers.isEmpty) {
      lines.add('- 暂无 ledger。');
    } else {
      for (final ledger in ledgers) {
        lines.addAll(_ledgerSummary(ledger));
      }
    }
    lines
      ..add('')
      ..add('## 结构化参考快照（Claims）')
      ..add('')
      ..add(
        _jsonBlock(
          claimReferenceBlockId,
          claims.map((item) => item.toJson()).toList(growable: false),
        ),
      )
      ..add('')
      ..add('## 结构化参考快照（Ledger）')
      ..add('')
      ..add(
        _jsonBlock(
          ledgerReferenceBlockId,
          ledgers.map((item) => item.toJson()).toList(growable: false),
        ),
      )
      ..add('')
      ..add('## 可编辑 Claim Draft')
      ..add('')
      ..add(_jsonBlock(claimDraftBlockId, const <Object?>[]));
    return NarrativeStateProjectionDocument(
      projectionId: NarrativeStateProjectionDocument.recentChangesProjectionId,
      relativePath: NarrativeStateProjectionDocument.recentChangesRelativePath,
      title: '最近状态变化',
      markdown: lines.join('\n').trimRight() + '\n',
    );
  }

  NarrativeStateProjectionDocument _buildConstraintSummaryDocument(
    NarrativeStateProjectionSource source,
  ) {
    final bindings = [...source.bindings]..sort(_compareBindings);
    final lines = <String>[
      _frontmatter(
        projectionId:
            NarrativeStateProjectionDocument.constraintSummaryProjectionId,
        title: '项目约束摘要',
        sourceOfTruthPaths: <String>['.novel_agent/continuity/bindings/*.json'],
        editableDraftBlocks: <String>[bindingDraftBlockId],
      ),
      '# 项目约束摘要',
      '',
      '> 这份文档只投影当前已记录的约束绑定，不会替代底层结构化事实源。',
      '> Markdown 编辑必须回到 binding draft，不能直接改写运行时约束。',
      '',
      '## 当前约束概览',
      '',
      '- 当前 binding 数：${bindings.length}',
      '- 事实源位置：`.novel_agent/continuity/bindings/*.json`',
      '',
      '## 当前约束明细',
      '',
    ];
    if (bindings.isEmpty) {
      lines.add('- 暂无 bindings。');
    } else {
      for (final binding in bindings) {
        lines.addAll(_bindingSummary(binding));
      }
    }
    lines
      ..add('')
      ..add('## 结构化参考快照（只读参考）')
      ..add('')
      ..add(
        _jsonBlock(
          bindingReferenceBlockId,
          bindings.map((item) => item.toJson()).toList(growable: false),
        ),
      )
      ..add('')
      ..add('## 可编辑 Binding Draft')
      ..add('')
      ..add(_jsonBlock(bindingDraftBlockId, const <Object?>[]));
    return NarrativeStateProjectionDocument(
      projectionId:
          NarrativeStateProjectionDocument.constraintSummaryProjectionId,
      relativePath:
          NarrativeStateProjectionDocument.constraintSummaryRelativePath,
      title: '项目约束摘要',
      markdown: lines.join('\n').trimRight() + '\n',
    );
  }

  NarrativeStateProjectionDocument _buildSemanticReviewSummaryDocument(
    NarrativeStateProjectionSource source,
  ) {
    final reviews = [...source.reviews]
      ..sort((left, right) => left.reviewId.compareTo(right.reviewId));
    final lines = <String>[
      _frontmatter(
        projectionId:
            NarrativeStateProjectionDocument.semanticReviewSummaryProjectionId,
        title: '语义复核摘要',
        sourceOfTruthPaths: <String>['.novel_agent/continuity/reviews/*.json'],
        editableDraftBlocks: <String>[semanticReviewDraftBlockId],
      ),
      '# 语义复核摘要',
      '',
      '> 这份文档只投影当前 semantic review 记录，方便浏览与协作。',
      '> 若要人工修订，请在文末 semantic review draft block 中提交结构化草案。',
      '',
      '## 当前复核概览',
      '',
      '- 当前 review 数：${reviews.length}',
      '- 事实源位置：`.novel_agent/continuity/reviews/*.json`',
      '',
      '## 当前复核明细',
      '',
    ];
    if (reviews.isEmpty) {
      lines.add('- 暂无 semantic review。');
    } else {
      for (final review in reviews) {
        lines.addAll(_reviewSummary(review));
      }
    }
    lines
      ..add('')
      ..add('## 结构化参考快照（只读参考）')
      ..add('')
      ..add(
        _jsonBlock(
          semanticReviewReferenceBlockId,
          reviews.map((item) => item.toJson()).toList(growable: false),
        ),
      )
      ..add('')
      ..add('## 可编辑 Semantic Review Draft')
      ..add('')
      ..add(_jsonBlock(semanticReviewDraftBlockId, const <Object?>[]));
    return NarrativeStateProjectionDocument(
      projectionId:
          NarrativeStateProjectionDocument.semanticReviewSummaryProjectionId,
      relativePath:
          NarrativeStateProjectionDocument.semanticReviewSummaryRelativePath,
      title: '语义复核摘要',
      markdown: lines.join('\n').trimRight() + '\n',
    );
  }

  List<String> _profileSummary(NarrativeProfile profile) {
    return <String>[
      '### ${profile.profileLabel.trim().isEmpty ? profile.profileId : profile.profileLabel}',
      '',
      '- Profile ID：`${profile.profileId}`',
      '- Namespace：`${profile.profileNamespace}`',
      '- 生命周期：`${profile.lifecycleStatus.id}`',
      '- 置信度：${profile.confidence}',
      '- 来源：`${profile.source.sourceType}` / `${profile.source.sourceId}`',
      '- 原因：${profile.reason.trim().isEmpty ? '无' : profile.reason}',
      '- Payload：`${jsonEncode(profile.profilePayload)}`',
      '- Extensions：`${jsonEncode(profile.profileExtensions)}`',
      '',
    ];
  }

  List<String> _claimSummary(NarrativeStateClaim claim) {
    return <String>[
      '### ${claim.claimLabel.trim().isEmpty ? claim.claimId : claim.claimLabel}',
      '',
      '- Claim ID：`${claim.claimId}`',
      '- Namespace：`${claim.claimNamespace}`',
      '- 置信度：${claim.confidence}',
      '- Uncertainty：${claim.uncertainty.trim().isEmpty ? '无' : claim.uncertainty}',
      '- 来源：`${claim.source.sourceType}` / `${claim.source.sourceId}`',
      '- Payload：`${jsonEncode(claim.claimPayload)}`',
      '',
    ];
  }

  List<String> _ledgerSummary(NarrativeStateLedger ledger) {
    final lines = <String>[
      '### ${ledger.ledgerId}',
      '',
      '- Entry 数：${ledger.entries.length}',
      '- Event 数：${ledger.events.length}',
    ];
    if (ledger.entries.isNotEmpty) {
      for (final entry in ledger.entries.take(3)) {
        lines.add(
          '- Entry `${entry.entryId}`：`${entry.claim.claimId}` -> `${entry.disposition.id}`',
        );
      }
    }
    if (ledger.events.isNotEmpty) {
      for (final event in ledger.events.take(3)) {
        lines.add(
          '- Event `${event.eventId}`：`${event.eventType}` / `${event.disposition.id}`',
        );
      }
    }
    lines.add('');
    return lines;
  }

  List<String> _bindingSummary(NarrativeConstraintBindingProposal binding) {
    return <String>[
      '### ${binding.constraintLabel.trim().isEmpty ? binding.bindingId : binding.constraintLabel}',
      '',
      '- Binding ID：`${binding.bindingId}`',
      '- Constraint Type：`${binding.constraintType}`',
      '- Applies To：${binding.scope.appliesTo.isEmpty ? '无' : binding.scope.appliesTo.join('、')}',
      '- 需要用户确认：${binding.policy.requiresUserConfirmation}',
      '- 禁止自动应用：${binding.policy.forbiddenAutoApply}',
      '- Payload：`${jsonEncode(binding.constraintPayload)}`',
      '- 原因：${binding.reason.trim().isEmpty ? '无' : binding.reason}',
      '',
    ];
  }

  List<String> _reviewSummary(NarrativeSemanticReview review) {
    return <String>[
      '### ${review.reviewId}',
      '',
      '- 建议处置：`${review.recommendedDisposition.id}`',
      '- 置信度：${review.confidence}',
      '- 接受 claims：${review.acceptedClaimIds.length}',
      '- 质疑 claims：${review.questionedClaimIds.length}',
      '- findings：${review.findings.length}',
      '- 摘要：${review.summary.trim().isEmpty ? '无' : review.summary}',
      '',
    ];
  }

  String _frontmatter({
    required String projectionId,
    required String title,
    required List<String> sourceOfTruthPaths,
    required List<String> editableDraftBlocks,
  }) {
    return '---\n${_yamlWriterService.write(<String, Object?>{'projection_id': projectionId, 'title': title, 'projection_only': true, 'source_of_truth_paths': sourceOfTruthPaths, 'editable_draft_blocks': editableDraftBlocks})}\n---\n';
  }

  String _jsonBlock(String blockId, Object value) {
    return '```json $blockId\n${const JsonEncoder.withIndent('  ').convert(value)}\n```';
  }

  int _compareProfiles(NarrativeProfile left, NarrativeProfile right) {
    final namespaceCompare = left.profileNamespace.compareTo(
      right.profileNamespace,
    );
    if (namespaceCompare != 0) {
      return namespaceCompare;
    }
    return left.profileId.compareTo(right.profileId);
  }

  int _compareClaims(NarrativeStateClaim left, NarrativeStateClaim right) {
    final namespaceCompare = left.claimNamespace.compareTo(
      right.claimNamespace,
    );
    if (namespaceCompare != 0) {
      return namespaceCompare;
    }
    return left.claimId.compareTo(right.claimId);
  }

  int _compareBindings(
    NarrativeConstraintBindingProposal left,
    NarrativeConstraintBindingProposal right,
  ) {
    final typeCompare = left.constraintType.compareTo(right.constraintType);
    if (typeCompare != 0) {
      return typeCompare;
    }
    return left.bindingId.compareTo(right.bindingId);
  }
}
