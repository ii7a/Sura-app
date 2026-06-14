import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_service.dart';
import '../../community/models/community_models.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<MockUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;
  return ref.watch(firestoreServiceProvider).getUser(user.uid);
});

/// The single Sura admin account. Kept as a constant so the bootstrap
/// check on first login still knows which email to privilege. The runtime
/// check reads from Firestore (see [isAdminProvider]) so we don't have
/// to ship the list of admins inside the app.
const String kSuraAdminEmail = 'suraappsa@gmail.com';

/// True when the signed-in user has the `isAdmin` flag set on their
/// Firestore user doc. Reading from Firestore (rather than a hard-coded
/// email) means new admins can be granted by flipping the flag in the
/// Firebase Console — no code change required.
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  return user?.isAdmin ?? false;
});
