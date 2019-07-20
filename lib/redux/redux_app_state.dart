import 'package:flutter_blue/flutter_blue.dart';

///全局信息
///
class ReduxAppState{
  BluetoothDevice _device;
  get device => _device;

  ReduxAppState(this._device);

  ReduxAppState.initState(){
    this._device = null;
  }
}
