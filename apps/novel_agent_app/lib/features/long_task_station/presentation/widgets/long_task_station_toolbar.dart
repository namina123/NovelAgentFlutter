import 'package:flutter/material.dart';

class LongTaskStationToolbar extends StatelessWidget {
  const LongTaskStationToolbar({
    super.key,
    required this.title,
    required this.description,
    required this.supervisorStatusLabel,
    required this.onBackRequested,
    required this.onRefreshRequested,
  });

  final String title;
  final String description;
  final String supervisorStatusLabel;
  final VoidCallback onBackRequested;
  final VoidCallback onRefreshRequested;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: '返回工作台',
          onPressed: onBackRequested,
          icon: const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                '$description  $supervisorStatusLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: '刷新',
          onPressed: onRefreshRequested,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}
