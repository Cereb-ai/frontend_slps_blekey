import 'common/route_tool.dart';
import 'screens/ble_key/ble_key_screen.dart';

abstract final class Routes {
  static const home = '/';
}

final Map<String, RouteHandler> routes = <String, RouteHandler>{
  Routes.home: (context, {args}) => const BleKeyScreen(),
};
