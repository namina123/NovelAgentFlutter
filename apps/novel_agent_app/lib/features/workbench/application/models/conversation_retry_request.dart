class ConversationRetryRequest {
  const ConversationRetryRequest({
    required this.prompt,
    required this.visibleText,
    this.errorMessage = '',
    this.label = '重试上次失败请求',
  });

  final String prompt;
  final String visibleText;
  final String errorMessage;
  final String label;
}
