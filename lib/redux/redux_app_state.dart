import 'package:flutter_blue/flutter_blue.dart';

///全局信息
///
class ReduxAppState{
  /// 一条全局信息
  String _appInfo;
  String get appInfo => _appInfo;
  ///
  BluetoothDevice _device;
  BluetoothDevice get device => _device;


  ReduxAppState(this._device);

  ReduxAppState.initState(){
    this._device = null;
    this._appInfo = "hello redux";
  }
}
