import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'screens/ble_key/ble_key_controller.dart';
import 'states/global_error_store.dart';
import 'states/locale_store.dart';
import 'states/location_provider.dart';

List<SingleChildWidget> get providers => <SingleChildWidget>[
  ChangeNotifierProvider(create: (_) => GlobalErrorStore.instance),
  ChangeNotifierProvider(create: (_) => BleKeyController()),
  ChangeNotifierProvider(create: (_) => LocaleStore.instance),
  ChangeNotifierProvider(create: (_) => LocationProvider()),
];
