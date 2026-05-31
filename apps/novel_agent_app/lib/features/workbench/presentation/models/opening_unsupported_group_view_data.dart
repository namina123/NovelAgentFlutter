import 'package:flutter/foundation.dart';

class OpeningUnsupportedGroupViewData {
  const OpeningUnsupportedGroupViewData({
    required this.groupId,
    required this.displayName,
    required this.description,
    required this.reasonSummary,
    required this.reasonDetails,
  });

  final String groupId;
  final String displayName;
  final String description;
  final String reasonSummary;
  final List<String> reasonDetails;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OpeningUnsupportedGroupViewData &&
            other.groupId == groupId &&
            other.displayName == displayName &&
            other.description == description &&
            other.reasonSummary == reasonSummary &&
            listEquals(other.reasonDetails, reasonDetails);
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    displayName,
    description,
    reasonSummary,
    Object.hashAll(reasonDetails),
  );
}
