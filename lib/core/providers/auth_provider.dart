import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_service.dart';
import '../../firebase_options.dart';

/// Initializes Firebase asynchronously to avoid blocking the main thread during cold start.
final firebaseInitProvider = FutureProvider<FirebaseApp>((ref) async {
  return await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
});

/// Provides the singleton [AuthService].
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provides a [Stream<User?>] that emits whenever the Firebase auth state
/// changes (sign-in, sign-out, token refresh).
final authStateProvider = StreamProvider<User?>((ref) async* {
  // Ensure Firebase is initialized before accessing Auth
  await ref.watch(firebaseInitProvider.future);
  yield* ref.watch(authServiceProvider).authStateChanges;
});

/// Convenience derived provider: the currently authenticated [User] or `null`.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
