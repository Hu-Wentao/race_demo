// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'dart:io';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';

import 'bloc/settings_page_bloc.dart';

abstract class RaceDevice {
  final BluetoothDevice device;

  int get mtu;

  RaceDevice(this.device);

  requestMtuAndPriority({int mtu, ConnectionPriority priority}) {
    if (!Platform.isAndroid) return;
    if (mtu != null) device.requestMtu(mtu);
    if (priority != null) device.requestConnectionPriority(priority);
  }

  openAndListenCharNotify(StreamSink sink, List<String> charUuidList);

  Future<BluetoothService> get oadService;

  Future<Map<String, BluetoothCharacteristic>> get charMap;
}

class DeviceCc2640 extends RaceDevice {
  static const String oadServiceUuid = "f000ffc0-0451-4000-b000-000000000000";

  static const String identifyCharUuid = "f000ffc1-0451-4000-b000-000000000000";

  static const String blockCharUuid = "f000ffc2-0451-4000-b000-000000000000";

  static const String statusCharUuid = "f000ffc4-0451-4000-b000-000000000000";

  BluetoothService _oadService;
  Map<String, BluetoothCharacteristic> _charMap;
  BluetoothCharacteristic _identifyChar;
  BluetoothCharacteristic _blockChar;
  BluetoothCharacteristic _statusChar;

  DeviceCc2640(BluetoothDevice device) : super(device);

  Future<BluetoothService> get oadService async =>
      _oadService ??
      (_oadService = (await device.discoverServices())
          .where((s) => s.uuid.toString() == oadServiceUuid)
          .toList()[0]);

  Future<Map<String, BluetoothCharacteristic>> get charMap async =>
      _charMap ??
      (_charMap = Map.fromIterable(
        ((await oadService).characteristics),
        key: (char) => (char as BluetoothCharacteristic).uuid.toString(),
        value: (char) => (char as BluetoothCharacteristic),
      ));

  Future<BluetoothCharacteristic> get identifyChar async =>
      _identifyChar ?? (_identifyChar = (await charMap)[identifyCharUuid]);

  Future<BluetoothCharacteristic> get blockChar async =>
      _blockChar ?? (_blockChar = (await charMap)[blockCharUuid]);

  Future<BluetoothCharacteristic> get statusChar async =>
      _statusChar ?? (_statusChar = (await charMap)[statusCharUuid]);

  @override
  openAndListenCharNotify(StreamSink _inAddUpdateCmd, List<String> charUuidList) async {

    for(int i =0; i<charUuidList.length; i++) {
      print('DeviceCc2640.openAndListenCharNotify ${DateTime.now().toIso8601String()} ### test 正在打开 ${charUuidList[i]} 的通知....');


      // 无法省略...
      await Future.delayed(const Duration(milliseconds: 700));

      (await charMap)[charUuidList[i]].setNotifyValue(true);   // 库 存在问题......., setNotifyValue() 无法等待获取返回值

      (await charMap)[charUuidList[i]].value.listen((notify) => _inAddUpdateCmd.add(UpdateCtrlCmd(
          UpdatePhase.RECEIVE_NOTIFY,
          notifyInfo: NotifyInfo(((_charMap)[charUuidList[i]]), notify))));
      print('DeviceCc2640.openAndListenCharNotify ${DateTime.now().toIso8601String()} ### test 成功打开 ${charUuidList[i]} 的通知');
    }
  }

  @override
  int get mtu => 256;
}

class NotifyInfo {
//  String charKeyUuid;
  List<int> notifyValue;
  BluetoothCharacteristic char;

  NotifyInfo(this.char, this.notifyValue);

  @override
  toString() {
    return "From: ${char.uuid
        .toString()} Key UUID : ${char.uuid.toString()}, Notify: $notifyValue";
  }
}
