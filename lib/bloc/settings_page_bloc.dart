//import 'dart:async';
//import 'package:flutter_blue/flutter_blue.dart';

import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

import 'base_bloc.dart';

class SettingsPageBloc extends BaseBloc {
  @override
  void dispose() {
    _transportDevice.close();
//    _updateFirmware.close();
  }
  // 设备连接 事件的流入, 从 Status中流入, 在Settings中流出
  StreamController<BluetoothDevice> _transportDevice = StreamController.broadcast();
  StreamSink<BluetoothDevice> get inAddConnectedDevice => _transportDevice.sink;
  Stream<BluetoothDevice> get outConnectedDevice => _transportDevice.stream;

//  // 设备升级 流
//  StreamController _updateFirmware = StreamController();
//  StreamSink get inAdd

  SettingsPageBloc(){
//    outUpdateProgress.listen(onData)
  }
}
