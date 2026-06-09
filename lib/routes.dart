import 'common/route_tool.dart';
import 'screens/ble_key/ble_key_screen.dart';
import 'screens/ble_key/online_switch_lock_screen.dart';
import 'screens/ble_key/vendor_ble_key_screen.dart';
import 'screens/home/app_home_screen.dart';
import 'screens/home/home_screen.dart';

abstract final class Routes {
  static const home = '/';
  static const testHome = '/test-home';
  static const currentTest = '/current-test';
  static const vendorTest = '/vendor-test';
  static const onlineSwitchLock = '/online-switch-lock';
}

final Map<String, RouteHandler> routes = <String, RouteHandler>{
  Routes.home: (context, {args}) => const AppHomeScreen(),
  Routes.testHome: (context, {args}) => const HomeScreen(),
  Routes.currentTest: (context, {args}) => const BleKeyScreen(),
  Routes.vendorTest: (context, {args}) => const VendorBleKeyScreen(),
  Routes.onlineSwitchLock: (context, {args}) => const OnlineSwitchLockScreen(),
};
