//import 'dart:async';
//import 'package:flutter_blue/flutter_blue.dart';

import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

import 'base_bloc.dart';

class SettingsPageBloc extends BaseBloc {
  @override
  void dispose() {
    _updateFirmware.close();
  }
  // 事件的流入
  StreamController<BluetoothDevice> _updateFirmware = StreamController.broadcast();
  StreamSink<BluetoothDevice> get inAddConnectedDevice => _updateFirmware.sink;
  Stream<BluetoothDevice> get outUpdateProgress => _updateFirmware.stream;

  SettingsPageBloc(){
//    outUpdateProgress.listen(onData)
  }
}
