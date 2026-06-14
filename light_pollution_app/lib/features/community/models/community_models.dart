import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class MockUser {
  const MockUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarInitials,
    required this.bio,
    this.isVerified = false,
    this.isAdmin = false,
    this.avatarUrl,
    this.bannerUrl,
    this.phone,
    this.email,
    this.location,
    this.birthDate,
    this.isPrivate = false,
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.dmSetting = 'everyone',
    this.likesVisibility = 'everyone',
    this.locationInfo = true,
  });

  final String id;
  final String name;
  final String username;
  final String avatarInitials;
  final String bio;
  /// Verified users get the blue verified badge AND can create trips,
  /// appear in the Featured Users section of search, and unlock
  /// premium-tier privileges. Admin controls this flag via Firestore.
  final bool isVerified;
  final bool isAdmin;
  final String? avatarUrl;
  final String? bannerUrl;
  /// Contact phone number the user optionally provides in Edit Profile.
  /// Surfaced to trip creators when the user books one of their trips.
  final String? phone;
  /// Sign-in email captured at signup time. Not publicly browsable — only
  /// trip creators see the emails of users who booked their trips.
  final String? email;
  /// Free-form location string the user types in Edit Profile (e.g.
  /// "Riyadh, Saudi Arabia"). Optional.
  final String? location;
  /// Birth date stored as ISO 8601 string (YYYY-MM-DD). Optional.
  final String? birthDate;
  // ── Settings ──
  final bool isPrivate;
  final bool pushNotifications;
  final bool emailNotifications;
  /// "everyone", "followers", "none"
  final String dmSetting;
  /// "everyone", "onlyMe"
  final String likesVisibility;
  final bool locationInfo;

  /// Admin users have full privileges: create/edit/delete trips, manage all posts.
  /// Verified users can create trips and show a verified badge.
  bool get hasFullAccess => isAdmin;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'avatarInitials': avatarInitials,
      'bio': bio,
      'isVerified': isVerified,
      'isAdmin': isAdmin,
      'avatarUrl': avatarUrl,
      'bannerUrl': bannerUrl,
      'phone': phone,
      'email': email,
      'location': location,
      'birthDate': birthDate,
      'isPrivate': isPrivate,
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'dmSetting': dmSetting,
      'likesVisibility': likesVisibility,
      'locationInfo': locationInfo,
    };
  }

  factory MockUser.fromMap(String id, Map<String, dynamic> map) {
    // Validate local file paths — discard if file doesn't exist
    String? validUrl(String? url) {
      if (url == null) return null;
      if (url.startsWith('/') && !File(url).existsSync()) return null;
      return url;
    }

    final username = map['username'] ?? '';
    // Sura official account always gets full privileges
    final isSura = username == '@Suraapp' || username == '@sura_ksa';

    return MockUser(
      id: id,
      name: map['name'] ?? '',
      username: username,
      avatarInitials: map['avatarInitials'] ?? '',
      bio: map['bio'] ?? '',
      // Treat legacy premium accounts as verified so existing users keep
      // their trip-creation access after the premium tier was merged in.
      isVerified: isSura || (map['isVerified'] ?? false) || (map['isPremium'] ?? false),
      isAdmin: isSura || (map['isAdmin'] ?? false),
      avatarUrl: validUrl(map['avatarUrl']),
      bannerUrl: validUrl(map['bannerUrl']),
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      location: map['location'] as String?,
      birthDate: map['birthDate'] as String?,
      isPrivate: map['isPrivate'] ?? false,
      pushNotifications: map['pushNotifications'] ?? true,
      emailNotifications: map['emailNotifications'] ?? false,
      dmSetting: map['dmSetting'] ?? 'everyone',
      likesVisibility: map['likesVisibility'] ?? 'everyone',
      locationInfo: map['locationInfo'] ?? true,
    );
  }

  MockUser copyWith({
    String? id,
    String? name,
    String? username,
    String? avatarInitials,
    String? bio,
    bool? isVerified,
    bool? isAdmin,
    String? avatarUrl,
    String? bannerUrl,
    String? phone,
    String? email,
    String? location,
    String? birthDate,
    bool? isPrivate,
    bool? pushNotifications,
    bool? emailNotifications,
    String? dmSetting,
    String? likesVisibility,
    bool? locationInfo,
  }) {
    return MockUser(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      isAdmin: isAdmin ?? this.isAdmin,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      birthDate: birthDate ?? this.birthDate,
      isPrivate: isPrivate ?? this.isPrivate,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      dmSetting: dmSetting ?? this.dmSetting,
      likesVisibility: likesVisibility ?? this.likesVisibility,
      locationInfo: locationInfo ?? this.locationInfo,
    );
  }
}

class SkyPost {
  SkyPost({
    required this.id,
    required this.user,
    required this.caption,
    required this.imageAssets,
    required this.timeAgo,
    required this.likes,
    required this.comments,
    this.reposts = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isReposted = false,
    this.location,
    this.bortleClass,
    this.skyQuality,
    this.qualityLabel,
    this.imageFiles = const [],
    this.imageUrls = const [],
    this.likedBy = const [],
    this.likedAt = const {},
    this.bookmarkedBy = const [],
    this.repostedBy = const [],
    this.userId = '',
    this.createdAt,
    this.quotedPostId,
  });

  final String id;
  final MockUser user;
  final String caption;
  final List<String> imageAssets;
  final List<dynamic> imageFiles;
  final List<String> imageUrls;
  final String timeAgo;
  int likes;
  final int reposts;
  final List<PostComment> comments;
  bool isLiked;
  bool isBookmarked;
  bool isReposted;
  final String? location;
  final int? bortleClass;
  final int? skyQuality;
  final String? qualityLabel;
  final List<String> likedBy;
  /// Map of userId -> when that user liked this post (server timestamp at
  /// the moment of the toggle). Null entries mean the like was recorded
  /// before this map was introduced.
  final Map<String, DateTime?> likedAt;
  final List<String> bookmarkedBy;
  final List<String> repostedBy;
  final String userId;
  final DateTime? createdAt;
  final String? quotedPostId;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'caption': caption,
      'imageAssets': imageAssets,
      'imageUrls': imageUrls,
      'likes': likes,
      'reposts': reposts,
      'location': location,
      'bortleClass': bortleClass,
      'skyQuality': skyQuality,
      'qualityLabel': qualityLabel,
      'likedBy': likedBy,
      'bookmarkedBy': bookmarkedBy,
      'repostedBy': repostedBy,
      'quotedPostId': quotedPostId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory SkyPost.fromMap(String id, Map<String, dynamic> map, MockUser user, List<PostComment> comments, {String? currentUserId}) {
    final createdAt = map['createdAt'];
    DateTime? dateTime;
    if (createdAt is Timestamp) {
      dateTime = createdAt.toDate();
    }

    final likedBy = List<String>.from(map['likedBy'] ?? []);
    final bookmarkedBy = List<String>.from(map['bookmarkedBy'] ?? []);
    final repostedBy = List<String>.from(map['repostedBy'] ?? []);

    // Read the per-user like timestamps map. Posts from before this field
    // existed only have `likedBy` (a flat array of uids); their entries
    // come back with null timestamps.
    final likedAt = <String, DateTime?>{};
    final likesRaw = map['likes'];
    if (likesRaw is Map) {
      likesRaw.forEach((key, value) {
        if (key is String) {
          likedAt[key] = value is Timestamp ? value.toDate() : null;
        }
      });
    }
    for (final uid in likedBy) {
      likedAt.putIfAbsent(uid, () => null);
    }

    // Use network URLs if available, otherwise fall back to local image paths
    final imageUrls = List<String>.from(map['imageUrls'] ?? []);
    final localPaths = List<String>.from(map['localImagePaths'] ?? []);

    return SkyPost(
      id: id,
      user: user,
      caption: map['caption'] ?? '',
      imageAssets: List<String>.from(map['imageAssets'] ?? []),
      imageUrls: imageUrls,
      imageFiles: imageUrls.isEmpty
          ? localPaths.map((p) => File(p)).where((f) => f.existsSync()).toList()
          : const [],
      timeAgo: _timeAgoFromDate(dateTime),
      likes: likedBy.length,
      reposts: repostedBy.length,
      comments: comments,
      location: map['location'],
      bortleClass: map['bortleClass'],
      skyQuality: map['skyQuality'],
      qualityLabel: map['qualityLabel'],
      isLiked: currentUserId != null && likedBy.contains(currentUserId),
      isBookmarked: currentUserId != null && bookmarkedBy.contains(currentUserId),
      isReposted: currentUserId != null && repostedBy.contains(currentUserId),
      likedBy: likedBy,
      likedAt: likedAt,
      bookmarkedBy: bookmarkedBy,
      repostedBy: repostedBy,
      userId: map['userId'] ?? '',
      createdAt: dateTime,
      quotedPostId: map['quotedPostId'],
    );
  }

  static String _timeAgoFromDate(DateTime? date) {
    if (date == null) return 'now';
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}

class PostComment {
  const PostComment({
    required this.user,
    required this.text,
    required this.timeAgo,
    this.id = '',
    this.userId = '',
    this.createdAt,
    this.imageUrls = const [],
  });

  final String id;
  final MockUser user;
  final String text;
  final String timeAgo;
  final String userId;
  final DateTime? createdAt;
  final List<String> imageUrls;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'text': text,
      'imageUrls': imageUrls,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory PostComment.fromMap(String id, Map<String, dynamic> map, MockUser user) {
    final createdAt = map['createdAt'];
    DateTime? dateTime;
    if (createdAt is Timestamp) {
      dateTime = createdAt.toDate();
    }

    return PostComment(
      id: id,
      user: user,
      text: map['text'] ?? '',
      timeAgo: SkyPost._timeAgoFromDate(dateTime),
      userId: map['userId'] ?? '',
      createdAt: dateTime,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }
}

String formatCount(int count) {
  if (count >= 1000000) {
    final value = count / 1000000;
    return value == value.truncateToDouble()
        ? '${value.toInt()}M'
        : '${value.toStringAsFixed(1)}M';
  } else if (count >= 1000) {
    final value = count / 1000;
    return value == value.truncateToDouble()
        ? '${value.toInt()}k'
        : '${value.toStringAsFixed(1)}k';
  }
  return '$count';
}
