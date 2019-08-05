// Copyright 2019, Hu Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
// Date : 2019/8/5
// Time : 14:18
part of 'app_redux.dart';

/// 定义 设置当前设备 Action
class SetCurrentDeviceAction extends Action {
  RaceState _raceDevice;

  SetCurrentDeviceAction(BluetoothDevice bleDevice) : super(AcType._SET_CURRENT_DEVICE) {
    if (bleDevice == null) {
      // todo 考虑使用中间件 来实现这个功能
//      currentOadState.setCurrentOadPhase(OadPhase.UN_OAD);
      _raceDevice = null;
    } else {
      _raceDevice = DeviceCc2640(bleDevice);
    }
  }
}

/// 管理 Race设备 的状态
class DeviceState {
  final RaceState _raceDevice;

  DeviceState(this._raceDevice);

  RaceState get currentDevice => _raceDevice;
}


RaceState raceDeviceReducer(raceState, action) {
  /////////////
  return raceState;
}
