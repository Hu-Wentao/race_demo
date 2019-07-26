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
//  BluetoothDevice bleDevice;
  List<List<int>> binContent;
  int openCharDelay = 0;

  @override
  void dispose() {
    _transportDevice.close();
    _oadCtrl.close();
    _updateFirmware.close();
    _notifyController.close();
    _updateControl.close();
  }

  // 设备连接 事件的流入, 从 Status中流入, 在Settings中流出
  StreamController<BluetoothDevice> _transportDevice =
      StreamController.broadcast();

  StreamSink<BluetoothDevice> get inAddConnectedDevice => _transportDevice.sink;

  Stream<BluetoothDevice> get outConnectedDevice => _transportDevice.stream;

  // 控制OAD 开始与结束
  StreamController<BluetoothDevice> _oadCtrl = StreamController();

  StreamSink<BluetoothDevice> get inAddOadCmd => _oadCtrl.sink;

  Stream<BluetoothDevice> get _outOadCmd => _oadCtrl.stream;

  // 监听各个char的通知 // todo 可以整合到 _updateControl 中
  StreamController<NotifyInfo> _notifyController = StreamController.broadcast();

  StreamSink<NotifyInfo> get _inAddNotify => _notifyController.sink;

  Stream<NotifyInfo> get _outGetNotify => _notifyController.stream;

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

  SettingsPageBloc() {
    _outOadCmd.listen((device) => _oadFlow(device));
    //
    _outGetNotify.listen((notify) => _oadNotify(notify));
    //
    _outGetUpdateCmd.listen((updateCmd) => _exeUpdateCmd(updateCmd));
  }

  Future _oadFlow(BluetoothDevice device) async {
    if(isUpdating){
      print('SettingsPageBloc._oadFlow 检测到当前设备正在更新, 请勿重复发起更新....');
      return;
    }
    isUpdating = true;

//    if (bleDevice != null) {
//      print('SettingsPageBloc._oadFlow 本方法被再次激活, 已自动屏蔽...');
//      return;
//    }
    currentRaceDevice = RaceDevice.cc2640(device);

    _inAddUpdateCmd.add(UpdateCtrlCmd(UpdatePhase.GET_FIRM));
  }

  Future<BluetoothCharacteristic> _openAndListenCharNotify(
      BluetoothService service) async {
    var rightCharList = service.characteristics
        .where((char) => ["abf1", "ffc1", "ffc2", "ffc4"]
            .contains(char.uuid.toString().substring(4, 8)))
        .toList();

    for (int i = 0; i < rightCharList.length; i++) {
      final charKeyUuid = rightCharList[i].uuid.toString().substring(4, 8);

      print('SettingsPageBloc._oadFlow 开启: $charKeyUuid 特征通知...');

//      await rightCharList[i].setNotifyValue(true);
      Future.delayed(Duration(milliseconds: 800*i)).then((_)=>rightCharList[i].setNotifyValue(true));

      // todo 这里的 notify流 可以 整合到 UpdateCtrlCmd 中..................................,
      rightCharList[i].value.listen((notifyVal) {
        _inAddNotify.add(NotifyInfo(
            char: rightCharList[i],
            charKeyUuid: charKeyUuid,
            notifyValue: notifyVal));
      });
      // todo del
      print('SettingsPageBloc._openCharNotify 开启成功 ');
      _inShowUpdateProgress.add(UpdateProgressInfo(
          UpdatePhase.LISTEN_CHARA,
          phraseProgress: openCharDelay / rightCharList.length));
    }
//    // todo del..
    return await Future.delayed(const Duration(seconds: 3)).then((_){
      return rightCharList
          .where((char) =>
          ["abf1", "ffc1"].contains(char.uuid.toString().substring(4, 8)))
          .toList()[0];
    });

    // todo 待优化(优化本方法, 直接获取oadChar)
//    return rightCharList
//        .where((char) =>
//            ["abf1", "ffc1"].contains(char.uuid.toString().substring(4, 8)))
//        .toList()[0];
  }

  _oadNotify(NotifyInfo notify) {
//    print(
//        'SettingsPageBloc._oadNotify  监听到 ${notify.charKeyUuid} 的消息: ${notify
//            .notifyValue}');
    if (notify.notifyValue.length == 0) {
      print('由于受到的消息长度为0, 所以忽略该消息');
      return;
    }
    switch (notify.charKeyUuid) {
      case "abf1":
      case "ffc1":
      case "ffc2":
        print("从 ffc2 中监听到信息： ${notify.notifyValue}");
        if (notify.notifyValue.length != 2) break;
        List<int> value = notify.notifyValue;
        int index = value[0] + value[1] * 256;
        _inShowUpdateProgress.add(UpdateProgressInfo(UpdatePhase.SEND_FIRM,
            phraseProgress: index / binContent.length));

        print('SettingsPageBloc._oadNotify 正在向 ffc2 发送: ${value + binContent[index]}');
        // 将索引号加上
        notify.char.write(value + binContent[index], withoutResponse: true);
        break;
      case "ffc4":
        print('SettingsPageBloc._oadNotify 监听到ffc4: ${notify.notifyValue}');
        //todo modify...
        _inShowUpdateProgress.add(
            UpdateProgressInfo(UpdatePhase.RECEIVE_RESULT, phraseProgress: 1));
        break;
    }
  }

  _exeUpdateCmd(UpdateCtrlCmd updateCmd) async {
    _inShowUpdateProgress.add(UpdateProgressInfo(updateCmd.updatePhase));
    switch (updateCmd.updatePhase) {
      case UpdatePhase.GET_FIRM:
        binContent = await _getByteList(_getFirmwareFromNet());
          _inAddUpdateCmd.add(UpdateCtrlCmd(UpdatePhase.REQUEST_MTU_PRIORITY));
        break;

    /////////////////////////////////////////////////////////////////////////////////////////////
      case UpdatePhase.REQUEST_MTU_PRIORITY:
        currentRaceDevice.requestMtuAndPriority(mtu: 128, priority: ConnectionPriority.high);
        _inAddUpdateCmd.add(UpdateCtrlCmd(UpdatePhase.LISTEN_CHARA));
        break;
      case UpdatePhase.LISTEN_CHARA:
        [DeviceCc2640.oadServiceUuid, ]
//        currentRaceDevice.charMap
        break;
        ////////////////////////////////////////////////////////////////////////////////////////
      case UpdatePhase.SEND_HEAD:
        print(
            'SettingsPageBloc._exeUpdateCmd 向特征 ${updateCmd.oadChar} 发送头文件: ${binContent[0]}');
        updateCmd.oadChar.write(binContent[0], withoutResponse: true);
        break;
      case UpdatePhase.SEND_FIRM:
        // TODO: Handle this case.
        break;
      case UpdatePhase.RECEIVE_RESULT:
        // TODO: Handle this case.
        break;
    }
  }
}

class UpdateCtrlCmd {
  final BluetoothDevice device;
  final UpdatePhase updatePhase;
  final BluetoothService oadService;
  final BluetoothCharacteristic oadChar;

  UpdateCtrlCmd(
    this.updatePhase, {
    this.oadChar,
    this.oadService,
    this.device,
  });
}

class UpdateProgressInfo {
  final UpdatePhase updatePhase;
  final double phraseProgress;

  double get totalProgress {
    switch (updatePhase) {
      case UpdatePhase.GET_FIRM:
        return phraseProgress * 0.04;
      case UpdatePhase.REQUEST_MTU_PRIORITY:
        return phraseProgress * 0.01 + 0.04;
      case UpdatePhase.FIND_SERVICE:
        return phraseProgress * 0.01 + 0.05;
      case UpdatePhase.LISTEN_CHARA:
        return phraseProgress * 0.02 + 0.06;
      case UpdatePhase.SEND_HEAD:
        return phraseProgress * 0.01 + 0.08;
      case UpdatePhase.SEND_FIRM:
        return phraseProgress * 0.9 + 0.09;
      case UpdatePhase.RECEIVE_RESULT:
        return phraseProgress * 0.01 + 0.99;
    }
    return 0;
  }

  UpdateProgressInfo(
    this.updatePhase, {
    this.phraseProgress: 0,
  });
}

enum UpdatePhase {
  GET_FIRM, // 4%
//  FIND_SERVICE, // 1%
  REQUEST_MTU_PRIORITY, // 1%
  LISTEN_CHARA, // 2%
  SEND_HEAD, // 1%
  SEND_FIRM, // 90%
  RECEIVE_RESULT, // 1%
}

Future<File> _getFirmwareFromNet() async {
//  const String downloadUrl = "http://file.racehf.com/RaceHF_Bean/bean_v01.bin";
//  const String downloadUrl = "http://file.racehf.com/RaceHF_Bean/app_oad1.bin";
//  const String downloadUrl = "https://send.firefox.com/download/7bac0850b24cc6e6";  // 128位的 oad1
  const String downloadUrl =
      "https://send.firefox.com/download/a4b64a580d022a54"; // 128位的 oad2
  Directory dir = await getApplicationDocumentsDirectory();

  File f = new File(dir.path + "/firmware.bin");
  if (!await f.exists()) {
    Response response = await Dio().download(downloadUrl, f.path);
    print('_getFirmwareFromNet response的信息:  ${response.data.toString()}');
  }
  return new File(dir.path + "/firmware.bin");
}

///
/// 将二进制文件转换成 二维列表
Future<List<List<int>>> _getByteList(Future<File> f) async {
  List<int> content = await (await f).readAsBytes();
  List<List<int>> binList = [];

  /// 发送数据的长度
  const int sendLength = 128;

  // 第一包
  binList.add(content.sublist(0, 16));
  // 后面的包
  for (int i = 0; i < content.length; i += sendLength) {
    int index = i + sendLength;
    if (index > content.length) index = content.length;
    binList.add(content.sublist(i, index));
  }
  return binList;
}

class NotifyInfo {
  String charKeyUuid;
  List<int> notifyValue;
  BluetoothCharacteristic char;

  NotifyInfo({this.char, this.charKeyUuid, this.notifyValue});

  @override
  toString() {
    return "From: ${char.uuid.toString()} Key UUID : $charKeyUuid, Notify: $notifyValue";
  }
}
