import 'package:flutter/material.dart';

class ConversationFullscreenHost extends StatelessWidget {
  const ConversationFullscreenHost({
    super.key,
    required this.isActive,
    required this.primaryChild,
    this.fullscreenChild,
  });

  final bool isActive;
  final Widget primaryChild;
  final Widget? fullscreenChild;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: isActive && fullscreenChild != null
          ? KeyedSubtree(
              key: const ValueKey('conversation_fullscreen_child'),
              child: fullscreenChild!,
            )
          : KeyedSubtree(
              key: const ValueKey('conversation_primary_child'),
              child: primaryChild,
            ),
    );
  }
}
