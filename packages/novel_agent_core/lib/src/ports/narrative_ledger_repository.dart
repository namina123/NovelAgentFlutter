import '../continuity/narrative_state/narrative_ledger_entry.dart';
import '../continuity/narrative_state/narrative_ledger_event.dart';
import '../continuity/narrative_state/narrative_state_ledger.dart';
import '../project/project_descriptor.dart';

abstract class NarrativeLedgerRepository {
  Future<void> appendLedgerEntry(
    ProjectDescriptor project,
    NarrativeLedgerEntry entry, {
    required String ledgerId,
  });

  Future<void> appendLedgerEvent(
    ProjectDescriptor project,
    NarrativeLedgerEvent event, {
    required String ledgerId,
  });

  Future<NarrativeStateLedger?> readLedger(
    ProjectDescriptor project, {
    required String ledgerId,
  });

  Future<List<NarrativeStateLedger>> listLedgers(ProjectDescriptor project);
}
