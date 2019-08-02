// Copyright 2019, Hu Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
// Date : 2019/8/2
// Time : 14:12

import 'package:race_demo/race_device.dart';

class AppState {
  final RaceDevice raceDevice;
  final OadState oadState;
  final String testInfo;

  AppState({
    this.raceDevice,
    this.oadState,
    this.testInfo,
  });

  AppState.initState()
      : this(raceDevice: null, oadState: null, testInfo: "hello redux");
}

class OadState {

}

///自定义 appReducer 用于创建 store.
///reducer 是一个状态生成器, 接收原来的状态和一个action,通过匹配这个状态来生成新的状态
AppState appReducer(AppState state, dynamic action) {
  switch ((action as AppAction).type) {
    case ActionType.setConnectedDevice:
      return AppState(device: action.data as BluetoothDevice);
    case ActionType.removeConnectDevice:
      return AppState(device: null);
    case ActionType.changAppInfo:
      return AppState(appInfo: action.data);
    default:
      print('deviceReducer 异常!!!空的case: $action');
      return null;
  }

//  return AppState(
//    raceDevice: raceDeviceReducer(state.raceDevice, action),
//    oadState: OadState(),
//  );
}

raceDeviceReducer(RaceDevice raceDevice, action) {}

/////////////////////////////////////////////////////////////////////////////
class AppAction {
  final ActionType type;
  final data;

  AppAction(this.type, this.data);

  @override
  String toString() => "类型: ${this.type}, 数据: ${this.data}";
}

enum ActionType {
  setConnectedDevice,
  removeConnectDevice,
  changAppInfo,
}
