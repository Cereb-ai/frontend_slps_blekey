import 'common/route_tool.dart';
import 'screens/ble_key/ble_key_screen.dart';
import 'screens/ble_key/fingerprint_unlock_demo_screen.dart';
import 'screens/ble_key/online_switch_lock_screen.dart';
import 'screens/ble_key/vendor_ble_key_screen.dart';
import 'screens/home/app_home_screen.dart';
import 'screens/home/demo_list_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/clearance/worker_clearance_screen.dart';
import 'screens/home/key_control_screen.dart';
import 'screens/home/location_test_screen.dart';
import 'screens/home/offline_task_cache_screen.dart';
import 'screens/login/login_screen.dart';

abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const testHome = '/test-home';
  static const currentTest = '/current-test';
  static const vendorTest = '/vendor-test';
  static const onlineSwitchLock = '/online-switch-lock';
  static const demoList = '/demo-list';
  static const fingerprintUnlockDemo = '/fingerprint-unlock-demo';
  static const locationTest = '/location-test';
  static const keyControl = '/key-control';
  static const workerClearance = '/worker-clearance';
  static const offlineTaskCache = '/offline-task-cache';
}

final Map<String, RouteHandler> routes = <String, RouteHandler>{
  Routes.login: (context, {args}) => const LoginScreen(),
  Routes.home: (context, {args}) => const AppHomeScreen(),
  Routes.testHome: (context, {args}) => const HomeScreen(),
  Routes.currentTest: (context, {args}) => const BleKeyScreen(),
  Routes.vendorTest: (context, {args}) => const VendorBleKeyScreen(),
  Routes.onlineSwitchLock: (context, {args}) => const OnlineSwitchLockScreen(),
  Routes.demoList: (context, {args}) => const DemoListScreen(),
  Routes.fingerprintUnlockDemo: (context, {args}) =>
      const FingerprintUnlockDemoScreen(),
  Routes.locationTest: (context, {args}) => const LocationTestScreen(),
  Routes.keyControl: (context, {args}) => KeyControlScreen.fromArgs(args),
  Routes.offlineTaskCache: (context, {args}) => const OfflineTaskCacheScreen(),
  Routes.workerClearance: (context, {args}) {
    final data = args ?? const <String, dynamic>{};
    return WorkerClearanceScreen(initialTaskId: data['taskId']?.toString());
  },
};
