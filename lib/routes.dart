import 'common/route_tool.dart';
import 'screens/ble_key/ble_key_screen.dart';
import 'screens/ble_key/vendor_ble_key_screen.dart';
import 'screens/home/home_screen.dart';

abstract final class Routes {
  static const home = '/';
  static const currentTest = '/current-test';
  static const vendorTest = '/vendor-test';
}

final Map<String, RouteHandler> routes = <String, RouteHandler>{
  Routes.home: (context, {args}) => const HomeScreen(),
  Routes.currentTest: (context, {args}) => const BleKeyScreen(),
  Routes.vendorTest: (context, {args}) => const VendorBleKeyScreen(),
};
