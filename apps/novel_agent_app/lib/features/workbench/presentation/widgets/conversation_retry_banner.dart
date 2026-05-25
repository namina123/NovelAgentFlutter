import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../models/retry_request_view_data.dart';

class ConversationRetryBanner extends StatelessWidget {
  const ConversationRetryBanner({
    super.key,
    required this.retryRequest,
    required this.onRetryRequested,
  });

  final RetryRequestViewData retryRequest;
  final VoidCallback onRetryRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 重试横幅只承接“重新发起上一轮失败请求”的入口，不关心具体会话和模型状态。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (retryRequest.errorMessage.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              retryRequest.errorMessage,
              style: const TextStyle(
                color: Color(0xFF9C3C30),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ActionButton(
          label: retryRequest.label,
          icon: Icons.refresh_rounded,
          compact: true,
          expanded: true,
          onPressed: onRetryRequested,
        ),
      ],
    );
  }
}
