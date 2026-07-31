import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
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
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: colors.dangerSoftColor.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.dangerStrongColor.withValues(alpha: 0.38),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 15,
                color: colors.dangerStrongColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  // 中文注释: 去掉「请求」这类技术词，用人话点明是上一次生成没跑完、可以重试。
                  '上一次生成未完成，要重试吗？',
                  style: TextStyle(
                    color: surface.foregroundColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (retryRequest.errorMessage.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              retryRequest.errorMessage,
              style: TextStyle(
                color: colors.dangerStrongColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ActionButton(
            label: retryRequest.label,
            icon: Icons.refresh_rounded,
            tone: ActionButtonTone.danger,
            compact: true,
            onPressed: onRetryRequested,
          ),
        ],
      ),
    );
  }
}
