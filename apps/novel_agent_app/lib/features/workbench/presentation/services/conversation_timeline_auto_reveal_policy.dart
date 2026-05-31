import '../models/conversation_timeline_snapshot.dart';

class ConversationTimelineAutoRevealPolicy {
  const ConversationTimelineAutoRevealPolicy();

  bool shouldAutoReveal({
    required ConversationTimelineSnapshot previous,
    required ConversationTimelineSnapshot current,
    required bool anchoredToLatest,
  }) {
    // 中文注释: 只有用户原本就停留在最新输出附近时，才自动追随新的流式内容和新增条目。
    if (!anchoredToLatest) {
      return false;
    }
    if (current.blockCount == 0) {
      return false;
    }
    if (previous.blockCount != current.blockCount) {
      return true;
    }
    return previous.lastBlockId != current.lastBlockId ||
        previous.lastBlockContentLength != current.lastBlockContentLength ||
        previous.lastBlockDetailLength != current.lastBlockDetailLength;
  }
}
