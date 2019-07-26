// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'package:flutter_blue/flutter_blue.dart';

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
}

abstract class DeviceProfile {
  String get oadServiceUuid;

  String get identifyCharUuid;

  String get blockCharUuid;

  String get statusCharUuid;
}

class DeviceCc2640 extends DeviceProfile {
  @override
  String get oadServiceUuid => "f000ffc0-0451-4000-b000-000000000000";

  @override
  String get identifyCharUuid => "f000ffc1-0451-4000-b000-000000000000";

  @override
  String get blockCharUuid => "f000ffc2-0451-4000-b000-000000000000";

  @override
  String get statusCharUuid => "f000ffc4-0451-4000-b000-000000000000";
}
