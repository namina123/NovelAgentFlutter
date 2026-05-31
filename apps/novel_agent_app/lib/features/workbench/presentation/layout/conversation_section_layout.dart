import 'package:flutter/material.dart';

import 'conversation_section_id.dart';
import 'conversation_section_slot.dart';
import 'section_placement.dart';

@immutable
class ConversationSectionSlotSpec {
  const ConversationSectionSlotSpec({
    required this.slotId,
    this.expand = false,
  });

  final ConversationSectionSlot slotId;
  final bool expand;
}

@immutable
class ConversationSectionLayout {
  const ConversationSectionLayout({
    required this.slotSpecs,
    required this.placements,
  });

  final List<ConversationSectionSlotSpec> slotSpecs;
  final List<SectionPlacement<ConversationSectionId, ConversationSectionSlot>>
  placements;

  List<SectionPlacement<ConversationSectionId, ConversationSectionSlot>>
  placementsForSlot(ConversationSectionSlot slotId) {
    final matches = placements
        .where((placement) => placement.slotId == slotId)
        .toList(growable: false);
    matches.sort((left, right) => left.order.compareTo(right.order));
    return matches;
  }
}
