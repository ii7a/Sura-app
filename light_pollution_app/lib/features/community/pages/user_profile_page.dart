import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/smart_image.dart';
import '../../notifications/models/notification_model.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import '../widgets/sky_post_card.dart';
import '../widgets/comments_sheet.dart';
import '../widgets/reply_card.dart';
import '../widgets/verified_badge.dart';
import 'post_detail_page.dart';
import 'user_list_page.dart';

/// Profile page for viewing ANY user (not the current user).
///
/// Visually mirrors [ProfilePage] but is view-only: no edit button, no way
/// to change the user's bio/avatar/banner, and posts can only be deleted
/// when the caller happens to own them (which only matters for the edge
/// case of navigating to your own profile through this page).
class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key, required this.user});

  final MockUser user;

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirestoreService();
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _block({required String myUid}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block ${widget.user.name}?'),
        content: const Text(
            'They will no longer be able to message you, and you won\'t see their posts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _firestore.blockUser(myUid, widget.user.id);
      // If we're following them, drop the follow edge as part of blocking.
      await _firestore.unfollowUser(myUid, widget.user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.user.name} blocked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not block: $e')),
        );
      }
    }
  }

  Future<void> _unblock({required String myUid}) async {
    try {
      await _firestore.unblockUser(myUid, widget.user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.user.name} unblocked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not unblock: $e')),
        );
      }
    }
  }

  Future<void> _toggleFollow({required String myUid, required bool currentlyFollowing}) async {
    if (_followBusy) return;
    setState(() => _followBusy = true);
    try {
      if (currentlyFollowing) {
        await _firestore.unfollowUser(myUid, widget.user.id);
        // Remove the old "started following you" notification so the user
        // doesn't see a stale entry after we un-followed.
        await _firestore.deleteNotification(
          recipientUid: widget.user.id,
          actorUid: myUid,
          type: NotificationType.follow,
        );
      } else {
        await _firestore.followUser(myUid, widget.user.id);
        final actor = await _firestore.getUser(myUid);
        if (actor != null) {
          await _firestore.createNotification(
            recipientUid: widget.user.id,
            actor: actor,
            type: NotificationType.follow,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update follow: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final user = widget.user;
    final postsAsync = ref.watch(postsStreamProvider);
    final posts = postsAsync.valueOrNull ?? [];
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    final userPosts = posts.where((p) => p.userId == user.id).toList();
    // Likes tab: sort by when *this* user liked each post, newest first.
    final likedPosts = posts.where((p) => p.likedBy.contains(user.id)).toList();
    likedPosts.sort((a, b) {
      final at = a.likedAt[user.id] ??
          a.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.likedAt[user.id] ??
          b.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    // Collect replies by this user across all posts, sorted newest first.
    final userReplies = <_ReplyInfo>[];
    for (final post in posts) {
      for (final comment in post.comments) {
        if (comment.userId == user.id) {
          userReplies.add(_ReplyInfo(post: post, comment: comment));
        }
      }
    }
    userReplies.sort((a, b) {
      final ad = a.comment.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.comment.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    // Photos tab: posts-with-images AND replies-with-images merged, newest first.
    final photoItems = <_PhotoItem>[
      ...userPosts
          .where((p) =>
              p.imageUrls.isNotEmpty ||
              p.imageFiles.isNotEmpty ||
              p.imageAssets.isNotEmpty)
          .map((p) => _PhotoItem.post(p)),
      ...userReplies
          .where((r) => r.comment.imageUrls.isNotEmpty)
          .map((r) => _PhotoItem.reply(r)),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final avatarUrl = user.avatarUrl;
    final bannerUrl = user.bannerUrl;
    final hasBanner = bannerUrl != null;

    // If the profile owner has blocked the current viewer, swap the page
    // for a minimal "account unavailable" screen so none of their content
    // (avatar, banner, posts, follow button) leaks. Owners viewing their
    // own profile via this route skip the check entirely.
    final blockedStream = (currentUid != null && currentUid != user.id)
        ? _firestore.isBlockedByStream(currentUid, user.id)
        : Stream.value(false);

    return StreamBuilder<bool>(
      stream: blockedStream,
      builder: (context, blockedSnap) {
        if (blockedSnap.data == true) {
          // X-style "blocked you" view: keep the public surface (banner,
          // avatar, name, username) but replace bio/follow/posts with a
          // single notice. Nothing tappable except the back button.
          return Scaffold(
            backgroundColor: AppColors.bg(context),
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: false,
                  expandedHeight: 280,
                  backgroundColor: hasBanner
                      ? AppColors.bg(context)
                      : const Color(0xFF0a0a2e),
                  leading: _BannerIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      children: [
                        Positioned.fill(
                          bottom: 50,
                          child: bannerUrl != null
                              ? SizedBox.expand(
                                  child: SmartImage(
                                    url: bannerUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fallback: _defaultBanner(),
                                  ),
                                )
                              : _defaultBanner(),
                        ),
                        Positioned(
                          left: 16,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.bg(context),
                                width: 4,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: AppColors.navy,
                              child: avatarUrl != null
                                  ? ClipOval(
                                      child: SmartImage(
                                        url: avatarUrl,
                                        width: 76,
                                        height: 76,
                                        fallback: Text(
                                          user.avatarInitials,
                                          style: font(
                                            color: AppColors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      user.avatarInitials,
                                      style: font(
                                        color: AppColors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user.name,
                                overflow: TextOverflow.ellipsis,
                                style: font(
                                  color: AppColors.text(context),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (user.isVerified) ...[
                              const SizedBox(width: 4),
                              VerifiedBadge(size: 20, isAdmin: user.isAdmin),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.username,
                          style: font(
                            color: AppColors.textSub(context),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.div(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You\'re blocked',
                                style: font(
                                  color: AppColors.text(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'You can\'t follow ${user.username} or see ${user.username}\'s posts.',
                                style: font(
                                  color: AppColors.textSub(context),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: false,
              expandedHeight: 280,
              backgroundColor: hasBanner ? AppColors.bg(context) : const Color(0xFF0a0a2e),
              leading: _BannerIconButton(
                icon: Icons.arrow_back,
                onTap: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (currentUid != null && currentUid != widget.user.id)
                  StreamBuilder<bool>(
                    stream: _firestore.isBlockedStream(currentUid, widget.user.id),
                    builder: (context, snap) {
                      final isBlocked = snap.data ?? false;
                      return PopupMenuButton<String>(
                        // Use a child so the menu trigger picks up the
                        // same translucent-circle treatment as the back
                        // arrow on the banner.
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.more_vert,
                              color: AppColors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        onSelected: (value) async {
                          if (value == 'block') {
                            await _block(myUid: currentUid);
                          } else if (value == 'unblock') {
                            await _unblock(myUid: currentUid);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: isBlocked ? 'unblock' : 'block',
                            child: Text(
                              isBlocked
                                  ? 'Unblock ${widget.user.name}'
                                  : 'Block ${widget.user.name}',
                              style: TextStyle(
                                color: isBlocked ? null : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // Banner
                    Positioned.fill(
                      bottom: 50,
                      child: bannerUrl != null
                          ? SizedBox.expand(
                              child: SmartImage(
                                url: bannerUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fallback: _defaultBanner(),
                              ),
                            )
                          : _defaultBanner(),
                    ),
                    Positioned(
                      left: 0, right: 0, bottom: 0, height: 50,
                      child: Container(color: AppColors.bg(context)),
                    ),
                    // Avatar
                    Positioned(
                      left: 16, bottom: 2,
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bg(context),
                          border: Border.all(color: AppColors.bg(context), width: 4),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.navy,
                          ),
                          child: avatarUrl != null
                              ? ClipOval(
                                  child: SmartImage(
                                    url: avatarUrl,
                                    width: 90, height: 90,
                                    fallback: _initials(user),
                                  ),
                                )
                              : _initials(user),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // User info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row with Follow/Following button on the right
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: font(
                                      color: AppColors.text(context),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              if (user.isVerified) ...[
                                const SizedBox(width: 4),
                                VerifiedBadge(size: 20, isAdmin: user.isAdmin),
                              ],
                            ],
                          ),
                        ),
                        if (currentUid != null && currentUid != user.id)
                          _FollowButton(
                            myUid: currentUid,
                            otherUid: user.id,
                            busy: _followBusy,
                            onToggle: _toggleFollow,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(user.username,
                        style: font(color: AppColors.textSub(context), fontSize: 14)),
                    const SizedBox(height: 10),
                    if (user.bio.isNotEmpty)
                      Text(user.bio,
                          style: font(
                              color: AppColors.text(context),
                              fontSize: 14,
                              height: 1.4)),
                    const SizedBox(height: 12),
                    _FollowStatsRow(userId: user.id, username: user.username),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Tab bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.navy,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.navy,
                  indicatorWeight: 3,
                  labelStyle: font(fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: font(fontSize: 14, fontWeight: FontWeight.w500),
                  tabs: [
                    Tab(text: l10n.posts),
                    Tab(text: l10n.repliesTab),
                    Tab(text: l10n.photos),
                    Tab(text: l10n.likesTab),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsList(userPosts, currentUid),
            _buildRepliesList(userReplies),
            _buildPhotosList(photoItems, currentUid),
            _buildPostsList(likedPosts, currentUid),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildPostsList(List<SkyPost> posts, String? currentUid) {
    if (posts.isEmpty) {
      return _buildEmptyTab(AppLocalizations.of(context)!.noPostsYetSimple);
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final isOwner = post.userId == currentUid;
        return SkyPostCard(
          post: post,
          onLike: () => ref.read(communityProvider.notifier).toggleLike(post.id),
          onComment: () => _showComments(context, post),
          onDelete: isOwner
              ? () => ref.read(communityProvider.notifier).deletePost(post.id)
              : null,
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
          ),
        );
      },
    );
  }

  Widget _buildRepliesList(List<_ReplyInfo> replies) {
    if (replies.isEmpty) {
      return _buildEmptyTab(AppLocalizations.of(context)!.noRepliesYet);
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: replies.length,
      itemBuilder: (context, index) => _replyEntry(replies[index]),
    );
  }

  Widget _buildPhotosList(List<_PhotoItem> items, String? currentUid) {
    if (items.isEmpty) {
      return _buildEmptyTab(AppLocalizations.of(context)!.noPostsYetSimple);
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final post = item.post;
        if (post != null) {
          final isOwner = post.userId == currentUid;
          return SkyPostCard(
            post: post,
            onLike: () => ref.read(communityProvider.notifier).toggleLike(post.id),
            onComment: () => _showComments(context, post),
            onDelete: isOwner
                ? () => ref.read(communityProvider.notifier).deletePost(post.id)
                : null,
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
            ),
          );
        }
        return _replyEntry(item.reply!);
      },
    );
  }

  /// Renders a reply with its parent post — used by both Replies and Photos
  /// tabs on the view-only profile.
  Widget _replyEntry(_ReplyInfo reply) {
    final font = AppFonts.style(context);
    return Container(
      color: AppColors.bg(context),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Icon(Icons.reply, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  'Replying to ${reply.post.user.username}',
                  style: font(color: AppColors.textHint, fontSize: 13),
                ),
              ],
            ),
          ),
          SkyPostCard(
            post: reply.post,
            onLike: () => ref.read(communityProvider.notifier).toggleLike(reply.post.id),
            onComment: () => _showComments(context, reply.post),
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => PostDetailPage(postId: reply.post.id)),
            ),
          ),
          // View-only on someone else's profile, so no delete on the reply.
          ReplyCard(
            comment: reply.comment,
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => PostDetailPage(postId: reply.post.id)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Text(message,
          style: AppFonts.style(context)(color: AppColors.textSub(context), fontSize: 15)),
    );
  }

  void _showComments(BuildContext context, SkyPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.3, maxChildSize: 0.9,
        builder: (context, scrollController) => CommentsSheet(post: post),
      ),
    );
  }

  Widget _defaultBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0a0a2e), Color(0xFF1a1a4e), Color(0xFF0d0d1a)],
        ),
      ),
    );
  }

  Widget _initials(MockUser user) {
    return Center(
      child: Text(
        user.avatarInitials,
        style: AppFonts.style(context)(
            color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// White icon over a translucent dark circle. Sits on top of profile
/// banners (which can be any color/brightness) and stays legible without
/// us having to color-pick the banner. Used for the back arrow and the
/// overflow menu in the profile app bar.
class _BannerIconButton extends StatelessWidget {
  const _BannerIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: AppColors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

class _ReplyInfo {
  final SkyPost post;
  final PostComment comment;
  _ReplyInfo({required this.post, required this.comment});
}

/// A single entry in the Photos tab — either a regular post that has an
/// image, or a reply that has an image attached. Sorted by [createdAt].
class _PhotoItem {
  _PhotoItem.post(SkyPost p)
      : post = p,
        reply = null,
        createdAt = p.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  _PhotoItem.reply(_ReplyInfo r)
      : post = null,
        reply = r,
        createdAt = r.comment.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  final SkyPost? post;
  final _ReplyInfo? reply;
  final DateTime createdAt;
}

/// Live Follow / Following button. Subscribes to the follow-edge doc so its
/// label updates as soon as the follow/unfollow write lands.
class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.myUid,
    required this.otherUid,
    required this.busy,
    required this.onToggle,
  });

  final String myUid;
  final String otherUid;
  final bool busy;
  final void Function({required String myUid, required bool currentlyFollowing}) onToggle;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    return StreamBuilder<bool>(
      stream: FirestoreService().isFollowingStream(myUid, otherUid),
      builder: (context, snapshot) {
        final following = snapshot.data ?? false;
        final label = following ? 'Following' : 'Follow';
        final bg = following ? AppColors.bg(context) : AppColors.navy;
        final fg = following ? AppColors.text(context) : AppColors.white;
        final borderColor = following ? AppColors.div(context) : Colors.transparent;
        return SizedBox(
          height: 32,
          child: OutlinedButton(
            onPressed: busy
                ? null
                : () => onToggle(myUid: myUid, currentlyFollowing: following),
            style: OutlinedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: fg,
              side: BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              minimumSize: Size.zero,
            ),
            child: busy
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Text(
                    label,
                    style: font(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// Live Following / Followers counts row. Tapping either label pushes a
/// [UserListPage] with the matching user list.
class _FollowStatsRow extends StatelessWidget {
  const _FollowStatsRow({required this.userId, required this.username});

  final String userId;
  final String username;

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Row(
      children: [
        _FollowStat(
          countStream: firestore.followingCountStream(userId),
          label: 'Following',
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => UserListPage(
                  title: '$username · Following',
                  loader: (fs) => fs.getFollowing(userId),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        _FollowStat(
          countStream: firestore.followersCountStream(userId),
          label: 'Followers',
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (_) => UserListPage(
                  title: '$username · Followers',
                  loader: (fs) => fs.getFollowers(userId),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _FollowStat extends StatelessWidget {
  const _FollowStat({
    required this.countStream,
    required this.label,
    required this.onTap,
  });

  final Stream<int> countStream;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: StreamBuilder<int>(
        stream: countStream,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$count',
                  style: font(
                      color: AppColors.text(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text(' $label',
                  style: font(color: AppColors.textSub(context), fontSize: 14)),
            ],
          );
        },
      ),
    );
  }
}
