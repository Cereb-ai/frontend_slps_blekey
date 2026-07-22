import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'common/navigation_service.dart';
import 'common/route_tool.dart';
import 'l10n/app_localizations.dart';
import 'providers.dart';
import 'routes.dart';
import 'screens/login/login_screen.dart';
import 'screens/home/app_home_screen.dart';
import 'services/offline_data_store.dart';
import 'states/global_user.dart';
import 'states/locale_store.dart';
import 'themes/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
    WidgetsBinding.instance.addObserver(this);
    LocaleStore.instance.loadFromStorage();
    Api.registerAuthStateHandlers(
      getAccessToken: () => GlobalUser.instance.token,
      getRefreshToken: () => GlobalUser.instance.refreshToken,
      persistTokens: ({required accessToken, refreshToken}) {
        return GlobalUser.instance.persistTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      },
    );
    Api.registerUnauthorizedHandler(() async {
      await GlobalUser.instance.clearLocalSession();
      if (!mounted) return;
      final navigator = NavigationService.navigatorKey.currentState;
      if (navigator == null) return;
      final context = NavigationService.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute == Routes.login) return;
      }
      navigator.pushNamedAndRemoveUntil(Routes.login, (_) => false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _hideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: Consumer<LocaleStore>(
        builder: (context, localeStore, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          navigatorKey: NavigationService.navigatorKey,
          locale: localeStore.locale,
          supportedLocales: LocaleStore.supportedLocales,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const _SplashGate(),
          onGenerateRoute: (settings) {
            final normalized = mergeUriToRouteSettings(settings);
            final handler = routes[normalized.name] ?? routes[Routes.home]!;
            return MaterialPageRoute<void>(
              settings: normalized,
              builder: (context) => handler(
                context,
                args: normalized.arguments as Map<String, dynamic>?,
              ),
            );
          },
          builder: (context, child) {
            final page = GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _hideKeyboard(context),
              child: child,
            );
            return ValueListenableBuilder<bool>(
              valueListenable: OfflineDataStore.isSyncing,
              builder: (context, syncing, _) => Stack(
                children: [
                  page,
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: IgnorePointer(
                        ignoring: !syncing,
                        child: AnimatedSlide(
                          offset: syncing ? Offset.zero : const Offset(0, -1.2),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                          child: AnimatedOpacity(
                            opacity: syncing ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: const _GlobalSyncBanner(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GlobalSyncBanner extends StatelessWidget {
  const _GlobalSyncBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 12),
            Text('正在同步钥匙、锁和授权任务…'),
          ],
        ),
      ),
    );
  }
}

/// Shown at startup; checks token then routes to login or home.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    Api.suppressUnauthorizedHandler(true);
    try {
      await GlobalUser.instance.loadFromStorage();
      if (GlobalUser.instance.isLoggedIn) {
        await _validateStoredSession();
      }
    } finally {
      Api.suppressUnauthorizedHandler(false);
    }
    final loggedIn = GlobalUser.instance.isLoggedIn;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => loggedIn ? const AppHomeScreen() : const LoginScreen(),
      ),
    );
  }

  Future<void> _validateStoredSession() async {
    try {
      await GlobalUser.instance.fetchProfile().timeout(
        const Duration(seconds: 3),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await GlobalUser.instance.clearLocalSession();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF05070B),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF00D9FF))),
    );
  }
}
