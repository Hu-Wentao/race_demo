// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'package:flutter_blue/flutter_blue.dart';

///全局信息
class ReduxAppState {
  /// 一条全局信息
  final String appInfo;
  final BluetoothDevice device;

  ReduxAppState({this.appInfo, this.device});

  ReduxAppState.initState() : this(appInfo: "hello");
}
