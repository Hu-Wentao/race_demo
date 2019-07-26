// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
class ReduxAppAction{
  final ActionType type;
  final data;

  ReduxAppAction(this.type, this.data);
  @override
  String toString()=> "类型: ${this.type}, 数据: ${this.data}";
}
enum ActionType{
  setConnectedDevice,
  removeConnectDevice,
  changAppInfo,
}
