import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpenNarrativeStateProjectionWriterService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late LocalProjectWorkspacePort workspacePort;
    late LocalNarrativeProfileRepository profileRepository;
    late LocalNarrativeClaimRepository claimRepository;
    late LocalNarrativeLedgerRepository ledgerRepository;
    late LocalSemanticReviewRepository reviewRepository;
    late LocalConstraintBindingRepository bindingRepository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-projection-writer-',
      );
      workspacePort = LocalProjectWorkspacePort();
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
      );
      profileRepository = LocalNarrativeProfileRepository(
        workspacePort: workspacePort,
      );
      claimRepository = LocalNarrativeClaimRepository(
        workspacePort: workspacePort,
      );
      ledgerRepository = LocalNarrativeLedgerRepository(
        workspacePort: workspacePort,
      );
      reviewRepository = LocalSemanticReviewRepository(
        workspacePort: workspacePort,
      );
      bindingRepository = LocalConstraintBindingRepository(
        workspacePort: workspacePort,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'writes visible markdown projections without mutating hidden fact sources',
      () async {
        await profileRepository.appendProfile(
          project,
          NarrativeProfile(
            profileId: 'hero',
            profileNamespace: 'character',
            profileLabel: '主角',
            lifecycleStatus: NarrativeProfileLifecycleStatus.accepted,
            profilePayload: const <String, Object?>{'weapon': 'spear'},
            source: _source(),
          ),
        );
        final claim = NarrativeStateClaim.fromJson(<String, Object?>{
          'claim_id': 'claim-1',
          'claim_namespace': 'continuity',
          'claim_payload': <String, Object?>{
            'unknown_payload': <String, Object?>{'weather': 'ash'},
          },
          'source': _source().toJson(),
          'mystery_field': 'kept',
        });
        await claimRepository.appendClaim(project, claim);
        await ledgerRepository.appendLedgerEntry(
          project,
          NarrativeLedgerEntry(
            entryId: 'entry-1',
            claim: claim,
            disposition: NarrativeClaimDisposition.accepted,
            source: _source(),
          ),
          ledgerId: 'main-ledger',
        );
        await reviewRepository.appendReview(
          project,
          NarrativeSemanticReview(
            reviewId: 'review-1',
            source: _source(),
            recommendedDisposition:
                SemanticReviewRecommendedDisposition.acceptWithNote,
            summary: 'summary',
          ),
        );
        await bindingRepository.appendBinding(
          project,
          NarrativeConstraintBindingProposal(
            bindingId: 'binding-1',
            constraintType: 'style_rule',
            constraintLabel: '禁用全知旁白',
            constraintPayload: const <String, Object?>{
              'unknown_payload': <String, Object?>{'severity': 'high'},
            },
            scope: const ConstraintBindingScope(appliesTo: <String>['draft']),
            policy: const ConstraintBindingPolicy(
              requiresUserConfirmation: true,
            ),
            source: _source(),
          ),
        );

        final writer = OpenNarrativeStateProjectionWriterService(
          workspacePort: workspacePort,
          profileRepository: profileRepository,
          claimRepository: claimRepository,
          ledgerRepository: ledgerRepository,
          reviewRepository: reviewRepository,
          bindingRepository: bindingRepository,
        );

        final documents = await writer.writeProjection(project);

        expect(documents, hasLength(4));
        final rulesFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}continuity${Platform.pathSeparator}叙事状态规则.md',
        );
        final changesFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}continuity${Platform.pathSeparator}最近状态变化.md',
        );
        final constraintsFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}constraints${Platform.pathSeparator}项目约束摘要.md',
        );
        final reviewsFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}reviews${Platform.pathSeparator}语义复核摘要.md',
        );
        expect(await rulesFile.exists(), isTrue);
        expect(await changesFile.exists(), isTrue);
        expect(await constraintsFile.exists(), isTrue);
        expect(await reviewsFile.exists(), isTrue);
        expect(
          await rulesFile.readAsString(),
          contains('这份 Markdown 只是结构化事实源的可读投影'),
        );

        await rulesFile.delete();
        await changesFile.delete();
        await constraintsFile.delete();
        await reviewsFile.delete();

        final loadedProfile = await profileRepository.readProfile(
          project,
          profileId: 'hero',
        );
        final loadedClaim = await claimRepository.readClaim(
          project,
          claimId: 'claim-1',
        );
        final loadedLedger = await ledgerRepository.readLedger(
          project,
          ledgerId: 'main-ledger',
        );
        final loadedReview = await reviewRepository.readReview(
          project,
          reviewId: 'review-1',
        );
        final loadedBinding = await bindingRepository.readBinding(
          project,
          bindingId: 'binding-1',
        );

        expect(loadedProfile, isNotNull);
        expect(loadedClaim, isNotNull);
        expect(loadedClaim!.toJson()['mystery_field'], 'kept');
        expect(loadedLedger, isNotNull);
        expect(loadedReview, isNotNull);
        expect(loadedBinding, isNotNull);
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
