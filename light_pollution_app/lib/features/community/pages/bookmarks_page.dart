import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/l10n/app_localizations.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/community_provider.dart';
import '../widgets/sky_post_card.dart';
import 'post_detail_page.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final font = AppFonts.style(context);
    final postsAsync = ref.watch(postsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        title: Text(
          l10n.bookmarks,
          style: font(
            color: AppColors.text(context),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: AppColors.icon(context)),
        ),
      ),
      body: postsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.navy),
        ),
        error: (e, _) => Center(
          child: Text(
            '$e',
            style: font(color: AppColors.textSub(context)),
          ),
        ),
        data: (posts) {
          final bookmarked = posts.where((p) => p.isBookmarked).toList();
          if (bookmarked.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: AppColors.textSub(context),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noBookmarksYet,
                    style: font(
                      color: AppColors.text(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.noBookmarksDesc,
                    style: font(
                      color: AppColors.textSub(context),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: bookmarked.length,
            itemBuilder: (context, index) {
              final post = bookmarked[index];
              return SkyPostCard(
                post: post,
                onLike: () =>
                    ref.read(communityProvider.notifier).toggleLike(post.id),
                onComment: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
                ),
                onRepost: () =>
                    ref.read(communityProvider.notifier).toggleRepost(post.id),
                onBookmark: () =>
                    ref.read(communityProvider.notifier).toggleBookmark(post.id),
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                      builder: (_) => PostDetailPage(postId: post.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
