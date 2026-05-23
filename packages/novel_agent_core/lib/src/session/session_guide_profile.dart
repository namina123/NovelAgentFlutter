import 'session_guide_action.dart';

class SessionGuideProfile {
  const SessionGuideProfile({
    required this.profileId,
    required this.title,
    required this.description,
    required this.composerHint,
    required this.statusHint,
    required this.primaryActions,
    this.secondaryActions = const <SessionGuideAction>[],
  });

  final String profileId;
  final String title;
  final String description;
  final String composerHint;
  final String statusHint;
  final List<SessionGuideAction> primaryActions;
  final List<SessionGuideAction> secondaryActions;
}
