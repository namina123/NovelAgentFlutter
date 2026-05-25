class ConversationRetryRequest {
  const ConversationRetryRequest({
    required this.prompt,
    required this.visibleText,
    this.errorMessage = '',
  });

  final String prompt;
  final String visibleText;
  final String errorMessage;
}
