import '../../community/models/community_models.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.timestamp,
    this.isRead = true,
  });

  final String id;
  final String text;
  final String senderId;
  final DateTime timestamp;
  final bool isRead;
}

class Conversation {
  Conversation({
    required this.id,
    required this.otherUser,
    required List<ChatMessage> messages,
    this.unreadCount = 0,
    this.isRequest = false,
  }) : messages = List.from(messages);

  final String id;
  final MockUser otherUser;
  final List<ChatMessage> messages;
  int unreadCount;
  /// True when the current user hasn't accepted this thread yet — surfaced
  /// in the Message Requests folder rather than the main inbox.
  final bool isRequest;

  ChatMessage get lastMessage => messages.last;

  String get lastMessageTime {
    final diff = DateTime.now().difference(lastMessage.timestamp);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }

  void addMessage(ChatMessage message) {
    messages.add(message);
  }

  void markAsRead() {
    unreadCount = 0;
  }
}
