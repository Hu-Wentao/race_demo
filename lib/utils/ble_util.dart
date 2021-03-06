// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel methodChannel = MethodChannel('bean.racehf.com/bluetooth');

class BleUtil {
  //打开蓝牙
  static Future<void> openBluetooth() async {
    if(Platform.isAndroid) {
      String message = await methodChannel.invokeMethod('openBluetooth');
      print('SettingsPage._openBluetooth $message');
    }
  }
}
