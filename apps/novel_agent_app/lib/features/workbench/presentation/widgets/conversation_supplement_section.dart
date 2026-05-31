import 'package:flutter/material.dart';

class ConversationSupplementSection extends StatelessWidget {
  const ConversationSupplementSection({
    super.key,
    required this.child,
    this.title = '补充说明',
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
