// Copyright 2019, Hu Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
// Date : 2019/8/2
// Time : 18:41
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:race_demo/race_device.dart';

import 'oad_model.dart';

class RaceModel with ChangeNotifier {
  RaceDevice _raceDevice;

  RaceDevice get currentDevice => _raceDevice;

  setCurrentDevice({BluetoothDevice bleDevice}) {
    if(bleDevice == null){
//      currentOadState.setCurrentOadPhase(OadPhase.UN_OAD);
      _raceDevice = null;
    }else{
      _raceDevice = DeviceCc2640(bleDevice);
    }
    notifyListeners();
  }

}