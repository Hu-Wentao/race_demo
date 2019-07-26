// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'dart:io';

import 'package:flutter_blue/flutter_blue.dart';
import 'dart:async';

_typeOf<T>() => T;


class RaceDevice {
  final BluetoothDevice device;
  final DeviceProfile profile;
  BluetoothService _oadService;
  Map<String, BluetoothCharacteristic> _charMap;
  BluetoothCharacteristic _identifyChar;
  BluetoothCharacteristic _blockChar;
  BluetoothCharacteristic _statusChar;

  RaceDevice(this.device, this.profile);

  RaceDevice.cc2640(BluetoothDevice device) : this(device, DeviceCc2640());

  // 下面的代码可以封装到 DeviceCc2640 中去, 然后使用泛型约束 DeviceProfile////////////////////
  Future<BluetoothService> get oadService async =>
      _oadService ??
      (_oadService = (await device.discoverServices())
          .where((s) => s.uuid.toString() == profile.oadServiceUuid)
          .toList()[0]);

  Future<Map<String, BluetoothCharacteristic>> get charMap async =>
      _charMap ??
      (_charMap = Map.fromIterable(
        ((await oadService).characteristics),
        key: (char) => (char as BluetoothCharacteristic).uuid.toString(),
        value: (char) => (char as BluetoothCharacteristic),
      ));

  Future<BluetoothCharacteristic> get identifyChar async =>
      _identifyChar ??
      (_identifyChar = (await charMap)[profile.identifyCharUuid]);

  Future<BluetoothCharacteristic> get blockChar async =>
      _blockChar ?? (_blockChar = (await charMap)[profile.blockCharUuid]);

  Future<BluetoothCharacteristic> get statusChar async =>
      _statusChar ?? (_statusChar = (await charMap)[profile.statusCharUuid]);

  openCharNotify(List<String> charUuidList) {
    charUuidList.forEach((uuid) async {
      // TODO DEL.................................................
      print('RaceDevice.openCharNotify ### test 正在打开 $uuid 的通知....');
      await (_charMap[uuid]).setNotifyValue(true);
      print('RaceDevice.openCharNotify ### test 成功打开 $uuid 的通知');
    });
  }

  requestMtuAndPriority({int mtu, ConnectionPriority priority}) {
    if (!Platform.isAndroid) return;
    if (mtu != null) device.requestMtu(mtu);
    if (priority != null) device.requestConnectionPriority(priority);
  }
}

// 本类可以转移到单独的 base_profile.dart 中/////////////////////////////////////////////
abstract class DeviceProfile {
  int get mtu;
}

class DeviceCc2640 extends DeviceProfile {
  @override
  int get mtu => 128;
  final String oadServiceUuid = "f000ffc0-0451-4000-b000-000000000000";

  static const String identifyCharUuid = "f000ffc1-0451-4000-b000-000000000000";

  static  String blockCharUuid = "f000ffc2-0451-4000-b000-000000000000";

  static const String statusCharUuid = "f000ffc4-0451-4000-b000-000000000000";
}

