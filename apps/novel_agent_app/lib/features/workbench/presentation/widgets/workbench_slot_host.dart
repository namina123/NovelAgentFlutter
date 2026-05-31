import 'package:flutter/material.dart';

import '../layout/workbench_slot_id.dart';

@immutable
class WorkbenchSlotEntry {
  const WorkbenchSlotEntry({
    required this.slotId,
    required this.child,
  });

  final WorkbenchSlotId slotId;
  final Widget child;
}

class WorkbenchSlotLookup {
  WorkbenchSlotLookup._(List<WorkbenchSlotEntry> entries)
    : _entries = {
        for (final entry in entries) entry.slotId: entry.child,
      };

  final Map<WorkbenchSlotId, Widget> _entries;

  Widget require(WorkbenchSlotId slotId) {
    final child = _entries[slotId];
    if (child == null) {
      throw StateError('Missing workbench slot child for $slotId');
    }
    return child;
  }

  Widget? maybe(WorkbenchSlotId slotId) => _entries[slotId];
}

class WorkbenchSlotHost extends StatelessWidget {
  const WorkbenchSlotHost({
    super.key,
    required this.entries,
    required this.builder,
  });

  final List<WorkbenchSlotEntry> entries;
  final Widget Function(BuildContext context, WorkbenchSlotLookup lookup)
  builder;

  @override
  Widget build(BuildContext context) {
    return builder(context, WorkbenchSlotLookup._(entries));
  }
}
