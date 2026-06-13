import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import '../storage/open_narrative_state_path_service.dart';

class ProjectNarrativeClaimActivationContractService {
  ProjectNarrativeClaimActivationContractService({
    OpenNarrativeStatePathService? pathService,
  }) : _pathService = pathService ?? OpenNarrativeStatePathService();

  final OpenNarrativeStatePathService _pathService;

  List<ContextActivationItem> buildItems({
    required List<NarrativeStateClaim> claims,
    required List<NarrativeStateLedger> ledgers,
  }) {
    // 中文注释: continuity 激活候选必须优先消费 ledger-backed 状态真相，不能再把 raw claim log 直接当正式状态出口。
    final result = <ContextActivationItem>[];
    final trackedClaimIds = <String>{};
    final currentLedgerEntries = _currentLedgerEntries(ledgers);

    for (final entryView in currentLedgerEntries) {
      trackedClaimIds.add(entryView.entry.claim.claimId);
      final item = _itemFromLedgerEntry(entryView);
      if (item != null) {
        result.add(item);
      }
    }

    final sortedClaims = claims.toList(growable: false)
      ..sort(
        (left, right) =>
            left.claimNamespace.compareTo(right.claimNamespace) != 0
            ? left.claimNamespace.compareTo(right.claimNamespace)
            : left.claimId.compareTo(right.claimId),
      );
    for (final claim in sortedClaims) {
      if (trackedClaimIds.contains(claim.claimId)) {
        continue;
      }
      result.add(_rawSubmissionItem(claim));
    }

    return result;
  }

  List<_LedgerEntryView> _currentLedgerEntries(
    List<NarrativeStateLedger> ledgers,
  ) {
    final result = <_LedgerEntryView>[];
    for (final ledger in ledgers) {
      final latestByEntryId = <String, NarrativeLedgerEntry>{};
      for (final entry in ledger.entries) {
        latestByEntryId[entry.entryId] = entry;
      }
      for (final entry in latestByEntryId.values) {
        result.add(_LedgerEntryView(ledgerId: ledger.ledgerId, entry: entry));
      }
    }
    result.sort((left, right) {
      final namespaceCompare = left.entry.claim.claimNamespace.compareTo(
        right.entry.claim.claimNamespace,
      );
      if (namespaceCompare != 0) {
        return namespaceCompare;
      }
      final claimCompare = left.entry.claim.claimId.compareTo(
        right.entry.claim.claimId,
      );
      if (claimCompare != 0) {
        return claimCompare;
      }
      final dispositionCompare = _dispositionWeight(
        right.entry.disposition,
      ).compareTo(_dispositionWeight(left.entry.disposition));
      if (dispositionCompare != 0) {
        return dispositionCompare;
      }
      return left.entry.entryId.compareTo(right.entry.entryId);
    });
    return result;
  }

  ContextActivationItem? _itemFromLedgerEntry(_LedgerEntryView entryView) {
    // 中文注释: rejected / superseded 已退出当前 continuity 真相面，不再混入激活上下文。
    final disposition = entryView.entry.disposition;
    if (disposition == NarrativeClaimDisposition.rejected ||
        disposition == NarrativeClaimDisposition.superseded) {
      return null;
    }
    final formalTruth =
        disposition == NarrativeClaimDisposition.accepted ||
        disposition == NarrativeClaimDisposition.questioned;
    final claim = entryView.entry.claim;
    final label = claim.claimLabel.trim().isEmpty
        ? claim.claimId
        : claim.claimLabel.trim();
    final pinned = _boolFlags(claim.metadata['pinned'], claim.metadata['pin']);
    final required =
        _boolFlags(claim.metadata['required'], claim.metadata['is_required']) ||
        disposition == NarrativeClaimDisposition.questioned;
    final targetPath = _pathService.ledgerEntriesPath(entryView.ledgerId);
    final locator = '$targetPath#${entryView.entry.entryId}';
    final refs = _fallbackRefs(
      targetPath: targetPath,
      targetId: claim.claimId,
      title: label,
      refs: _dedupeRefs(<NarrativeRef>[
        ...claim.affectedRefs,
        ...claim.contextRefs,
      ]),
    );
    final evidenceRefs = entryView.entry.evidenceRefs.isNotEmpty
        ? entryView.entry.evidenceRefs
        : claim.evidenceRefs;
    final activationText = _ledgerClaimActivationText(
      entryView,
      formalTruth: formalTruth,
      locator: locator,
      evidenceRefs: evidenceRefs,
    );
    return ContextActivationItem(
      itemId: 'claim_entry:${entryView.entry.entryId}',
      source: formalTruth ? 'narrative_claim' : 'narrative_claim_submission',
      title: label,
      targetPath: targetPath,
      refs: refs,
      activationReasons: <String>[
        if (pinned) ContextActivationReasonCodes.manualPin,
        ContextActivationReasonCodes.claim,
      ],
      reasonDetails: <String, Object?>{
        'claim_id': claim.claimId,
        'claim_namespace': claim.claimNamespace,
        'ledger_id': entryView.ledgerId,
        'entry_id': entryView.entry.entryId,
        'claim_disposition': disposition.id,
        'required': required,
        'pinned': pinned,
        'priority_weight': formalTruth
            ? _formalLedgerPriorityWeight(disposition)
            : _pendingLedgerPriorityWeight(disposition),
      },
      requestedChars: activationText.length,
      metadata: <String, Object?>{
        'source_kind': formalTruth
            ? 'narrative_claim'
            : 'narrative_claim_submission',
        'truth_status': formalTruth ? 'formal_ledger' : 'pending_ledger',
        'claim_id': claim.claimId,
        'claim_namespace': claim.claimNamespace,
        'entry_id': entryView.entry.entryId,
        'ledger_id': entryView.ledgerId,
        'claim_disposition': disposition.id,
        'recorded_at': entryView.entry.recordedAt,
        'source_of_truth_locator': locator,
        'source_display': _sourceDisplay(entryView.entry.source),
        'source_refs': <JsonMap>[entryView.entry.source.toJson()],
        'evidence_refs': evidenceRefs
            .map((ref) => ref.toJson())
            .toList(growable: false),
        'required': required,
        'pinned': pinned,
        'priority_weight': formalTruth
            ? _formalLedgerPriorityWeight(disposition)
            : _pendingLedgerPriorityWeight(disposition),
        'activation_text': activationText,
      },
    );
  }

  ContextActivationItem _rawSubmissionItem(NarrativeStateClaim claim) {
    // 中文注释: 没进入 ledger 的 raw claim 只能作为待裁决提交流暴露，不能继续冒充正式 continuity truth。
    final label = claim.claimLabel.trim().isEmpty
        ? claim.claimId
        : claim.claimLabel.trim();
    final pinned = _boolFlags(claim.metadata['pinned'], claim.metadata['pin']);
    final required = _boolFlags(
      claim.metadata['required'],
      claim.metadata['is_required'],
    );
    final targetPath = _pathService.claimsLogPath();
    final locator = '$targetPath#${claim.claimId}';
    final refs = _fallbackRefs(
      targetPath: targetPath,
      targetId: claim.claimId,
      title: label,
      refs: _dedupeRefs(<NarrativeRef>[
        ...claim.affectedRefs,
        ...claim.contextRefs,
      ]),
    );
    final activationText = _rawSubmissionActivationText(
      claim,
      locator: locator,
    );
    return ContextActivationItem(
      itemId: 'claim_submission:${claim.claimId}',
      source: 'narrative_claim_submission',
      title: label,
      targetPath: targetPath,
      refs: refs,
      activationReasons: <String>[
        if (pinned) ContextActivationReasonCodes.manualPin,
        ContextActivationReasonCodes.claim,
      ],
      reasonDetails: <String, Object?>{
        'claim_id': claim.claimId,
        'claim_namespace': claim.claimNamespace,
        'required': required,
        'pinned': pinned,
        'priority_weight': _rawSubmissionPriorityWeight(),
      },
      requestedChars: activationText.length,
      metadata: <String, Object?>{
        'source_kind': 'narrative_claim_submission',
        'truth_status': 'submission_log',
        'claim_id': claim.claimId,
        'claim_namespace': claim.claimNamespace,
        'source_of_truth_locator': locator,
        'source_display': _sourceDisplay(claim.source),
        'source_refs': <JsonMap>[claim.source.toJson()],
        'evidence_refs': claim.evidenceRefs
            .map((ref) => ref.toJson())
            .toList(growable: false),
        'required': required,
        'pinned': pinned,
        'priority_weight': _rawSubmissionPriorityWeight(),
        'activation_text': activationText,
      },
    );
  }

  List<NarrativeRef> _fallbackRefs({
    required String targetPath,
    required String targetId,
    required String title,
    required List<NarrativeRef> refs,
  }) {
    if (refs.isNotEmpty) {
      return refs;
    }
    return <NarrativeRef>[
      NarrativeRef(
        refType: NarrativeRefTypes.asset,
        refId: targetId,
        displayName: title,
        relativePath: targetPath,
        sourcePath: targetPath,
      ),
    ];
  }

  List<NarrativeRef> _dedupeRefs(List<NarrativeRef> refs) {
    final seen = <String>{};
    final result = <NarrativeRef>[];
    for (final ref in refs) {
      final key = [
        ref.refType,
        ref.refId,
        ref.relativePath,
        ref.chapterId,
        ref.segmentId,
      ].join('|');
      if (seen.add(key)) {
        result.add(ref);
      }
    }
    return result;
  }

  bool _boolFlags(Object? first, Object? second) {
    return ValueReaders.boolValue(first) || ValueReaders.boolValue(second);
  }

  int _dispositionWeight(NarrativeClaimDisposition disposition) {
    return switch (disposition) {
      NarrativeClaimDisposition.accepted => 500,
      NarrativeClaimDisposition.questioned => 400,
      NarrativeClaimDisposition.proposed => 300,
      NarrativeClaimDisposition.observed => 200,
      NarrativeClaimDisposition.rejected => 100,
      NarrativeClaimDisposition.superseded => 0,
    };
  }

  int _formalLedgerPriorityWeight(NarrativeClaimDisposition disposition) {
    return switch (disposition) {
      NarrativeClaimDisposition.accepted => 280,
      NarrativeClaimDisposition.questioned => 360,
      _ => 120,
    };
  }

  int _pendingLedgerPriorityWeight(NarrativeClaimDisposition disposition) {
    return switch (disposition) {
      NarrativeClaimDisposition.proposed => 90,
      NarrativeClaimDisposition.observed => 70,
      _ => 50,
    };
  }

  int _rawSubmissionPriorityWeight() => 40;

  String _sourceDisplay(NarrativeSourceRef source) {
    final sourceType = source.sourceType.trim();
    final sourceId = source.sourceId.trim();
    if (sourceId.isEmpty) {
      return sourceType;
    }
    return '$sourceType/$sourceId';
  }

  String _ledgerClaimActivationText(
    _LedgerEntryView entryView, {
    required bool formalTruth,
    required String locator,
    required List<NarrativeEvidenceRef> evidenceRefs,
  }) {
    final claim = entryView.entry.claim;
    final label = claim.claimLabel.trim().isEmpty
        ? claim.claimId
        : claim.claimLabel.trim();
    final lines = <String>[
      formalTruth ? '[Ledger Claim]' : '[Pending Ledger Claim]',
      'claim_label: $label',
      'claim_id: ${claim.claimId}',
      'claim_namespace: ${claim.claimNamespace}',
      'ledger_id: ${entryView.ledgerId}',
      'entry_id: ${entryView.entry.entryId}',
      'claim_disposition: ${entryView.entry.disposition.id}',
      'source_of_truth_locator: $locator',
      'source_display: ${_sourceDisplay(entryView.entry.source)}',
      'confidence: ${claim.confidence}',
    ];
    if (claim.uncertainty.trim().isNotEmpty) {
      lines.add('uncertainty: ${claim.uncertainty.trim()}');
    }
    if (entryView.entry.note.trim().isNotEmpty) {
      lines.add('ledger_note: ${entryView.entry.note.trim()}');
    }
    if (claim.claimPayload.isNotEmpty) {
      lines
        ..add('claim_payload:')
        ..add(_prettyObject(claim.claimPayload));
    }
    if (claim.affectedRefs.isNotEmpty) {
      lines
        ..add('affected_refs:')
        ..add(
          _prettyObject(
            claim.affectedRefs
                .map((ref) => ref.toJson())
                .toList(growable: false),
          ),
        );
    }
    if (claim.contextRefs.isNotEmpty) {
      lines
        ..add('context_refs:')
        ..add(
          _prettyObject(
            claim.contextRefs
                .map((ref) => ref.toJson())
                .toList(growable: false),
          ),
        );
    }
    if (evidenceRefs.isNotEmpty) {
      lines
        ..add('evidence_refs:')
        ..add(
          _prettyObject(
            evidenceRefs.map((ref) => ref.toJson()).toList(growable: false),
          ),
        );
    }
    if (!formalTruth) {
      lines.add('status_note: 当前只进入 ledger 提交流，尚未成为正式 continuity truth。');
    }
    return lines.join('\n');
  }

  String _rawSubmissionActivationText(
    NarrativeStateClaim claim, {
    required String locator,
  }) {
    final label = claim.claimLabel.trim().isEmpty
        ? claim.claimId
        : claim.claimLabel.trim();
    final lines = <String>[
      '[Claim Submission]',
      'claim_label: $label',
      'claim_id: ${claim.claimId}',
      'claim_namespace: ${claim.claimNamespace}',
      'source_of_truth_locator: $locator',
      'source_display: ${_sourceDisplay(claim.source)}',
      'confidence: ${claim.confidence}',
      'status_note: 该 claim 尚未进入 narrative state ledger，不能视为正式 continuity truth。',
    ];
    if (claim.uncertainty.trim().isNotEmpty) {
      lines.add('uncertainty: ${claim.uncertainty.trim()}');
    }
    if (claim.claimPayload.isNotEmpty) {
      lines
        ..add('claim_payload:')
        ..add(_prettyObject(claim.claimPayload));
    }
    if (claim.affectedRefs.isNotEmpty) {
      lines
        ..add('affected_refs:')
        ..add(
          _prettyObject(
            claim.affectedRefs
                .map((ref) => ref.toJson())
                .toList(growable: false),
          ),
        );
    }
    if (claim.contextRefs.isNotEmpty) {
      lines
        ..add('context_refs:')
        ..add(
          _prettyObject(
            claim.contextRefs
                .map((ref) => ref.toJson())
                .toList(growable: false),
          ),
        );
    }
    if (claim.evidenceRefs.isNotEmpty) {
      lines
        ..add('evidence_refs:')
        ..add(
          _prettyObject(
            claim.evidenceRefs
                .map((ref) => ref.toJson())
                .toList(growable: false),
          ),
        );
    }
    return lines.join('\n');
  }

  String _prettyObject(Object? value) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}

class _LedgerEntryView {
  const _LedgerEntryView({required this.ledgerId, required this.entry});

  final String ledgerId;
  final NarrativeLedgerEntry entry;
}
