import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/smart_image.dart';
import '../../community/widgets/verified_badge.dart';
import '../../community/pages/user_profile_page.dart';
import '../models/chat_models.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({
    super.key,
    required this.conversation,
  });

  final Conversation conversation;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestore = FirestoreService();
  List<ChatMessage> _messages = [];
  StreamSubscription? _messagesSub;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.conversation.markAsRead();
    _markRemoteRead();
    _listenToMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _markRemoteRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    // Fire-and-forget: any failure here should not block the chat UI.
    try {
      await _firestore.markConversationAsRead(widget.conversation.id, uid);
    } catch (_) {}
  }

  void _listenToMessages() {
    _messagesSub = _firestore.messagesStream(widget.conversation.id).listen(
      (msgDocs) {
        final msgs = msgDocs.map((doc) {
          final ts = doc['timestamp'];
          final timestamp = ts is Timestamp ? ts.toDate() : DateTime.now();
          return ChatMessage(
            id: doc['id'] as String,
            text: doc['text'] as String? ?? '',
            senderId: doc['senderId'] as String? ?? '',
            timestamp: timestamp,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _messages = msgs;
            _error = null;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _error = 'Could not load messages: $e');
        }
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSub?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _messageController.clear();

    try {
      await _firestore.sendMessage(widget.conversation.id, {
        'text': text,
        'senderId': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
      // Stream listener will update _messages.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send: $e')),
        );
        // Put the text back so the user can retry.
        _messageController.text = text;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final user = widget.conversation.otherUser;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'me';

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.icon(context)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => UserProfilePage(user: user)),
          ),
          child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.navy,
              child: user.avatarUrl != null
                  ? ClipOval(
                      child: SmartImage(
                        url: user.avatarUrl!,
                        width: 32,
                        height: 32,
                        fallback: Text(
                          user.avatarInitials,
                          style: font(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      user.avatarInitials,
                      style: font(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user.name,
                          style: font(
                            color: AppColors.text(context),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        VerifiedBadge(size: 14, isAdmin: user.isAdmin),
                      ],
                    ],
                  ),
                  Text(
                    user.username,
                    style: font(color: AppColors.textSub(context), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: AppColors.icon(context), size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Divider(height: 1, color: AppColors.div(context)),

          // Messages
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: font(color: AppColors.textSub(context), fontSize: 14),
                      ),
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Send a message to start the conversation',
                          style: font(color: AppColors.textSub(context), fontSize: 15),
                        ),
                      )
                    : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == uid || msg.senderId == 'me';
                      final showAvatar = !isMe &&
                          (index == 0 || (_messages[index - 1].senderId == uid || _messages[index - 1].senderId == 'me'));

                      return _MessageBubble(
                        message: msg,
                        isMe: isMe,
                        showAvatar: showAvatar,
                        user: user,
                      );
                    },
                  ),
          ),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              border: Border(
                top: BorderSide(color: AppColors.div(context), width: 0.5),
              ),
            ),
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image_outlined, color: AppColors.navy, size: 24),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.div(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: font(fontSize: 15, color: AppColors.text(context)),
                            maxLines: 4,
                            minLines: 1,
                            textInputAction: TextInputAction.newline,
                            decoration: InputDecoration(
                              hintText: 'Start a new message',
                              hintStyle: font(fontSize: 15, color: AppColors.hint(context)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(Icons.send_rounded, color: AppColors.navy, size: 24),
                  onPressed: _sendMessage,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.user,
  });

  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    // Skip empty placeholder messages
    if (message.text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.navy,
                child: user.avatarUrl != null
                    ? ClipOval(
                        child: SmartImage(
                          url: user.avatarUrl!,
                          width: 28,
                          height: 28,
                          fallback: Text(
                            user.avatarInitials,
                            style: font(
                              color: AppColors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        user.avatarInitials,
                        style: font(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.navy : AppColors.card(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Text(
                message.text,
                style: font(
                  color: isMe ? AppColors.white : AppColors.text(context),
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 36),
        ],
      ),
    );
  }
}
