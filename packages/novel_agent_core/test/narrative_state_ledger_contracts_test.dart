import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeStateLedger contracts', () {
    test('ledger preserves different sources for the same fact without collapsing entries', () {
      const codec = NarrativeStateLedgerCodecService();
      final ledger = codec.ledgerFromJson(<String, Object?>{
        'ledger_id': 'ledger-001',
        'entries': <Object?>[
          <String, Object?>{
            'entry_id': 'entry-observed',
            'claim': <String, Object?>{
              'claim_id': 'claim-shared',
              'claim_namespace': 'analysis.character.memory',
              'claim_payload': <String, Object?>{
                'memory_state': 'partial',
              },
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.deconstruction,
              },
            },
            'disposition': 'observed',
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.deconstruction,
            },
          },
          <String, Object?>{
            'entry_id': 'entry-proposed',
            'claim': <String, Object?>{
              'claim_id': 'claim-shared',
              'claim_namespace': 'analysis.character.memory',
              'claim_payload': <String, Object?>{
                'memory_state': 'partial',
              },
              'source': <String, Object?>{
                'source_type': NarrativeSourceTypes.user,
              },
            },
            'disposition': 'proposed',
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.user,
            },
          },
        ],
      });

      expect(ledger.entries, hasLength(2));
      expect(ledger.entries[0].disposition, NarrativeClaimDisposition.observed);
      expect(ledger.entries[1].disposition, NarrativeClaimDisposition.proposed);
      expect(ledger.entries[0].source.sourceType, NarrativeSourceTypes.deconstruction);
      expect(ledger.entries[1].source.sourceType, NarrativeSourceTypes.user);
      expect(ledger.entries[0].claim.claimId, 'claim-shared');
      expect(ledger.entries[1].claim.claimId, 'claim-shared');
      expect(ledger.validateBasics(), isEmpty);
    });

    test('entry supports source evidence and supersedes replacement links', () {
      const codec = NarrativeStateLedgerCodecService();
      final entry = codec.entryFromJson(<String, Object?>{
        'entry_id': 'entry-accepted',
        'claim': <String, Object?>{
          'claim_id': 'claim-accepted',
          'claim_namespace': 'project.rule.scope',
          'claim_payload': <String, Object?>{
            'scope_mode': 'frame_scoped',
          },
          'source': <String, Object?>{
            'source_type': NarrativeSourceTypes.writer,
          },
        },
        'disposition': 'accepted',
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.reviewer,
        },
        'evidence_refs': <Object?>[
          <String, Object?>{
            'evidence_type': NarrativeEvidenceTypes.reviewNote,
            'evidence_id': 'evidence-accepted',
          },
        ],
        'supersedes_entry_ids': <Object?>['entry-old-001'],
        'replacement_entry_ids': <Object?>['entry-next-001'],
        'events': <Object?>[
          <String, Object?>{
            'event_id': 'event-accepted',
            'event_type': 'review_accept',
            'disposition': 'accepted',
            'source': <String, Object?>{
              'source_type': NarrativeSourceTypes.reviewer,
            },
            'related_entry_ids': <Object?>['entry-old-001', 'entry-next-001'],
          },
        ],
      });

      final encoded = codec.entryToJson(entry);

      expect(entry.disposition, NarrativeClaimDisposition.accepted);
      expect(entry.supersedesEntryIds, contains('entry-old-001'));
      expect(entry.replacementEntryIds, contains('entry-next-001'));
      expect(entry.events.single.disposition, NarrativeClaimDisposition.accepted);
      expect(
        ((encoded['events'] as List<Object?>).single as Map<String, Object?>)['event_type'],
        'review_accept',
      );
      expect(entry.validateBasics(), isEmpty);
    });

    test('ledger event supports questioned rejected and superseded dispositions', () {
      const codec = NarrativeStateLedgerCodecService();
      final questioned = codec.eventFromJson(<String, Object?>{
        'event_id': 'event-questioned',
        'event_type': 'review_questioned',
        'disposition': 'questioned',
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.reviewer,
        },
      });
      final rejected = codec.eventFromJson(<String, Object?>{
        'event_id': 'event-rejected',
        'event_type': 'user_rejected',
        'disposition': 'rejected',
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.user,
        },
      });
      final superseded = codec.eventFromJson(<String, Object?>{
        'event_id': 'event-superseded',
        'event_type': 'profile_superseded',
        'disposition': 'superseded',
        'source': <String, Object?>{
          'source_type': NarrativeSourceTypes.system,
        },
      });

      expect(questioned.disposition, NarrativeClaimDisposition.questioned);
      expect(rejected.disposition, NarrativeClaimDisposition.rejected);
      expect(superseded.disposition, NarrativeClaimDisposition.superseded);
    });

    test('validation basics report missing ids and source type', () {
      final ledger = NarrativeStateLedger.fromJson(<String, Object?>{
        'ledger_id': '',
        'entries': <Object?>[
          <String, Object?>{
            'entry_id': '',
            'claim': <String, Object?>{
              'claim_id': '',
              'claim_namespace': 'test',
              'claim_payload': <String, Object?>{},
              'source': <String, Object?>{},
            },
            'disposition': 'observed',
            'source': <String, Object?>{},
            'events': <Object?>[
              <String, Object?>{
                'event_id': '',
                'event_type': '',
                'disposition': 'observed',
                'source': <String, Object?>{},
              },
            ],
          },
        ],
      });

      expect(
        ledger.validateBasics(),
        containsAll(<String>[
          NarrativeLedgerValidationCodes.missingLedgerId,
          NarrativeLedgerValidationCodes.missingEntryId,
          NarrativeLedgerValidationCodes.missingClaimId,
          NarrativeLedgerValidationCodes.missingSourceType,
          NarrativeLedgerValidationCodes.missingEventId,
          NarrativeLedgerValidationCodes.missingEventType,
        ]),
      );
    });
  });
}
