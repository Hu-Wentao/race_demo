import 'package:flutter_blue/flutter_blue.dart';
import 'package:race_demo/redux/redux_app_action.dart';
import 'package:race_demo/redux/redux_app_state.dart';

ReduxAppState appReducer(ReduxAppState state, action) {
  switch ((action as ReduxAppAction).type) {
    case ActionType.setConnectedDevice:
      return ReduxAppState(device: action.data as BluetoothDevice);
    case ActionType.removeConnectDevice:
      return ReduxAppState(device: null);
    case ActionType.changAppInfo:
      return ReduxAppState(appInfo: action.data);
    default:
      print('deviceReducer 异常!!!空的case: $action');
      return null;
  }
}
