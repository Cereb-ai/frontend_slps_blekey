import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'screens/ble_key/ble_key_controller.dart';
import 'states/global_error_store.dart';

List<SingleChildWidget> get providers => <SingleChildWidget>[
  ChangeNotifierProvider(create: (_) => GlobalErrorStore.instance),
  ChangeNotifierProvider(create: (_) => BleKeyController()),
];
