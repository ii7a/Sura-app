import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/widgets/smart_image.dart';
import '../../community/models/community_models.dart';
import '../../community/providers/community_provider.dart';
import '../../community/widgets/sky_post_card.dart';
import '../../community/widgets/comments_sheet.dart';
import '../../chat/models/chat_models.dart';
import '../../chat/pages/chat_detail_page.dart';
import '../../community/widgets/verified_badge.dart';
import '../../community/pages/post_detail_page.dart';
import '../../community/pages/user_profile_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String _query = '';
  List<MockUser> _allUsers = const [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await FirestoreService().getAllUsers();
      if (!mounted) return;
      setState(() => _allUsers = users);
    } catch (_) {
      // Leave _allUsers empty on error; the UI will render an empty state.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startDM(MockUser user) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final firestore = FirestoreService();
    try {
      final convId = await firestore.getOrCreateConversation(uid, user.id);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailPage(
            conversation: Conversation(id: convId, otherUser: user, messages: []),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start conversation: $e')),
        );
      }
    }
  }

  List<MockUser> _searchUsers(String query) {
    if (query.isEmpty) return _allUsers;
    final q = query.toLowerCase();
    return _allUsers.where((user) {
      return user.name.toLowerCase().contains(q) ||
          user.username.toLowerCase().contains(q) ||
          user.bio.toLowerCase().contains(q);
    }).toList();
  }

  List<SkyPost> _searchPosts(String query, List<SkyPost> allPosts) {
    if (query.isEmpty) return allPosts;
    final q = query.toLowerCase();
    return allPosts.where((post) {
      return post.caption.toLowerCase().contains(q) ||
          post.user.name.toLowerCase().contains(q) ||
          (post.location?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);
    final postsAsync = ref.watch(postsStreamProvider);
    final isSearching = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.div(context)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search, color: AppColors.hint(context), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        style: font(fontSize: 15.0, color: AppColors.text(context)),
                        decoration: InputDecoration(
                          hintText: 'Search users, posts, locations...',
                          hintStyle: font(fontSize: 15.0, color: AppColors.hint(context)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (isSearching)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.close, color: AppColors.hint(context), size: 18),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (isSearching) ...[
              // Search mode: tabs + results
              TabBar(
                controller: _tabController,
                labelColor: AppColors.icon(context),
                unselectedLabelColor: AppColors.textSub(context),
                indicatorColor: AppColors.navy,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: font(fontSize: 14.0, fontWeight: FontWeight.w600),
                unselectedLabelStyle: font(fontSize: 14.0, fontWeight: FontWeight.w400),
                tabs: const [Tab(text: 'People'), Tab(text: 'Posts')],
              ),
              Divider(height: 1, color: AppColors.div(context)),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildPeopleTab(font), _buildPostsTab(postsAsync, font)],
                ),
              ),
            ] else ...[
              // Discover mode: news, trends, people
              Expanded(child: _buildDiscoverView(font)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Discover View (when not searching) ──

  Widget _buildDiscoverView(dynamic font) {
    final featuredUsers = _allUsers.where((u) => u.isVerified).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // Astronomy News
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Text('Astronomy News', style: font(color: AppColors.text(context), fontSize: 18.0, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _NewsCard(
                icon: Icons.rocket_launch,
                title: "Saturn's rings will disappear from view in 2025 due to orbital tilt",
                source: 'NASA',
                gradient: [const Color(0xFF0a0a2e), const Color(0xFF1a1a4e)],
              ),
              const SizedBox(width: 12),
              _NewsCard(
                icon: Icons.public,
                title: 'James Webb Telescope discovers high-redshift galaxies challenging models',
                source: 'ESA',
                gradient: [const Color(0xFF0d1b2a), const Color(0xFF1b2838)],
              ),
              const SizedBox(width: 12),
              _NewsCard(
                icon: Icons.nightlight_round,
                title: 'Total lunar eclipse visible across Middle East on September 2025',
                source: 'Sky & Telescope',
                gradient: [const Color(0xFF1a0a2e), const Color(0xFF2d1b4e)],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Trending Topics
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Text('Trending Topics', style: font(color: AppColors.text(context), fontSize: 18.0, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              '#MilkyWay', '#Astrophotography', '#DarkSky',
              '#Bortle1', '#StarTrail', '#LunarEclipse',
              '#NightSky', '#Stargazing', '#Nebula', '#AlUla',
              '#LightPollution', '#Telescope',
            ].map((tag) => _TopicChip(
              label: tag,
              onTap: () {
                _searchController.text = tag.substring(1);
                setState(() => _query = tag.substring(1));
              },
            )).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // People
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.people_outline, color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              Text('People', style: font(color: AppColors.text(context), fontSize: 18.0, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...featuredUsers.map((user) => _buildUserTile(user, font)),
      ],
    );
  }

  // ── Search Results ──

  Widget _buildPeopleTab(dynamic font) {
    final users = _searchUsers(_query);
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 48, color: AppColors.hint(context)),
            const SizedBox(height: 12),
            Text('No users found', style: font(color: AppColors.textSub(context), fontSize: 16.0)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) => _buildUserTile(users[index], font),
    );
  }

  Widget _buildUserTile(MockUser user, dynamic font) {
    return InkWell(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => UserProfilePage(user: user)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.navy,
              child: user.avatarUrl != null
                  ? ClipOval(child: SmartImage(url: user.avatarUrl!, width: 48, height: 48,
                      fallback: Text(user.avatarInitials, style: font(color: AppColors.white, fontSize: 14.0, fontWeight: FontWeight.w700))))
                  : Text(user.avatarInitials, style: font(color: AppColors.white, fontSize: 14.0, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(user.name, style: font(color: AppColors.text(context), fontSize: 15.0, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                      if (user.isVerified) ...[const SizedBox(width: 4), VerifiedBadge(size: 16, isAdmin: user.isAdmin)],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.username, style: font(color: AppColors.textSub(context), fontSize: 13.0)),
                  const SizedBox(height: 4),
                  Text(user.bio, style: font(color: AppColors.textSub(context), fontSize: 13.0), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.mail_outline, color: AppColors.icon(context), size: 22),
              onPressed: () => _startDM(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab(AsyncValue<List<SkyPost>> postsAsync, dynamic font) {
    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.navy)),
      error: (e, _) => Center(child: Text('Failed to load posts', style: font(color: AppColors.textSub(context)))),
      data: (posts) {
        final filtered = _searchPosts(_query, posts);
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 48, color: AppColors.hint(context)),
                const SizedBox(height: 12),
                Text('No posts found', style: font(color: AppColors.textSub(context), fontSize: 16.0)),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final post = filtered[index];
            return SkyPostCard(
              post: post,
              onLike: () => ref.read(communityProvider.notifier).toggleLike(post.id),
              onComment: () => _showComments(context, post),
              onDelete: () => ref.read(communityProvider.notifier).deletePost(post.id),
              onTap: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
              ),
            );
          },
        );
      },
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
}

// ── News Card ──

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.icon, required this.title, required this.source, required this.gradient});
  final IconData icon;
  final String title;
  final String source;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(source, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Topic Chip ──

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.div(context)),
          color: AppColors.card(context),
        ),
        child: Text(
          label,
          style: AppFonts.style(context)(color: AppColors.text(context), fontSize: 13.0, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
