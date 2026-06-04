import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('local narrative state repositories', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-narrative-state-repositories-',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'profile repository persists json inside hidden continuity directory',
      () async {
        final repository = LocalNarrativeProfileRepository(
          workspacePort: workspacePort,
        );
        final profile = NarrativeProfile.fromJson(<String, Object?>{
          'profile_id': 'hero',
          'profile_namespace': 'character',
          'profile_label': '主角',
          'lifecycle_status': 'accepted',
          'profile_payload': <String, Object?>{
            'weapon': 'spear',
            'unknown_trait': <String, Object?>{'rarity': 'mythic'},
          },
          'profile_extensions': <String, Object?>{'mood': 'grim'},
          'source': _source().toJson(),
          'confidence': 0.93,
          'reason': 'accepted by reviewer',
          'schema_version': '1',
          'metadata': <String, Object?>{'tag': 'important'},
        });

        await repository.appendProfile(project, profile);

        final loaded = await repository.readProfile(project, profileId: 'hero');
        final list = await repository.listProfiles(
          project,
          profileNamespace: 'character',
        );

        expect(loaded, isNotNull);
        expect(loaded!.profilePayload['unknown_trait'], <String, Object?>{
          'rarity': 'mythic',
        });
        expect(list, hasLength(1));
        final profileFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}profiles${Platform.pathSeparator}hero.json',
        );
        final indexFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}profiles${Platform.pathSeparator}index.json',
        );
        expect(await profileFile.exists(), isTrue);
        expect(await indexFile.exists(), isTrue);
      },
    );

    test(
      'claim repository persists jsonl and keeps unknown top level fields',
      () async {
        final repository = LocalNarrativeClaimRepository(
          workspacePort: workspacePort,
        );
        final claim = NarrativeStateClaim.fromJson(<String, Object?>{
          'claim_id': 'claim-1',
          'claim_namespace': 'continuity',
          'claim_label': '装备变更',
          'claim_payload': <String, Object?>{
            'inventory': <Object?>['rope', 'map'],
          },
          'source': _source().toJson(),
          'confidence': 0.88,
          'uncertainty': 'low',
          'schema_version': '1',
          'metadata': <String, Object?>{'hint': 'roundtrip'},
          'mystery_field': 'kept',
        });

        await repository.appendClaim(project, claim);

        final loaded = await repository.readClaim(project, claimId: 'claim-1');
        final listed = await repository.listClaims(
          project,
          claimNamespace: 'continuity',
        );

        expect(loaded, isNotNull);
        expect(loaded!.toJson()['mystery_field'], 'kept');
        expect(listed, hasLength(1));
        final logFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}claims${Platform.pathSeparator}claims.jsonl',
        );
        expect(await logFile.exists(), isTrue);
        expect(
          await logFile.readAsString(),
          contains('"mystery_field":"kept"'),
        );
      },
    );

    test(
      'ledger repository persists entries and events under hidden continuity directory',
      () async {
        final repository = LocalNarrativeLedgerRepository(
          workspacePort: workspacePort,
        );
        final claim = NarrativeStateClaim(
          claimId: 'claim-ledger',
          claimNamespace: 'timeline',
          claimPayload: const <String, Object?>{
            'location': 'ancient_gate',
            'unknown_payload': <String, Object?>{'weather': 'ash'},
          },
          source: _source(),
        );
        final entry = NarrativeLedgerEntry(
          entryId: 'entry-1',
          claim: claim,
          disposition: NarrativeClaimDisposition.accepted,
          source: _source(),
          note: 'entry-note',
        );
        final event = NarrativeLedgerEvent(
          eventId: 'event-1',
          eventType: 'accepted',
          disposition: NarrativeClaimDisposition.accepted,
          source: _source(),
          entryId: 'entry-1',
          summary: 'event-summary',
        );

        await repository.appendLedgerEntry(
          project,
          entry,
          ledgerId: 'main-ledger',
        );
        await repository.appendLedgerEvent(
          project,
          event,
          ledgerId: 'main-ledger',
        );

        final loaded = await repository.readLedger(
          project,
          ledgerId: 'main-ledger',
        );
        final listed = await repository.listLedgers(project);

        expect(loaded, isNotNull);
        expect(loaded!.entries.single.claim.claimPayload['unknown_payload'], {
          'weather': 'ash',
        });
        expect(loaded.events.single.summary, 'event-summary');
        expect(listed.map((item) => item.ledgerId), <String>['main-ledger']);
        final entriesFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}ledgers${Platform.pathSeparator}main-ledger${Platform.pathSeparator}entries.jsonl',
        );
        final eventsFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}ledgers${Platform.pathSeparator}main-ledger${Platform.pathSeparator}events.jsonl',
        );
        expect(await entriesFile.exists(), isTrue);
        expect(await eventsFile.exists(), isTrue);
      },
    );

    test(
      'semantic review repository persists json and preserves suggested claims payloads',
      () async {
        final repository = LocalSemanticReviewRepository(
          workspacePort: workspacePort,
        );
        final review = NarrativeSemanticReview(
          reviewId: 'review-1',
          source: _source(),
          recommendedDisposition:
              SemanticReviewRecommendedDisposition.acceptWithNote,
          summary: 'summary',
          suggestedClaims: <NarrativeStateClaim>[
            NarrativeStateClaim(
              claimId: 'suggested-1',
              claimNamespace: 'continuity',
              claimPayload: const <String, Object?>{
                'unexpected': <String, Object?>{'tone_shift': true},
              },
              source: _source(),
            ),
          ],
        );

        await repository.appendReview(project, review);

        final loaded = await repository.readReview(
          project,
          reviewId: 'review-1',
        );
        final listed = await repository.listReviews(project);

        expect(loaded, isNotNull);
        expect(
          loaded!.suggestedClaims.single.claimPayload['unexpected'],
          <String, Object?>{'tone_shift': true},
        );
        expect(listed, hasLength(1));
        final reviewFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}reviews${Platform.pathSeparator}review-1.json',
        );
        expect(await reviewFile.exists(), isTrue);
      },
    );

    test(
      'constraint binding repository persists json and preserves open payload',
      () async {
        final repository = LocalConstraintBindingRepository(
          workspacePort: workspacePort,
        );
        final binding = NarrativeConstraintBindingProposal(
          bindingId: 'binding-1',
          constraintType: 'style_rule',
          constraintLabel: '禁用全知旁白',
          constraintPayload: const <String, Object?>{
            'forbidden_patterns': <Object?>['全知', '作者插嘴'],
            'unknown_payload': <String, Object?>{'severity': 'high'},
          },
          scope: const ConstraintBindingScope(appliesTo: <String>['draft']),
          policy: const ConstraintBindingPolicy(requiresUserConfirmation: true),
          source: _source(),
        );

        await repository.appendBinding(project, binding);

        final loaded = await repository.readBinding(
          project,
          bindingId: 'binding-1',
        );
        final listed = await repository.listBindings(
          project,
          constraintType: 'style_rule',
        );

        expect(loaded, isNotNull);
        expect(loaded!.constraintPayload['unknown_payload'], {
          'severity': 'high',
        });
        expect(listed, hasLength(1));
        final bindingFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}continuity${Platform.pathSeparator}bindings${Platform.pathSeparator}binding-1.json',
        );
        expect(await bindingFile.exists(), isTrue);
      },
    );
  });
}

NarrativeSourceRef _source() {
  return const NarrativeSourceRef(
    sourceType: 'tool_call',
    sourceId: 'source-1',
    label: 'tool',
  );
}
