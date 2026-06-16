import 'package:flutter/material.dart';

enum ResourceTreeSemanticTone {
  neutral,
  blue,
  teal,
  amber,
  green,
  purple,
  rose,
}

class ResourceTreeEntrySemanticViewData {
  const ResourceTreeEntrySemanticViewData({
    required this.detailLabel,
    required this.leadingIcon,
    this.badgeLabel = '',
    this.tone = ResourceTreeSemanticTone.neutral,
  });

  final String detailLabel;
  final IconData leadingIcon;
  final String badgeLabel;
  final ResourceTreeSemanticTone tone;

  bool get hasBadge => badgeLabel.trim().isNotEmpty;
}
