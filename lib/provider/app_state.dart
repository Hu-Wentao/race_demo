// Copyright 2019, Hu Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
// Date : 2019/8/2
// Time : 18:41
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:race_demo/race_device.dart';

import 'oad_state.dart';

class AppState with ChangeNotifier {
  OadState currentOadState = OadState();

  RaceDevice _raceDevice;
  ThemeData _themeData = ThemeData.light();

  get currentDevice => _raceDevice;

  setCurrentDevice({BluetoothDevice device}) {
    if(device == null){
      currentOadState.setCurrentOadPhase(OadPhase.UN_OAD);
      _raceDevice = null;
    }else{
      _raceDevice = DeviceCc2640(device);
    }
    notifyListeners();
  }

  get themeData => _themeData;

  setCurrentTheme() {
    _themeData =
        _themeData == ThemeData.light() ? ThemeData.dark() : ThemeData.light();
    notifyListeners();
  }
}
