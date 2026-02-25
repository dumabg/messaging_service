class MessagingException implements Exception {
  final String message;

  MessagingException(this.message);
  @override
  String toString() {
    return message;
  }
}
