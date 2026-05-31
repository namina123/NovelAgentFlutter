import 'package:flutter/material.dart';

@immutable
class SectionPlacement<TSectionId, TSlotId> {
  const SectionPlacement({
    required this.sectionId,
    required this.slotId,
    required this.order,
  });

  final TSectionId sectionId;
  final TSlotId slotId;
  final int order;
}
