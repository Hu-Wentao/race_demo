//import 'dart:async';
//import 'package:flutter_blue/flutter_blue.dart';

import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

import 'base_bloc.dart';

class SettingsPageBloc extends BaseBloc {
  @override
  void dispose() {
    _transportDevice.close();
    _updateFirmware.close();
  }

  // 设备连接 事件的流入, 从 Status中流入, 在Settings中流出
  StreamController<BluetoothDevice> _transportDevice =
      StreamController.broadcast();

  StreamSink<BluetoothDevice> get inAddConnectedDevice => _transportDevice.sink;

  Stream<BluetoothDevice> get outConnectedDevice => _transportDevice.stream;

//  // 设备升级 流, 只是用来展示 固件升级的进度
  StreamController<UpdateProgressInfo> _updateFirmware = StreamController();

  StreamSink<UpdateProgressInfo> get inAddUpdateProgress =>
      _updateFirmware.sink;

  Stream<UpdateProgressInfo> get outUpdateProgress => _updateFirmware.stream;

  SettingsPageBloc() {
//    outUpdateProgress.listen(onData)
  }
}

class UpdateProgressInfo {
  final UpdatePhase updatePhase;
  final double totalProgress;

  UpdateProgressInfo(this.updatePhase, this.totalProgress);
}

enum UpdatePhase {
  DOWNLOAD_FIRM,  //2%
  FIND_SERVICE, // 2%
  OPEN_CHARA, // 2%
  SEND_HEAD, // 2%
  SEND_FIRM, // 90%
  RECEIVE_RESULT, // 2%
}
