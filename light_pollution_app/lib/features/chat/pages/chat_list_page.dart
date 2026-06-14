import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/smart_image.dart';
import '../../community/models/community_models.dart';
import '../models/chat_models.dart';
import '../../community/widgets/verified_badge.dart';
import 'chat_detail_page.dart';
import 'message_requests_page.dart';
import 'message_settings_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _searchController = TextEditingController();
  String _query = '';
  final _firestore = FirestoreService();
  List<Conversation> _conversations = [];
  StreamSubscription? _conversationsSub;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'You must be signed in to see messages.');
      return;
    }

    _conversationsSub = _firestore.conversationsStream(uid).listen(
      (convDocs) async {
        try {
          final convs = <Conversation>[];
          for (final doc in convDocs) {
            final convId = doc['id'] as String;
            final participants = List<String>.from(doc['participants'] ?? []);
            // For a "note to self" conversation, all participants are the
            // current user — resolve the "other user" to the current user so
            // the tile renders with their own avatar and name.
            final otherUserId = participants.firstWhere(
              (p) => p != uid,
              orElse: () => uid,
            );

            final otherUser = await _firestore.getUser(otherUserId) ??
                MockUser(
                  id: otherUserId,
                  name: 'Unknown',
                  username: '@unknown',
                  avatarInitials: '?',
                  bio: '',
                );

            final lastMsg = doc['lastMessage'] as String? ?? '';
            final lastMsgAt = doc['lastMessageAt'];
            final timestamp = lastMsgAt is Timestamp ? lastMsgAt.toDate() : DateTime.now();
            // Unread count is best-effort: if it fails we still want the
            // conversation to appear in the list.
            int unread = 0;
            try {
              unread = await _firestore.getUnreadMessagesCount(convId, uid);
            } catch (_) {}

            // A conversation is a "request" for the current user when
            // they aren't yet in the acceptedBy array. Self-DMs and
            // freshly created threads (where the seed already includes
            // the user) skip this state, so the existing inbox UX is
            // preserved.
            final acceptedBy = List<String>.from(doc['acceptedBy'] ?? const []);
            final isRequest = !acceptedBy.contains(uid);

            convs.add(Conversation(
              id: convId,
              otherUser: otherUser,
              unreadCount: unread,
              isRequest: isRequest,
              messages: lastMsg.isNotEmpty
                  ? [
                      ChatMessage(
                        id: 'last',
                        text: lastMsg,
                        senderId: doc['lastMessageSenderId'] as String? ?? '',
                        timestamp: timestamp,
                      ),
                    ]
                  : [],
            ));
          }

          if (mounted) {
            setState(() {
              _conversations = convs;
              _error = null;
              _loading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _error = 'Could not load messages: $e';
              _loading = false;
            });
          }
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _error = 'Could not load messages: $e';
            _loading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _conversationsSub?.cancel();
    super.dispose();
  }

  /// Conversations the current user has accepted — what shows up in the
  /// main inbox list (filtered by the search query).
  List<Conversation> get _filteredConversations {
    final accepted = _conversations.where((c) => !c.isRequest).toList();
    if (_query.isEmpty) return accepted;
    final q = _query.toLowerCase();
    return accepted.where((c) {
      return c.otherUser.name.toLowerCase().contains(q) ||
          c.otherUser.username.toLowerCase().contains(q) ||
          (c.messages.isNotEmpty && c.lastMessage.text.toLowerCase().contains(q));
    }).toList();
  }

  /// Pending message requests. Search doesn't apply here — the dedicated
  /// page surfaces them in full.
  List<Conversation> get _requestConversations =>
      _conversations.where((c) => c.isRequest).toList();

  Future<void> _startConversation(MockUser user) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final convId = await _firestore.getOrCreateConversation(uid, user.id);
      if (!mounted) return;
      final conv = Conversation(
        id: convId,
        otherUser: user,
        messages: [],
      );
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => ChatDetailPage(conversation: conv)),
      );
    } catch (e) {
      if (mounted) {
        // Surface the block guard with a friendlier message than the
        // raw StateError; everything else falls through to the default.
        final message = (e is StateError && e.message == 'blocked')
            ? 'You can\'t message this account.'
            : 'Could not start conversation: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  void _showNewMessageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (ctx, scrollController) => _NewMessageSheet(
          scrollController: scrollController,
          onUserSelected: (user) {
            Navigator.pop(ctx);
            _startConversation(user);
          },
        ),
      ),
    );
  }

  Future<void> _deleteConversation(Conversation conv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Delete your conversation with ${conv.otherUser.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestore.deleteConversation(conv.id);
      // Stream will update the list automatically.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final filtered = _filteredConversations;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Messages',
          style: font(
            color: AppColors.text(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.icon(context), size: 22),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MessageSettingsPage()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'chatFab',
        onPressed: () => _showNewMessageSheet(context),
        backgroundColor: AppColors.navy,
        shape: const CircleBorder(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.chat_bubble, color: AppColors.white, size: 26),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: AppColors.navy, size: 12),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.div(context)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search, color: AppColors.hint(context), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: font(fontSize: 14, color: AppColors.text(context)),
                      decoration: InputDecoration(
                        hintText: 'Search Direct Messages',
                        hintStyle: font(fontSize: 14, color: AppColors.hint(context)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.close, color: AppColors.hint(context), size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Divider(height: 1, color: AppColors.div(context)),

          // Message Requests banner — only shown when there's at least one
          // pending request. Tap to open the dedicated page.
          if (_requestConversations.isNotEmpty)
            _MessageRequestsBanner(
              count: _requestConversations.length,
              onTap: () {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MessageRequestsPage(
                      requests: _requestConversations,
                      currentUserId: uid,
                    ),
                  ),
                );
              },
            ),

          // Conversations list or error / empty state
          Expanded(
            child: _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: font(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ),
                  )
                : _loading && _conversations.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.hint(context)),
                            const SizedBox(height: 12),
                            Text(
                              'No messages yet',
                              style: font(color: AppColors.textSub(context), fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap the + button to start a conversation',
                              style: font(color: AppColors.hint(context), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          indent: 76,
                          color: AppColors.div(context),
                        ),
                        itemBuilder: (context, index) {
                          final conv = filtered[index];
                          return Dismissible(
                            key: Key(conv.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              await _deleteConversation(conv);
                              return false; // We handle removal ourselves via the stream
                            },
                            child: _ConversationTile(
                              conversation: conv,
                              onTap: () {
                                Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailPage(conversation: conv),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ── New Message Sheet with search ──

class _NewMessageSheet extends StatefulWidget {
  const _NewMessageSheet({
    required this.scrollController,
    required this.onUserSelected,
  });

  final ScrollController scrollController;
  final void Function(MockUser user) onUserSelected;

  @override
  State<_NewMessageSheet> createState() => _NewMessageSheetState();
}

class _NewMessageSheetState extends State<_NewMessageSheet> {
  final _searchController = TextEditingController();
  final _firestore = FirestoreService();
  String _query = '';
  List<MockUser> _allUsers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _firestore.getAllUsers();
      if (!mounted) return;
      setState(() {
        // Show everyone — including the current user, so "note to self"
        // conversations work like X/Twitter's self DM.
        _allUsers = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load users: $e';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MockUser> get _filteredUsers {
    if (_query.isEmpty) return _allUsers;
    final q = _query.toLowerCase();
    return _allUsers.where((user) {
      return user.name.toLowerCase().contains(q) ||
          user.username.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final users = _filteredUsers;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'New Message',
                  style: font(
                    color: AppColors.navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search, color: AppColors.textHint, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: font(fontSize: 14, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search people...',
                        hintStyle: font(fontSize: 14, color: AppColors.textHint),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.close, color: AppColors.textHint, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // User list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: font(color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ),
                      )
                    : users.isEmpty
                        ? Center(
                            child: Text(
                              'No users found',
                              style: font(color: AppColors.textSecondary, fontSize: 15),
                            ),
                          )
                        : ListView.builder(
                            controller: widget.scrollController,
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.navy,
                                  child: user.avatarUrl != null
                                      ? ClipOval(
                                          child: SmartImage(
                                            url: user.avatarUrl!,
                                            width: 44,
                                            height: 44,
                                            fallback: Text(
                                              user.avatarInitials,
                                              style: font(
                                                color: AppColors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          user.avatarInitials,
                                          style: font(
                                            color: AppColors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        user.name,
                                        style: font(
                                          color: AppColors.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (user.isVerified) ...[
                                      const SizedBox(width: 4),
                                      VerifiedBadge(size: 16, isAdmin: user.isAdmin),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  user.username,
                                  style: font(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                onTap: () => widget.onUserSelected(user),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Conversation Tile ──

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final user = conversation.otherUser;
    final hasMessages = conversation.messages.isNotEmpty;
    final lastMsgText = hasMessages ? conversation.lastMessage.text : '';
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                style: font(
                                  color: AppColors.text(context),
                                  fontSize: 15,
                                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
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
                      ),
                      if (hasMessages) ...[
                        const SizedBox(width: 8),
                        Text(
                          conversation.lastMessageTime,
                          style: font(
                            color: hasUnread ? AppColors.navy : AppColors.hint(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsgText.isNotEmpty ? lastMsgText : 'Start a conversation',
                          style: font(
                            color: hasUnread ? AppColors.text(context) : AppColors.textSub(context),
                            fontSize: 14,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.navy,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// X-style banner that sits above the inbox list and links into the
/// pending Message Requests folder.
class _MessageRequestsBanner extends StatelessWidget {
  const _MessageRequestsBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.mail_outline, color: AppColors.navy, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Message requests',
                    style: font(
                      color: AppColors.text(context),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: font(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: AppColors.hint(context)),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: AppColors.div(context)),
      ],
    );
  }
}
