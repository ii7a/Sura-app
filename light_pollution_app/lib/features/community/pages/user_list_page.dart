import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:light_pollution_app/core/theme/app_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firestore_service.dart';
import '../models/community_models.dart';
import '../widgets/verified_badge.dart';
import 'user_profile_page.dart';

/// A simple list screen used for "Followers" and "Following" — takes a future
/// of [MockUser]s and renders them as tappable rows that open
/// [UserProfilePage] for each one.
class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({
    super.key,
    required this.title,
    required this.loader,
  });

  final String title;
  final Future<List<MockUser>> Function(FirestoreService firestore) loader;

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends ConsumerState<UserListPage> {
  late Future<List<MockUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.loader(FirestoreService());
  }

  @override
  Widget build(BuildContext context) {
    final font = AppFonts.style(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.icon(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: font(
            color: AppColors.text(context),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<List<MockUser>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.navy),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: font(color: AppColors.textSub(context), fontSize: 14),
                ),
              ),
            );
          }
          final users = snapshot.data ?? const <MockUser>[];
          if (users.isEmpty) {
            return Center(
              child: Text(
                'No users',
                style: font(color: AppColors.textSub(context), fontSize: 15),
              ),
            );
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              indent: 76,
              color: AppColors.div(context),
            ),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.navy,
                  child: user.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user.avatarUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Text(
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
                          color: AppColors.text(context),
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
                  style: font(color: AppColors.textSub(context), fontSize: 13),
                ),
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (_) => UserProfilePage(user: user),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
