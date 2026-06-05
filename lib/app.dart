import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'common/navigation_service.dart';
import 'common/route_tool.dart';
import 'providers.dart';
import 'routes.dart';
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
      child: MaterialApp(
        title: '蓝牙钥匙测试',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorKey: NavigationService.navigatorKey,
        initialRoute: Routes.home,
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
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _hideKeyboard(context),
            child: child,
          );
        },
      ),
    );
  }
}
