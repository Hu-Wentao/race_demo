import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

import 'base_bloc.dart';

class SettingsPageBloc extends BaseBloc {
  @override
  void dispose() {
    _deviceController.close();
  }
  // 为改页面提供当前已连接的 设备 , 用于为设备更新固件
  StreamController<BluetoothDevice> _deviceController = StreamController.broadcast();
  StreamSink<BluetoothDevice> get inAddConnectedDevice => _deviceController.sink;
  Stream<BluetoothDevice> get outGetConnectedDevice => _deviceController.stream;

//  SettingsPageBloc(){
//
//  }
}
