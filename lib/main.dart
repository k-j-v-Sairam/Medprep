import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/shared_prefs_provider.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/sync_provider.dart';
import 'core/utils/snackbar_utils.dart';
import 'features/study_session/domain/activity_log.dart';
import 'features/study_session/domain/subject.dart';
import 'features/study_session/domain/topic.dart';
import 'features/study_session/domain/notification_log.dart';
import 'features/study_session/application/notification_service.dart';
import 'features/study_session/application/db_seeder.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/navigation/presentation/screens/main_tab_screen.dart';
import 'core/widgets/animated_loading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Force portrait orientation for focused study UX
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // True OLED edge-to-edge immersion
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AppStartupWidget());
}

class AppInitData {
  final Isar isar;
  final SharedPreferences prefs;
  AppInitData({required this.isar, required this.prefs});
}

class AppStartupWidget extends StatefulWidget {
  const AppStartupWidget({super.key});

  @override
  State<AppStartupWidget> createState() => _AppStartupWidgetState();
}

class _AppStartupWidgetState extends State<AppStartupWidget> {
  late Future<AppInitData> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initApp();
  }

  Future<AppInitData> _initApp() async {
    // Both Firebase and Database init run concurrently off the critical UI path
    final firebaseInitFuture = Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Initialise and seed the database using the JSON syllabus
    final dbInitFuture = getApplicationDocumentsDirectory().then((dir) async {
       await prepareDatabaseIfNeeded(dir.path);
       return dir.path;
    });
    
    // Await both initialization tasks
    await firebaseInitFuture;
    final dbDirPath = await dbInitFuture;

    // Open Isar with all collections.
    final isar = await Isar.open(
      [ActivityLogSchema, SubjectSchema, TopicSchema, NotificationLogSchema],
      directory: dbDirPath,
    );

    // Initialise local notifications
    final notificationService = NotificationService(isar: isar);
    await notificationService.initialize(
      onDidReceiveNotificationResponse: (response) {
        // Just launch the app, no specific screen mapping for now since review UI is removed
      },
    );
    // Initialise SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    await notificationService.requestPermission();
    await notificationService.requestExactAlarmsPermission();
    await notificationService.rescheduleAllNotifications(prefs);

    return AppInitData(isar: isar, prefs: prefs);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppInitData>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            home: AnimatedLoadingScreen(message: 'Preparing Offline Database...'),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            home: Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: Text(
                  'Initialization Failed:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyLg(color: Colors.red),
                ),
              ),
            ),
          );
        } else {
          final data = snapshot.data!;
          return ProviderScope(
            overrides: [
              isarProvider.overrideWithValue(data.isar),
              sharedPreferencesProvider.overrideWithValue(data.prefs),
            ],
            child: NeuroNexusApp(isar: data.isar),
          );
        }
      },
    );
  }
}

class NeuroNexusApp extends ConsumerStatefulWidget {
  final Isar isar;
  const NeuroNexusApp({super.key, required this.isar});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  ConsumerState<NeuroNexusApp> createState() => _NeuroNexusAppState();
}

class _NeuroNexusAppState extends ConsumerState<NeuroNexusApp> {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NeuroNexusApp.navigatorKey,
      title: 'MedPrep',
      scaffoldMessengerKey: SnackbarUtils.messengerKey,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      onGenerateRoute: (settings) {
        if (settings.name == '/main') {
          return PageRouteBuilder(
            pageBuilder: (_, __, ___) => const MainTabScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          );
        }
        return null;
      },
      home: const _AuthGate(),
    );
  }
}

/// Watches the Firebase auth state and routes to the appropriate screen.
///
/// - Authenticated → [MainTabScreen] (with sync active in background)
/// - Not authenticated → [LoginScreen]
class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialise the sync service so it starts listening for
    // connectivity changes as soon as the user is authenticated.
    ref.watch(syncServiceProvider);

    final authState = ref.watch(authStateProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final isGuest = prefs.getBool('is_guest') ?? false;

    return authState.when(
      loading: () => const AnimatedLoadingScreen(message: 'Authenticating...'),
      error: (_, __) => isGuest ? const MainTabScreen() : const LoginScreen(),
      data: (user) => (user != null || isGuest) ? const MainTabScreen() : const LoginScreen(),
    );
  }
}
