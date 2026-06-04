import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('narrative repository ports', () {
    final project = ProjectDescriptor(
      id: 'project-1',
      name: 'Project 1',
      rootPath: '/workspace/project-1',
    );

    test('profile repository supports append read list', () async {
      final repository = _FakeNarrativeProfileRepository();
      final profile = NarrativeProfile(
        profileId: 'profile-1',
        profileNamespace: 'character',
        lifecycleStatus: NarrativeProfileLifecycleStatus.accepted,
        source: _source(),
        profileLabel: 'Hero',
      );

      await repository.appendProfile(project, profile);

      expect(
        await repository.readProfile(project, profileId: 'profile-1'),
        same(profile),
      );
      expect(
        await repository.listProfiles(project, profileNamespace: 'character'),
        [same(profile)],
      );
    });

    test('claim repository supports append read list', () async {
      final repository = _FakeNarrativeClaimRepository();
      final claim = NarrativeStateClaim(
        claimId: 'claim-1',
        claimNamespace: 'continuity',
        claimPayload: const <String, Object?>{'fact': 'joined guild'},
        source: _source(),
        claimLabel: 'Guild membership',
      );

      await repository.appendClaim(project, claim);

      expect(
        await repository.readClaim(project, claimId: 'claim-1'),
        same(claim),
      );
      expect(
        await repository.listClaims(project, claimNamespace: 'continuity'),
        [same(claim)],
      );
    });

    test('ledger repository supports append read list', () async {
      final repository = _FakeNarrativeLedgerRepository();
      final claim = NarrativeStateClaim(
        claimId: 'claim-2',
        claimNamespace: 'continuity',
        claimPayload: const <String, Object?>{'fact': 'entered city'},
        source: _source(),
      );
      final entry = NarrativeLedgerEntry(
        entryId: 'entry-1',
        claim: claim,
        disposition: NarrativeClaimDisposition.accepted,
        source: _source(),
      );
      final event = NarrativeLedgerEvent(
        eventId: 'event-1',
        eventType: 'accepted',
        disposition: NarrativeClaimDisposition.accepted,
        source: _source(),
        entryId: 'entry-1',
      );

      await repository.appendLedgerEntry(project, entry, ledgerId: 'ledger-1');
      await repository.appendLedgerEvent(project, event, ledgerId: 'ledger-1');

      final ledger = await repository.readLedger(project, ledgerId: 'ledger-1');
      expect(ledger, isNotNull);
      expect(ledger!.entries, [same(entry)]);
      expect(ledger.events, [same(event)]);
      expect(await repository.listLedgers(project), [
        isA<NarrativeStateLedger>(),
      ]);
    });

    test('semantic review repository supports append read list', () async {
      final repository = _FakeSemanticReviewRepository();
      final review = NarrativeSemanticReview(
        reviewId: 'review-1',
        source: _source(),
        recommendedDisposition:
            SemanticReviewRecommendedDisposition.acceptWithNote,
        summary: 'Needs a note',
      );

      await repository.appendReview(project, review);

      expect(
        await repository.readReview(project, reviewId: 'review-1'),
        same(review),
      );
      expect(await repository.listReviews(project), [same(review)]);
    });

    test('constraint binding repository supports append read list', () async {
      final repository = _FakeConstraintBindingRepository();
      final binding = NarrativeConstraintBindingProposal(
        bindingId: 'binding-1',
        constraintType: 'style',
        scope: const ConstraintBindingScope(appliesTo: <String>['draft']),
        policy: const ConstraintBindingPolicy(autoAccept: true),
        source: _source(),
        constraintLabel: 'No omniscient narration',
      );

      await repository.appendBinding(project, binding);

      expect(
        await repository.readBinding(project, bindingId: 'binding-1'),
        same(binding),
      );
      expect(await repository.listBindings(project, constraintType: 'style'), [
        same(binding),
      ]);
    });
  });
}

NarrativeSourceRef _source() {
  return const NarrativeSourceRef(
    sourceType: 'tool_call',
    sourceId: 'source-1',
    label: 'tool',
  );
}

class _FakeNarrativeProfileRepository implements NarrativeProfileRepository {
  final Map<String, Map<String, NarrativeProfile>> _profilesByProject =
      <String, Map<String, NarrativeProfile>>{};

  @override
  Future<void> appendProfile(
    ProjectDescriptor project,
    NarrativeProfile profile,
  ) async {
    _profilesByProject.putIfAbsent(
      project.id,
      () => <String, NarrativeProfile>{},
    )[profile.profileId] = profile;
  }

  @override
  Future<List<NarrativeProfile>> listProfiles(
    ProjectDescriptor project, {
    String? profileNamespace,
  }) async {
    return _profilesByProject[project.id]?.values
            .where(
              (profile) =>
                  profileNamespace == null ||
                  profile.profileNamespace == profileNamespace,
            )
            .toList(growable: false) ??
        const <NarrativeProfile>[];
  }

  @override
  Future<NarrativeProfile?> readProfile(
    ProjectDescriptor project, {
    required String profileId,
  }) async {
    return _profilesByProject[project.id]?[profileId];
  }
}

class _FakeNarrativeClaimRepository implements NarrativeClaimRepository {
  final Map<String, Map<String, NarrativeStateClaim>> _claimsByProject =
      <String, Map<String, NarrativeStateClaim>>{};

  @override
  Future<void> appendClaim(
    ProjectDescriptor project,
    NarrativeStateClaim claim,
  ) async {
    _claimsByProject.putIfAbsent(
      project.id,
      () => <String, NarrativeStateClaim>{},
    )[claim.claimId] = claim;
  }

  @override
  Future<List<NarrativeStateClaim>> listClaims(
    ProjectDescriptor project, {
    String? claimNamespace,
  }) async {
    return _claimsByProject[project.id]?.values
            .where(
              (claim) =>
                  claimNamespace == null ||
                  claim.claimNamespace == claimNamespace,
            )
            .toList(growable: false) ??
        const <NarrativeStateClaim>[];
  }

  @override
  Future<NarrativeStateClaim?> readClaim(
    ProjectDescriptor project, {
    required String claimId,
  }) async {
    return _claimsByProject[project.id]?[claimId];
  }
}

class _FakeNarrativeLedgerRepository implements NarrativeLedgerRepository {
  final Map<String, Map<String, NarrativeStateLedger>> _ledgersByProject =
      <String, Map<String, NarrativeStateLedger>>{};

  @override
  Future<void> appendLedgerEntry(
    ProjectDescriptor project,
    NarrativeLedgerEntry entry, {
    required String ledgerId,
  }) async {
    final ledger = _readOrCreate(project, ledgerId);
    _ledgersByProject[project.id]![ledgerId] = ledger.copyWith(
      entries: <NarrativeLedgerEntry>[...ledger.entries, entry],
    );
  }

  @override
  Future<void> appendLedgerEvent(
    ProjectDescriptor project,
    NarrativeLedgerEvent event, {
    required String ledgerId,
  }) async {
    final ledger = _readOrCreate(project, ledgerId);
    _ledgersByProject[project.id]![ledgerId] = ledger.copyWith(
      events: <NarrativeLedgerEvent>[...ledger.events, event],
    );
  }

  @override
  Future<List<NarrativeStateLedger>> listLedgers(
    ProjectDescriptor project,
  ) async {
    return _ledgersByProject[project.id]?.values.toList(growable: false) ??
        const <NarrativeStateLedger>[];
  }

  @override
  Future<NarrativeStateLedger?> readLedger(
    ProjectDescriptor project, {
    required String ledgerId,
  }) async {
    return _ledgersByProject[project.id]?[ledgerId];
  }

  NarrativeStateLedger _readOrCreate(
    ProjectDescriptor project,
    String ledgerId,
  ) {
    final projectLedgers = _ledgersByProject.putIfAbsent(
      project.id,
      () => <String, NarrativeStateLedger>{},
    );
    return projectLedgers.putIfAbsent(
      ledgerId,
      () => NarrativeStateLedger(ledgerId: ledgerId),
    );
  }
}

class _FakeSemanticReviewRepository implements SemanticReviewRepository {
  final Map<String, Map<String, NarrativeSemanticReview>> _reviewsByProject =
      <String, Map<String, NarrativeSemanticReview>>{};

  @override
  Future<void> appendReview(
    ProjectDescriptor project,
    NarrativeSemanticReview review,
  ) async {
    _reviewsByProject.putIfAbsent(
      project.id,
      () => <String, NarrativeSemanticReview>{},
    )[review.reviewId] = review;
  }

  @override
  Future<List<NarrativeSemanticReview>> listReviews(
    ProjectDescriptor project,
  ) async {
    return _reviewsByProject[project.id]?.values.toList(growable: false) ??
        const <NarrativeSemanticReview>[];
  }

  @override
  Future<NarrativeSemanticReview?> readReview(
    ProjectDescriptor project, {
    required String reviewId,
  }) async {
    return _reviewsByProject[project.id]?[reviewId];
  }
}

class _FakeConstraintBindingRepository implements ConstraintBindingRepository {
  final Map<String, Map<String, NarrativeConstraintBindingProposal>>
  _bindingsByProject =
      <String, Map<String, NarrativeConstraintBindingProposal>>{};

  @override
  Future<void> appendBinding(
    ProjectDescriptor project,
    NarrativeConstraintBindingProposal binding,
  ) async {
    _bindingsByProject.putIfAbsent(
      project.id,
      () => <String, NarrativeConstraintBindingProposal>{},
    )[binding.bindingId] = binding;
  }

  @override
  Future<List<NarrativeConstraintBindingProposal>> listBindings(
    ProjectDescriptor project, {
    String? constraintType,
  }) async {
    return _bindingsByProject[project.id]?.values
            .where(
              (binding) =>
                  constraintType == null ||
                  binding.constraintType == constraintType,
            )
            .toList(growable: false) ??
        const <NarrativeConstraintBindingProposal>[];
  }

  @override
  Future<NarrativeConstraintBindingProposal?> readBinding(
    ProjectDescriptor project, {
    required String bindingId,
  }) async {
    return _bindingsByProject[project.id]?[bindingId];
  }
}
