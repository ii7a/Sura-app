import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

/// Number of conversations with unread messages for the signed-in user.
/// Powers the badge on the Messages tab in the bottom navigation. Mirrors
/// X/Twitter — the badge counts threads, not individual messages.
final unreadConversationsCountProvider = StreamProvider<int>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  if (uid == null) return Stream.value(0);
  return ref.watch(firestoreServiceProvider).unreadConversationsCountStream(uid);
});
