import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/smart_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import '../widgets/sky_post_card.dart';
import '../widgets/reply_card.dart';
import '../widgets/verified_badge.dart';
import 'edit_profile_page.dart';
import 'compose_post_page.dart';
import 'post_detail_page.dart';
import 'user_list_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  Future<void> _openEditProfile() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );

    if (result != null && result['updated'] == true) {
      ref.invalidate(currentUserProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final postsAsync = ref.watch(postsStreamProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    final user = currentUserAsync.valueOrNull ??
        MockUser(
          id: '',
          name: l10n.loadingText,
          username: '@...',
          avatarInitials: '?',
          bio: '',
        );

    final posts = postsAsync.valueOrNull ?? [];
    // Posts tab: own posts + reposted posts, like X
    final ownPosts = posts.where((p) => p.userId == user.id).toList();
    final repostedPosts = posts
        .where((p) => p.userId != user.id && p.repostedBy.contains(user.id))
        .toList();
    final userPosts = [...ownPosts, ...repostedPosts];
    userPosts.sort((a, b) {
      final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    // Likes tab: sort by when *I* liked the post, newest first. Posts whose
    // like predates the timestamp map fall back to the post's own createdAt.
    final likedPosts = posts.where((p) => p.isLiked).toList();
    likedPosts.sort((a, b) {
      final at = a.likedAt[user.id] ??
          a.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.likedAt[user.id] ??
          b.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });

    // Collect all replies by current user across all posts, sorted newest first.
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

    // Photos tab: user's posts-with-images AND replies-with-images, merged
    // into one list sorted newest first.
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

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const ComposePostPage()),
          );
        },
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              pinned: false,
              expandedHeight: 280,
              backgroundColor: hasBanner ? AppColors.bg(context) : const Color(0xFF0a0a2e),
              leading: _BannerIconButton(
                icon: Icons.arrow_back,
                onTap: () {
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
              ),
              actions: [
                _BannerIconButton(
                  icon: Icons.edit_outlined,
                  onTap: _openEditProfile,
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
                    // White area below banner
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

            // Profile info
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user.name, style: font(color: AppColors.text(context), fontSize: 20, fontWeight: FontWeight.w800)),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          VerifiedBadge(size: 20, isAdmin: user.isAdmin),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(user.username, style: font(color: AppColors.textSub(context), fontSize: 14)),
                        if (user.isPrivate) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.lock, size: 14, color: AppColors.textSub(context)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (user.bio.isNotEmpty)
                      Text(user.bio, style: font(color: AppColors.text(context), fontSize: 14, height: 1.4)),
                    const SizedBox(height: 12),
                    if (user.id.isNotEmpty)
                      Row(
                        children: [
                          _ProfileFollowStat(
                            countStream: FirestoreService().followingCountStream(user.id),
                            label: 'Following',
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => UserListPage(
                                    title: '${user.username} · Following',
                                    loader: (fs) => fs.getFollowing(user.id),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          _ProfileFollowStat(
                            countStream: FirestoreService().followersCountStream(user.id),
                            label: 'Followers',
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => UserListPage(
                                    title: '${user.username} · Followers',
                                    loader: (fs) => fs.getFollowers(user.id),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
            _buildPostsList(userPosts, currentUser: user, allPosts: posts),
            _buildRepliesList(userReplies),
            _buildPhotosList(photoItems),
            _buildPostsList(
              likedPosts,
              emptyMessage: l10n.noLikesYet,
              currentUser: user,
              allPosts: posts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultBanner() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0a0a2e), Color(0xFF1a1a4e), Color(0xFF0d0d1a)],
            ),
          ),
        ),
        CustomPaint(painter: _BannerStarsPainter()),
      ],
    );
  }

  Widget _initials(MockUser user) {
    return Center(
      child: Text(
        user.avatarInitials,
        style: AppFonts.style(context)(color: AppColors.white, fontSize: 24.0, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildPostsList(
    List<SkyPost> posts, {
    String? emptyMessage,
    MockUser? currentUser,
    List<SkyPost>? allPosts,
  }) {
    if (posts.isEmpty) {
      return _buildEmptyTab(
          emptyMessage ?? AppLocalizations.of(context)!.noPostsYetSimple);
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        // Show "reposted by" header if this is someone else's post
        // that appears in the list because the user reposted it
        final isRepostEntry = currentUser != null &&
            post.userId != currentUser.id &&
            post.repostedBy.contains(currentUser.id);
        // Look up quoted post
        final quotedPost = post.quotedPostId != null && allPosts != null
            ? allPosts.where((p) => p.id == post.quotedPostId).firstOrNull
            : null;
        return SkyPostCard(
          post: post,
          quotedPost: quotedPost,
          repostedByName: isRepostEntry ? currentUser.name : null,
          onLike: () => ref.read(communityProvider.notifier).toggleLike(post.id),
          onComment: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
                ),
          onRepost: () => ref.read(communityProvider.notifier).toggleRepost(post.id),
          onBookmark: () => ref.read(communityProvider.notifier).toggleBookmark(post.id),
          onDelete: post.userId == currentUser?.id
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

  Widget _buildPhotosList(List<_PhotoItem> items) {
    if (items.isEmpty) {
      return _buildEmptyTab(AppLocalizations.of(context)!.noPhotosYet);
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final post = item.post;
        if (post != null) {
          return SkyPostCard(
            post: post,
            onLike: () =>
                ref.read(communityProvider.notifier).toggleLike(post.id),
            onComment: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
                ),
            onRepost: () => ref.read(communityProvider.notifier).toggleRepost(post.id),
            onBookmark: () => ref.read(communityProvider.notifier).toggleBookmark(post.id),
            onDelete: () =>
                ref.read(communityProvider.notifier).deletePost(post.id),
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
            ),
          );
        }
        return _replyEntry(item.reply!);
      },
    );
  }

  /// Renders a reply with its parent post, used by both the Replies tab and
  /// the Photos tab (when a reply carries an image attachment).
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
            onComment: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => PostDetailPage(postId: reply.post.id)),
                ),
            onRepost: () => ref.read(communityProvider.notifier).toggleRepost(reply.post.id),
            onBookmark: () => ref.read(communityProvider.notifier).toggleBookmark(reply.post.id),
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => PostDetailPage(postId: reply.post.id)),
            ),
          ),
          ReplyCard(
            comment: reply.comment,
            canDelete: true,
            onTap: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => PostDetailPage(postId: reply.post.id)),
            ),
            onDelete: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete reply?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(communityProvider.notifier).deleteComment(
                      reply.post.id,
                      reply.comment.id,
                    );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Text(message, style: AppFonts.style(context)(color: AppColors.textSub(context), fontSize: 15)),
    );
  }

}

/// Circular dark-tinted icon button for use over the profile banner.
/// Matches the style used on [UserProfilePage] so own-profile and other-user
/// profile screens look consistent regardless of banner brightness.
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

class _BannerStarsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    var hash = 42;
    for (int i = 0; i < 80; i++) {
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final x = (hash % size.width.toInt()).toDouble();
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final y = (hash % size.height.toInt()).toDouble();
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final brightness = 0.2 + (hash % 60) / 100.0;
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final radius = 0.4 + (hash % 15) / 15.0;
      paint.color = Colors.white.withValues(alpha: brightness);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    for (int i = 0; i < 5; i++) {
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final x = (hash % size.width.toInt()).toDouble();
      hash = ((hash * 1103515245) + 12345) & 0x7fffffff;
      final y = (hash % size.height.toInt()).toDouble();
      paint.color = Colors.white.withValues(alpha: 0.85);
      canvas.drawCircle(Offset(x, y), 1.8, paint);
      paint.color = Colors.white.withValues(alpha: 0.12);
      canvas.drawCircle(Offset(x, y), 4.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

class _ProfileFollowStat extends StatelessWidget {
  const _ProfileFollowStat({
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
