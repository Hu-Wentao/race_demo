// Copyright 2019, Hu Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
// Date : 2019/8/2
// Time : 14:12

import 'package:flutter_blue/flutter_blue.dart';
import 'package:race_demo/race_device.dart';
import 'package:redux/redux.dart';
part 'oad_redux.dart';
part 'device_redux.dart';

/// 这里定义所有的Action的类型
enum AcType {
  _SET_CURRENT_DEVICE,
  _SET_CURRENT_OAD_PHASE,
}

abstract class Action {
  final AcType type;
  Action(this.type);
}

/// 应用状态
class AppState {
  DeviceState deviceState;
  OadState oadState;

  AppState({this.deviceState, this.oadState});

  AppState.initState()
      : this(deviceState: DeviceState(null), oadState: OadState());

  @override
  String toString() => "deviceState: $deviceState, oadState: $oadState";
}

///自定义 appReducer 用于创建 store.
///reducer 是一个状态生成器, 接收原来的状态和一个action,通过匹配这个状态来生成新的状态
AppState appReducer(AppState state, dynamic action) {
  print("appReducer>> action类型: ${action.type}");
  switch (action.type) {
    case AcType._SET_CURRENT_DEVICE:
      state.deviceState = DeviceState((action as SetCurrentDeviceAction)._raceDevice);
      break;
  }
  print("appReducer>> state被修改: $state");
  return state;
}
