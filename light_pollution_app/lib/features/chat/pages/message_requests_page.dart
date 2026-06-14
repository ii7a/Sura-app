import 'package:flutter/material.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/smart_image.dart';
import '../../community/widgets/verified_badge.dart';
import '../models/chat_models.dart';
import 'chat_detail_page.dart';

/// X-style "Message Requests" inbox. Lists conversations the current user
/// hasn't accepted yet and lets them accept or decline each one inline.
class MessageRequestsPage extends StatefulWidget {
  const MessageRequestsPage({
    super.key,
    required this.requests,
    required this.currentUserId,
  });

  final List<Conversation> requests;
  final String currentUserId;

  @override
  State<MessageRequestsPage> createState() => _MessageRequestsPageState();
}

class _MessageRequestsPageState extends State<MessageRequestsPage> {
  final _firestore = FirestoreService();
  late List<Conversation> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.requests);
  }

  Future<void> _accept(Conversation conv) async {
    try {
      await _firestore.acceptMessageRequest(conv.id, widget.currentUserId);
      if (!mounted) return;
      setState(() => _items.removeWhere((c) => c.id == conv.id));
      // Drop straight into the chat once accepted, matching X.
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatDetailPage(conversation: conv)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not accept: $e')),
        );
      }
    }
  }

  Future<void> _decline(Conversation conv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline request'),
        content: Text('Decline the message request from ${conv.otherUser.name}? The conversation will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _firestore.declineMessageRequest(conv.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((c) => c.id == conv.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not decline: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.icon(context)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Message requests',
          style: font(
            color: AppColors.text(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: AppColors.hint(context)),
                  const SizedBox(height: 12),
                  Text(
                    'No message requests',
                    style: font(color: AppColors.textSub(context), fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 76,
                color: AppColors.div(context),
              ),
              itemBuilder: (context, index) {
                final conv = _items[index];
                return _RequestTile(
                  conversation: conv,
                  onAccept: () => _accept(conv),
                  onDecline: () => _decline(conv),
                );
              },
            ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.conversation,
    required this.onAccept,
    required this.onDecline,
  });

  final Conversation conversation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final user = conversation.otherUser;
    final hasMessages = conversation.messages.isNotEmpty;
    final preview = hasMessages ? conversation.lastMessage.text : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.navy,
                child: user.avatarUrl != null
                    ? ClipOval(
                        child: SmartImage(
                          url: user.avatarUrl!,
                          width: 48,
                          height: 48,
                          fallback: Text(
                            user.avatarInitials,
                            style: font(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        user.avatarInitials,
                        style: font(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
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
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          VerifiedBadge(size: 16, isAdmin: user.isAdmin),
                        ],
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            user.username,
                            style: font(color: AppColors.textSub(context), fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        style: font(color: AppColors.textSub(context), fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDecline,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: Text(
                  'Decline',
                  style: font(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Accept',
                  style: font(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
