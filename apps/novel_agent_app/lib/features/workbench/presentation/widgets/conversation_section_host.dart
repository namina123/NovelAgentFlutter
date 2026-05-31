import 'package:flutter/material.dart';

import '../layout/conversation_section_id.dart';
import '../layout/conversation_section_layout.dart';

@immutable
class ConversationSectionEntry {
  const ConversationSectionEntry({
    required this.sectionId,
    required this.child,
  });

  final ConversationSectionId sectionId;
  final Widget child;
}

class ConversationSectionHost extends StatelessWidget {
  const ConversationSectionHost({
    super.key,
    required this.layout,
    required this.entries,
    this.slotGap = 12,
    this.sectionGap = 8,
  });

  final ConversationSectionLayout layout;
  final List<ConversationSectionEntry> entries;
  final double slotGap;
  final double sectionGap;

  @override
  Widget build(BuildContext context) {
    final entryMap = {
      for (final entry in entries) entry.sectionId: entry.child,
    };
    final renderedSlots = <Widget>[];
    for (final slotSpec in layout.slotSpecs) {
      final placements = layout.placementsForSlot(slotSpec.slotId);
      final children = placements
          .map((placement) => entryMap[placement.sectionId])
          .whereType<Widget>()
          .toList(growable: false);
      if (children.isEmpty) {
        continue;
      }
      final slotChild = _SectionSlotColumn(
        sectionGap: sectionGap,
        children: children,
      );
      renderedSlots.add(
        slotSpec.expand ? Expanded(child: slotChild) : slotChild,
      );
    }
    return _SlotColumn(slotGap: slotGap, children: renderedSlots);
  }
}

class _SlotColumn extends StatelessWidget {
  const _SlotColumn({
    required this.children,
    required this.slotGap,
  });

  final List<Widget> children;
  final double slotGap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: slotGap),
          children[index],
        ],
      ],
    );
  }
}

class _SectionSlotColumn extends StatelessWidget {
  const _SectionSlotColumn({
    required this.children,
    required this.sectionGap,
  });

  final List<Widget> children;
  final double sectionGap;

  @override
  Widget build(BuildContext context) {
    if (children.length == 1) {
      return children.first;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) SizedBox(height: sectionGap),
          children[index],
        ],
      ],
    );
  }
}
