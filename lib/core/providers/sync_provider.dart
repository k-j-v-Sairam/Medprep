import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/sync/application/firestore_sync_service.dart';
import 'shared_prefs_provider.dart';
import 'auth_provider.dart';
import 'database_provider.dart';

/// Provides the [FirestoreSyncService] singleton.
final syncServiceProvider = Provider<FirestoreSyncService>((ref) {
  final isar = ref.watch(isarProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final service = FirestoreSyncService(isar: isar, prefs: prefs);

  // Start connectivity listener when a user is authenticated;
  // stop it when they sign out.
  ref.listen<AsyncValue>(authStateProvider, (_, next) {
    final user = next.valueOrNull;
    if (user != null) {
      dev.log('SyncProvider: user authenticated — starting listener', name: 'SyncProvider');
      service.startConnectivityListener(user.uid);
      // Perform an initial sync on login.
      unawaited(service.syncAll(user.uid));
    } else {
      dev.log('SyncProvider: user signed out — stopping listener', name: 'SyncProvider');
      service.stopConnectivityListener();
    }
  }, fireImmediately: true);

  ref.onDispose(service.stopConnectivityListener);
  return service;
});
