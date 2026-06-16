import 'package:novel_agent_core/novel_agent_core.dart';

class BookDeconstructionFollowupOptionSelectionService {
  const BookDeconstructionFollowupOptionSelectionService();

  String resolveSelectedOptionId({
    required BookDeconstructionFollowupMenu followupMenu,
    String preferredOptionId = '',
  }) {
    final cleanPreferred = preferredOptionId.trim();
    if (cleanPreferred.isNotEmpty &&
        optionById(followupMenu: followupMenu, optionId: cleanPreferred) !=
            null) {
      return cleanPreferred;
    }
    final highlighted = followupMenu.highlightedOptionId.trim();
    if (highlighted.isNotEmpty &&
        optionById(followupMenu: followupMenu, optionId: highlighted) != null) {
      return highlighted;
    }
    for (final group in followupMenu.groups) {
      if (group.options.isNotEmpty) {
        return group.options.first.id;
      }
    }
    return '';
  }

  BookDeconstructionFollowupOption? optionById({
    required BookDeconstructionFollowupMenu followupMenu,
    required String optionId,
  }) {
    final cleanId = optionId.trim();
    if (cleanId.isEmpty) {
      return null;
    }
    for (final group in followupMenu.groups) {
      for (final option in group.options) {
        if (option.id == cleanId) {
          return option;
        }
      }
    }
    return null;
  }
}
