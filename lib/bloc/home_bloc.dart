import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

import 'base_bloc.dart';


class HomeBloc extends BaseBloc{
  @override
  void dispose() {
    _deviceController.close();
  }
  // 为该页面提供当前已连接的 设备 , 用于为设备更新固件
  StreamController<BluetoothDevice> _deviceController = StreamController();
  StreamSink<BluetoothDevice> get inAddConnectedDevice => _deviceController.sink;
  Stream<BluetoothDevice> get outGetConnectedDevice => _deviceController.stream;

  HomeBloc(){
//    outGetConnectedDevice.listen((device){
//      print('HomeBloc.HomeBloc 监听到消息, 连接到了一个设备: ${device.name}');
//    });
  }
}
