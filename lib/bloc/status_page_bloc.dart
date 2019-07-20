import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

import 'base_bloc.dart';

class StatusPageBloc extends BaseBloc {
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
  }

  // 当监听到 StatusPage被build 事件输入时:
  void _onGetAction(BleOpInfo info) {
    // 这里的action 表示的是 "StatusPage实例被创建", 这里的action 表示的是 "StatusPage实例被创建",
    switch (info.op) {
      case Operate.CHECK_OPEN_BLE:
        _checkAndOpenBle();
        break;
      case Operate._FIND_IN_CONNECTED:
        _findInConnectedDevice();
        break;
      case Operate._SCAN_DEVICE:
        _scanDevice();
        break;
      case Operate.CONNECT_DEVICE:
        _connectDevice(info.device);
        break;
      case Operate.STOP_SCANNING:
        FlutterBlue.instance.stopScan();
        break;
    }

    // 向流中输入
//    _inAddData.addStream();
  }

  // 获取数据输出流, 提供给StreamBuilder
//  _getStreamData() {
//    return _dataController.stream.where();
//  }

  // 检测蓝牙是否打开
  _checkAndOpenBle() {
    FlutterBlue.instance.state.listen((bleState) {
      if (bleState == BluetoothState.on) {
        print('StatusPageBloc._onGetAction 监听到蓝牙已开启, 激活 _FIND_IN_CONNECTED 事件');
        inBleOperator.add(BleOpInfo(Operate._FIND_IN_CONNECTED, null));
        return true;
      } else {
        print('StatusPageBloc._onGetAction 蓝牙未开启 或 处于其他状态 todo #############');
        // todo 使用 bluetooth_serial 库 开启蓝牙, 或者自己写一个 MethodChannel
        return false;
      }
    });
  }

  _findInConnectedDevice() {
    //TODO del
    print(
        'StatusPageBloc._findInConnectedDevice 进入 _FIND_IN_CONNECTED 方法, 正在检索 Race 开头的设备...');
    FlutterBlue.instance.connectedDevices
        .then((list) => list.where((d) {
              //todo del
              print('StatusPageBloc._findInConnectedDevice 查找到设备: ${d.name}');
              return d.name.startsWith("Race");
            }).toList())
        .then((rightList) {
      if (rightList.length == 0) {
        print(
            'StatusPageBloc._findInConnectedDevice 没有在可用的设备列表中发现Race开头的设备 激活 SCAN_DEVICE 事件');
        inBleOperator.add(BleOpInfo(Operate._SCAN_DEVICE, null));
      } else if (rightList.length == 1) {
        print(
            'StatusPageBloc._findInConnectedDevice 发现已连接了 一个以Race开头的设备:${rightList[0].name} 激活 CONNECT_DEVICE');
        inBleOperator.add(BleOpInfo(Operate.CONNECT_DEVICE, rightList[0]));
      } else {
        print(
            'StatusPageBloc._findInConnectedDevice 发现已连接了 多个以Race开头的设备, 提示用户手动选择设备');
        // 提示用户手动选择连接的设备,
        _inSetBtnState
            .add(BtnStreamOpInfo(BleScanState.PLEASE_SELECT_DEVICE, rightList));
      }
    });
  }

  // 扫描设备
  _scanDevice() {
    print('StatusPageBloc._scanDevice 监听到 扫描设备 请求');
    print('StatusPageBloc._scanDevice 开始扫描');
    FlutterBlue.instance.startScan(timeout: const Duration(seconds: 2));
    _inSetBtnState.add(BtnStreamOpInfo(BleScanState.SCANNING, null));

    print('StatusPageBloc._scanDevice 正在监听扫描结果');
    FlutterBlue.instance.scanResults
//        .where((resultList) {
//      bool haveRightDevice = false;
//      resultList.forEach((r) {
//        switch (r.device.name) {
//          case"RaceDB_0020":
//          case"RaceDB_0021":
//          case "RaceDB_0010":
//          case "RaceDB_0011":
//          case "Race_0002":
//            print('StatusPageBloc._scanDevice 在扫描结果中找到 ${r.device.name}');
//            haveRightDevice = true;
//            break;
//        }
//      });
//      return haveRightDevice;
//    })
        .listen((list) {
      var rightList =
          list.where((d) => d.device.name.startsWith("Race")).toList();
      if (rightList.length == 0) {
        print('StatusPageBloc._scanDevice 没有在扫描结果中发现合适的设备');
      } else if (rightList.length == 1) {
        print(
            'StatusPageBloc._scanDevice 发现了一个合适的设备: ${rightList[0].device.name}, 正在连接');
//        rightList[0].device.connect();
        inBleOperator
            .add(BleOpInfo(Operate.CONNECT_DEVICE, rightList[0].device));
        inBleOperator.add(BleOpInfo(Operate.STOP_SCANNING, null));
      } else {
        print('StatusPageBloc._scanDevice 发现了多个合适设备: $rightList, 自动选择信号最强的设备');
        rightList = rightList.where((r) => r.rssi < 0).toList();
        rightList.sort(((a, b) => b.rssi - a.rssi));
//        rightList.first.device.connect();
        inBleOperator
            .add(BleOpInfo(Operate.CONNECT_DEVICE, rightList.first.device));
        inBleOperator.add(BleOpInfo(Operate.STOP_SCANNING, null));
        print(
            'StatusPageBloc._scanDevice 最终选择连接的设备是 ${rightList.first}, 发出 STOP_CANNING 请求');
      }
    });
  }

  _connectDevice(BluetoothDevice device) {
    _inSetBtnState.add(BtnStreamOpInfo(BleScanState.CONNECTING, null));
    device.connect();
//    inBleOperator.add(BleOpInfo(Op, data))
    _inSetBtnState
        .add(BtnStreamOpInfo(BleScanState.SHOW_CONNECTED_DEVICE, device));
  }
}

// 与 _bleOperateController 配合使用
class BleOpInfo {
  final Operate op;
  final BluetoothDevice device;

  BleOpInfo(this.op, this.device);
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
  STOP_SCANNING,
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