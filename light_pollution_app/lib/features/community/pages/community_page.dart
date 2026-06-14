import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/smart_image.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/pages/home_page.dart';
import '../providers/community_provider.dart';
import '../widgets/sky_post_card.dart';
import 'post_detail_page.dart';
import 'compose_post_page.dart';

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  // Drives the "tap logo → scroll to top + refresh" gesture. Parked here
  // so the behavior survives across rebuilds.
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Matches how X and Instagram respond to a tap on the top-bar logo:
  /// smooth-scroll to the top of the feed and refresh the stream so the
  /// newest posts show up without the user having to pull-to-refresh.
  void _refreshFeed() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
    ref.invalidate(postsStreamProvider);
    // Flash a brief confirmation so the tap is perceptible even when the
    // list is already at the top and the cached stream data hasn't changed.
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.refreshingFeed),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final postsAsync = ref.watch(postsStreamProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final homeScaffoldKey = ref.watch(homeScaffoldKeyProvider);
    final font = AppFonts.style(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => homeScaffoldKey.currentState?.openDrawer(),
          child: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Center(
              child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.navy,
                      ),
                      child: currentUser?.avatarUrl != null
                          ? ClipOval(
                              child: SmartImage(
                                url: currentUser!.avatarUrl!,
                                width: 32, height: 32,
                                fallback: Center(
                                  child: Text(
                                    currentUser.avatarInitials,
                                    style: font(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                currentUser?.avatarInitials ?? '',
                                style: font(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                    ),
            ),
          ),
        ),
        title: Material(
          color: Colors.transparent,
          child: InkWell(
            // Tap the logo to jump to the top of the feed and re-fetch —
            // same "home button" behaviour as X and Instagram. Using
            // InkWell over GestureDetector gives a visible ripple so the
            // user can tell the tap registered, and the padding expands
            // the hit target beyond the tight SVG bounds.
            onTap: _refreshFeed,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SvgPicture.asset(
                'assets/logo.svg',
                height: 36,
                colorFilter:
                    ColorFilter.mode(AppColors.icon(context), BlendMode.srcIn),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/map'),
            icon: Icon(Icons.explore_outlined, color: AppColors.icon(context)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const ComposePostPage()),
          );
        },
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${l10n.failedToLoadPosts}\n$e',
              textAlign: TextAlign.center,
              style: AppFonts.style(context)(color: AppColors.textSub(context)),
            ),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Text(
                l10n.noPostsYet,
                style: AppFonts.style(context)(color: AppColors.textSub(context)),
              ),
            );
          }
          final currentUser = ref.watch(currentUserProvider).valueOrNull;
          return RefreshIndicator(
            // Pull-to-refresh mirrors the logo-tap behaviour: resubscribe
            // to the posts stream so the newest posts land at the top.
            // We await a tiny delay so the spinner stays visible long
            // enough to feel responsive instead of flashing off instantly.
            onRefresh: () async {
              ref.invalidate(postsStreamProvider);
              await Future.delayed(const Duration(milliseconds: 600));
            },
            color: AppColors.navy,
            child: ListView.builder(
              controller: _scrollCtrl,
              // AlwaysScrollableScrollPhysics lets the user pull down even
              // when the list fits on one screen — otherwise the refresh
              // indicator wouldn't trigger on short feeds.
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: posts.length,
              itemBuilder: (context, index) {
              final post = posts[index];
              final isOwner = post.userId == currentUser?.id;
              // Look up quoted post if this is a quote post
              final quotedPost = post.quotedPostId != null
                  ? posts.where((p) => p.id == post.quotedPostId).firstOrNull
                  : null;
              // Show "You reposted" header if current user reposted this
              final repostedByName = (currentUser != null &&
                      post.userId != currentUser.id &&
                      post.isReposted)
                  ? 'You'
                  : null;
              return SkyPostCard(
                post: post,
                quotedPost: quotedPost,
                repostedByName: repostedByName,
                onLike: () => ref.read(communityProvider.notifier).toggleLike(post.id),
                onComment: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
                ),
                onRepost: () => ref.read(communityProvider.notifier).toggleRepost(post.id),
                onBookmark: () => ref.read(communityProvider.notifier).toggleBookmark(post.id),
                onDelete: isOwner
                    ? () => ref.read(communityProvider.notifier).deletePost(post.id)
                    : null,
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
                ),
              );
              },
            ),
          );
        },
      ),
    );
  }

}
