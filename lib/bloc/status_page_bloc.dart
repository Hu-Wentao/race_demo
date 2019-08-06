// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:race_demo/redux/app_redux.dart';
import 'package:race_demo/util/util.dart';
import 'base_bloc.dart';

/// modify........................VVV.VVV.VVV.......................................
const String DEVICE_NAME_START_WITH = "Race_";

class StatusPageBloc extends BaseBloc {
  BleScanState currentScanState;

  @override
  void dispose() {
    _bleOperatorController.close();
    _btnDataController.close();
  }

  // 声明广播, 对widget开放,控制 连接蓝牙设备 的整个流程
  StreamController<BleOpInfo> _bleOperatorController =
      new StreamController.broadcast();

  StreamSink<BleOpInfo> get inBleOperator => _bleOperatorController.sink;

  get _outGetAction => _bleOperatorController.stream;

  // 声明广播, 提供给 "搜索设备"按钮, 如果没有搜索到, 则提示用户点击按钮,进行搜索
  StreamController<BtnStreamOpInfo> _btnDataController =
      new StreamController.broadcast();

  // 供内部调用, 更改"搜索设备"按钮的状态,
  StreamSink<BtnStreamOpInfo> get _inSetBtnState => _btnDataController.sink;

  // bool 值, true 表示btn可点击, 点击后
  Stream<BtnStreamOpInfo> get outGetBtnState => _btnDataController.stream;

  // 构造函数, 定义流的处理的步骤 ///////////////////////////////////////////////
  StatusPageBloc() {
    this._outGetAction.listen(_onGetAction);
    this.outGetBtnState.listen((data) => currentScanState = data.state);
  }

  // 当监听到 StatusPage被build 事件输入时:
  void _onGetAction(BleOpInfo info) {
    // 这里的action 表示的是 "StatusPage实例被创建", 这里的action 表示的是 "StatusPage实例被创建",
    switch (info.op) {
      case Operate.CHECK_OPEN_BLE:
        _checkAndOpenBle(info.context);
        break;
      case Operate._FIND_IN_CONNECTED:
        _findInConnectedDevice(info.context);
        break;
      case Operate._SCAN_DEVICE:
        _scanDevice(info.context);
        break;
      case Operate.CONNECT_DEVICE:
        _connectDevice(info.context, info.device);
        break;
      case Operate.STOP_SCANNING:
        FlutterBlue.instance.stopScan();
        _inSetBtnState.add(BtnStreamOpInfo(BleScanState.STOP_SCAN, null));
        break;
      case Operate.DISCONNECT_DEVICE:
        info.device.disconnect();
        StoreProvider.of<AppState>(info.context)
            .dispatch(SetCurrentDeviceAction(null));
        _inSetBtnState.add(BtnStreamOpInfo(BleScanState.STOP_SCAN, null));
        break;
    }
  }

  // 检测蓝牙状态, 并自动打开
  _checkAndOpenBle(BuildContext context) {
    FlutterBlue.instance.state
        .where(
            (state) => [BluetoothState.on, BluetoothState.off].contains(state))
        .listen((bleState) {
      if (bleState == BluetoothState.on) {
        print('StatusPageBloc._onGetAction 监听到蓝牙已开启, 激活 _FIND_IN_CONNECTED 事件');
        inBleOperator.add(BleOpInfo(
          Operate._FIND_IN_CONNECTED,
          context: context,
        ));
      } else {
        print('StatusPageBloc._onGetAction 蓝牙处于关闭状态, 正在请求打开蓝牙');
        _inSetBtnState.add(BtnStreamOpInfo(BleScanState.PLEASE_OPEN_BLE, null));
        BleUtil.openBluetooth();
      }
    });
  }

  _findInConnectedDevice(BuildContext context) {
    FlutterBlue.instance.connectedDevices
        .then((list) => list
            .where((d) => d.name.startsWith(DEVICE_NAME_START_WITH))
            .toList())
        .then((rightList) {
      if (rightList.length == 0) {
        print(
            'StatusPageBloc._findInConnectedDevice 可用设备列表中没有Race开头的设备 激活 SCAN_DEVICE 事件');
        inBleOperator.add(BleOpInfo(Operate._SCAN_DEVICE, context: context));
      } else if (rightList.length == 1) {
        print(
            'StatusPageBloc._findInConnectedDevice 发现已连接了一个以Race开头的设备: ${rightList[0].name}激活 CONNECT_DEVICE');
        inBleOperator.add(BleOpInfo(Operate.CONNECT_DEVICE,
            context: context, device: rightList[0]));
      } else {
        // 提示用户手动选择连接的设备,
        print(
            'StatusPageBloc._findInConnectedDevice 发现已连接了多个以Race开头的设备, 提示用户手动选择设备');
        _inSetBtnState
            .add(BtnStreamOpInfo(BleScanState.PLEASE_SELECT_DEVICE, rightList));
      }
    });
  }

  // 扫描设备
  _scanDevice(BuildContext context) {
    print('StatusPageBloc._scanDevice 监听到 扫描设备 请求');
    FlutterBlue.instance
        .startScan(timeout: const Duration(seconds: 4))
        .then((_) {
      _inSetBtnState.add(BtnStreamOpInfo(BleScanState.STOP_SCAN, null));
    });
    _inSetBtnState.add(BtnStreamOpInfo(BleScanState.SCANNING, null));

    print('StatusPageBloc._scanDevice 正在监听扫描结果');
    FlutterBlue.instance.scanResults.listen((list) {
      // 如果当前正在连接设备, 则忽略本次连接请求
      if (currentScanState == BleScanState.CONNECTING || currentScanState == BleScanState.SHOW_CONNECTED_DEVICE) return;

      var rightList = list
          .where((d) => (d.advertisementData.localName
                  .startsWith(DEVICE_NAME_START_WITH) ||
              d.device.name.startsWith(DEVICE_NAME_START_WITH)))
          .toList();
      if (rightList.length == 0) {
        print('StatusPageBloc._scanDevice 没有在扫描结果中发现合适的设备');
      } else if (rightList.length == 1) {
        print('StatusPageBloc._scanDevice 发现一个合适的设备: ${rightList[0].device.name}, 正在连接');
//        inBleOperator.add(BleOpInfo(Operate.STOP_SCANNING));
        inBleOperator.add(BleOpInfo(Operate.CONNECT_DEVICE,
            context: context, device: rightList[0].device));
      } else {
        print('StatusPageBloc._scanDevice 发现了多个合适设备: $rightList, 自动选择信号最强的设备');
        rightList = rightList.where((r) => r.rssi < 0).toList();
        rightList.sort(((a, b) => b.rssi - a.rssi));
        inBleOperator.add(
            BleOpInfo(Operate.CONNECT_DEVICE, device: rightList.first.device));
        inBleOperator.add(BleOpInfo(
          Operate.STOP_SCANNING,
        ));
        print(
            'StatusPageBloc._scanDevice 最后选中的设备是 ${rightList.first},发出 STOP_CANNING');
      }
    });
  }

  _connectDevice(BuildContext context, BluetoothDevice device) async {
    _inSetBtnState.add(BtnStreamOpInfo(BleScanState.CONNECTING, null));

    device.connect();

    StoreProvider.of<AppState>(context)
        .dispatch(SetCurrentDeviceAction(device));

    _inSetBtnState
        .add(BtnStreamOpInfo(BleScanState.SHOW_CONNECTED_DEVICE, device));
  }
}

// 与 _bleOperateController 配合使用
class BleOpInfo {
  final Operate op;
  final BuildContext context;
  final BluetoothDevice device;

  BleOpInfo(this.op, {this.context, this.device}) {
    if (op == Operate.CONNECT_DEVICE || op == Operate.DISCONNECT_DEVICE) {
      assert(device != null);
      assert(context != null);
    }
  }
}

enum Operate {
  // 开启蓝牙
  CHECK_OPEN_BLE,
  // 在已连接的设备中查询
  _FIND_IN_CONNECTED,
  // 扫描新的设备
  _SCAN_DEVICE,
  // 连接设备, 该选项需要有参数
  CONNECT_DEVICE,
  // 停止扫描
  STOP_SCANNING,
  // 断开连接
  DISCONNECT_DEVICE,
}

class BtnStreamOpInfo {
  final BleScanState state;
  final Object data;

  BtnStreamOpInfo(this.state, this.data);
}

enum BleScanState {
  SCANNING,
  STOP_SCAN,
  CONNECTING,
  PLEASE_OPEN_BLE,
  PLEASE_SELECT_DEVICE,
  SHOW_CONNECTED_DEVICE,
}
