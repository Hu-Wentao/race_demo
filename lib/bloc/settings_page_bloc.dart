// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:path_provider/path_provider.dart';

import '../race_device.dart';
import 'base_bloc.dart';

class SettingsPageBloc extends BaseBloc {
  RaceDevice currentRaceDevice;

  bool isUpdating = false;

  List<List<int>> binContent;

//  //todo 升级计时
  int currentUpdateTime = 0;
  Timer _updateTimer;

  @override
  void dispose() {
    _transportDevice.close();
    _oadCtrl.close();
    _updateFirmware.close();
    _updateControl.close();

    // 计时器
    _timerCtrl.close();
    _timeCtrl.close();
  }

  // 设备连接 事件的流入, 从 Status中流入, 在Settings中流出, 以后考虑用redux取代
  StreamController<BluetoothDevice> _transportDevice =
      StreamController.broadcast();

  StreamSink<BluetoothDevice> get inAddConnectedDevice => _transportDevice.sink;

  Stream<BluetoothDevice> get outConnectedDevice => _transportDevice.stream;

  // 控制OAD 开始与结束 // todo 可以与 _updateControl 合并
  StreamController<BluetoothDevice> _oadCtrl = StreamController();

  StreamSink<BluetoothDevice> get inAddOadCmd => _oadCtrl.sink;

  Stream<BluetoothDevice> get _outOadCmd => _oadCtrl.stream;

  // 设备升级流, 只是用来展示固件升级的进度
  StreamController<UpdateProgressInfo> _updateFirmware =
      StreamController.broadcast();

  StreamSink<UpdateProgressInfo> get _inShowUpdateProgress =>
      _updateFirmware.sink;

  Stream<UpdateProgressInfo> get outUpdateProgress => _updateFirmware.stream;

  // 升级控制
  StreamController<UpdateCtrlCmd> _updateControl = StreamController.broadcast();

  StreamSink<UpdateCtrlCmd> get _inAddUpdateCmd => _updateControl.sink;

  Stream<UpdateCtrlCmd> get _outGetUpdateCmd => _updateControl.stream;

  // 计时器.................................................................................
  StreamController<bool> _timerCtrl = StreamController.broadcast();
  // 传入 -1 表示 开始计时, 传入-2, 表示停止计时
  StreamSink<bool> get inAddTimerCmd => _timerCtrl.sink;
  Stream<bool> get _outTimeCmd => _timerCtrl.stream;

  StreamController<int> _timeCtrl = StreamController.broadcast();
  StreamSink<int> get _inAddCurrentUpdateTime => _timeCtrl.sink;
  Stream<int> get outCurrentTime => _timeCtrl.stream;
  SettingsPageBloc() {
    _outOadCmd.listen((device) => _oadFlow(device));
    _outGetUpdateCmd.listen((updateCmd) => _exeUpdateCmd(updateCmd));

    _outTimeCmd.listen((start) {
      if(start){
        _updateTimer = Timer.periodic(const Duration(seconds: 1), (_){
          _inAddCurrentUpdateTime.add(currentUpdateTime++);
        });
      }else{
        _updateTimer.cancel();
      }
    });
  }

  Future _oadFlow(BluetoothDevice device) async {
    if (isUpdating) {
      print('SettingsPageBloc._oadFlow 检测到当前设备正在更新, 请勿重复发起更新....');
      return;
    }
    isUpdating = true;

    currentRaceDevice = DeviceCc2640(device);

    _inAddUpdateCmd.add(UpdateCtrlCmd(UpdatePhase.GET_FIRM));
  }

  _exeUpdateCmd(UpdateCtrlCmd updateCmd) async {
    if (updateCmd.updatePhase != UpdatePhase.RECEIVE_NOTIFY) {
      _inShowUpdateProgress.add(UpdateProgressInfo(updateCmd.updatePhase));
    }
    switch (updateCmd.updatePhase) {
      case UpdatePhase.GET_FIRM:
        binContent = await _getByteList(_getFirmwareFromNet());
        _inAddUpdateCmd.add(UpdateCtrlCmd(UpdatePhase.REQUEST_MTU_PRIORITY));
        break;
      /////////////////////////////////////////////////////////////////////////////////////////////
      case UpdatePhase.REQUEST_MTU_PRIORITY:
        currentRaceDevice.requestMtuAndPriority(
            mtu: 128, priority: ConnectionPriority.high);
        _inAddUpdateCmd
            .add(UpdateCtrlCmd(UpdatePhase.LISTEN_CHARA_AND_SEND_HEAD));
        break;
      case UpdatePhase.LISTEN_CHARA_AND_SEND_HEAD:
        await currentRaceDevice.openAndListenCharNotify(_inAddUpdateCmd, [
          DeviceCc2640.identifyCharUuid,
          DeviceCc2640.blockCharUuid,
          DeviceCc2640.statusCharUuid
        ]);

        await Future.delayed(const Duration(seconds: 1));
        print('SettingsPageBloc._exeUpdateCmd 向特征发送头文件: ${binContent[0].sublist(0,16)}');
        (await currentRaceDevice.charMap)[DeviceCc2640.identifyCharUuid]
            .write(binContent[0], withoutResponse: true);
        break;
      case UpdatePhase.RECEIVE_NOTIFY:
        NotifyInfo notifyInfo = updateCmd.notifyInfo;
        print(
            'SettingsPageBloc._exeUpdateCmd 监听到 ${notifyInfo.char.uuid.toString()} 消息: ${notifyInfo.notifyValue}');
        if (notifyInfo.notifyValue.length == 0) {
          print('由于收到的消息长度为0, 所以忽略该消息');
          return;
        }
        switch (notifyInfo.char.uuid.toString()) {
          case DeviceCc2640.identifyCharUuid:
          case DeviceCc2640.blockCharUuid:
            if (notifyInfo.notifyValue.length != 2) break;
            List<int> value = notifyInfo.notifyValue;
            int index = value[0] + value[1] * 256;
            print(
                'SettingsPageBloc._oadNotify 正在向ffc2发送: ${value + binContent[index]}');
            // 将索引号加上
            notifyInfo.char
                .write(value + binContent[index], withoutResponse: true);
            _inShowUpdateProgress.add(UpdateProgressInfo(
                UpdatePhase.RECEIVE_NOTIFY,
                phraseProgress: index / binContent.length));
            break;
          case DeviceCc2640.statusCharUuid:
            isUpdating = false;
            print(
                'SettingsPageBloc._oadNotify 监听到ffc4: ${notifyInfo.notifyValue}');
            _inShowUpdateProgress.add(UpdateProgressInfo(
                UpdatePhase.RECEIVE_NOTIFY,
                phraseProgress: 1));
            break;
        }
        break;
    }
  }
}

class UpdateCtrlCmd {
  final UpdatePhase updatePhase;
  final NotifyInfo notifyInfo;

  UpdateCtrlCmd(
    this.updatePhase, {
    this.notifyInfo,
  });
}

class UpdateProgressInfo {
  final UpdatePhase updatePhase;
  final double phraseProgress;

  double get totalProgress {
    switch (updatePhase) {
      case UpdatePhase.GET_FIRM:
        return phraseProgress * 0.03;
      case UpdatePhase.REQUEST_MTU_PRIORITY:
        return phraseProgress * 0.01 + 0.03;
      case UpdatePhase.LISTEN_CHARA_AND_SEND_HEAD:
        return phraseProgress * 0.01 + 0.04;
      case UpdatePhase.RECEIVE_NOTIFY:
        return phraseProgress * 0.95 + 0.05;
    }
    return 0;
  }

  UpdateProgressInfo(
    this.updatePhase, {
    this.phraseProgress: 0,
  });
}

enum UpdatePhase {
  GET_FIRM, // 3%
  REQUEST_MTU_PRIORITY, // 1%
  LISTEN_CHARA_AND_SEND_HEAD, // 1%
  RECEIVE_NOTIFY, // 95%
}

Future<File> _getFirmwareFromNet() async {
  const String firmwareName = "firmware.bin";
  const String downloadUrl =
//      "https://raw.githubusercontent.com/Hu-Wentao/File_Center/master/app_OAD1_16.bin";
//      "https://raw.githubusercontent.com/Hu-Wentao/File_Center/master/app_OAD2_16.bin";

//  "https://raw.githubusercontent.com/Hu-Wentao/File_Center/master/app_OAD1_32.bin";
   "https://raw.githubusercontent.com/Hu-Wentao/File_Center/master/app_OAD2_32.bin";

//   "https://raw.githubusercontent.com/Hu-Wentao/File_Center/master/app_OAD1_32_CRC.bin";
//   "https://raw.githubusercontent.com/Hu-Wentao/File_Center/master/app_OAD2_32_CRC.bin";
  Directory dir = await getApplicationDocumentsDirectory();
  File f = new File(dir.path + "/$firmwareName");
  if (!await f.exists()) {
    Response response = await Dio().download(downloadUrl, f.path);
    print('_getFirmwareFromNet response的信息:  ${response.data.toString()}');
  }
  return new File(dir.path + "/$firmwareName");
}

///
/// 将二进制文件转换成 二维列表
Future<List<List<int>>> _getByteList(Future<File> f) async {
  List<int> content = await (await f).readAsBytes();
  List<List<int>> binList = [];

  /// 发送数据的长度
  const int sendLength = 32;
//   第一包
//  binList.add(content.sublist(0, 16));
  // 后面的包
  for (int i = 0; i < content.length; i += sendLength) {
    int index = i + sendLength;
    if (index > content.length) index = content.length;
    binList.add(content.sublist(i, index));
  }
  return binList;
}
