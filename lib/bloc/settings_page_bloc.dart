// Copyright 2019/7/26, Hu Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:path_provider/path_provider.dart';

import '../race_device.dart';
import 'base_bloc.dart';

class SettingsPageBloc extends BaseBloc {
  RaceDevice currentDevice;

  bool isUpdating = false;

  List<List<int>> binContent;

  int updateStartTime = 0;
  Timer timer;

  // 升级控制
  StreamController<UpdateCtrlCmd> _updateControl = StreamController.broadcast();

  StreamSink<UpdateCtrlCmd> get inAddUpdateCmd => _updateControl.sink;

  Stream<UpdateCtrlCmd> get _outGetUpdateCmd => _updateControl.stream;

  // 设备升级流, 只是用来展示固件升级的进度
  StreamController<UpdateProgressInfo> _updateFirmware =
  StreamController.broadcast();

  StreamSink<UpdateProgressInfo> get _inShowUpdateProgress =>
      _updateFirmware.sink;

  Stream<UpdateProgressInfo> get outUpdateProgress => _updateFirmware.stream;

  // 计时器.................................................................................
  StreamController<bool> _timerCtrl = StreamController.broadcast();

  // 传入 true 表示 设置计时起点, 传入 false, 表示发送 当前时间-计时起点 的值
  StreamSink<bool> get inAddTimerCmd => _timerCtrl.sink;

  Stream<bool> get _outTimeCmd => _timerCtrl.stream;

  StreamController<int> _timeDataCtrl = StreamController.broadcast();

  StreamSink<int> get _inAddCurrentUpdateTime => _timeDataCtrl.sink;

  Stream<int> get outCurrentTime => _timeDataCtrl.stream;

  @override
  void dispose() {
    // 让设置Page 获取到 Device
    // 触发 OAD 事件     // 控制OAD的流程     // 向page展示当前的进度
    _updateControl.close();
    _updateFirmware.close();

    // 触发 计时器 事件     // 向Page发送计时数据
    _timerCtrl.close();
    _timeDataCtrl.close();
  }

  SettingsPageBloc() {
    _outGetUpdateCmd.listen((updateCmd) => _exeUpdateCmd(updateCmd));

    _outTimeCmd.listen((start) {
      if (start) {
        updateStartTime = DateTime
            .now()
            .millisecondsSinceEpoch;

        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          _inAddCurrentUpdateTime
              .add(DateTime
              .now()
              .millisecondsSinceEpoch - updateStartTime);
        });
      } else {
        timer.cancel();
      }
    });
  }

  _exeUpdateCmd(UpdateCtrlCmd updateCmd) async {
    switch (updateCmd.oadPhase) {
      case OadPhase.UN_OAD:
        _inShowUpdateProgress.add(UpdateProgressInfo(
            updateCmd.oadPhase, "Not in oad",
            phraseProgress: 0));
        print("当前不处于OAD状态, 本提示被打印代表程序逻辑可能出错########");
        return;
      case OadPhase.INIT_OAD:
        _inShowUpdateProgress.add(UpdateProgressInfo(
          updateCmd.oadPhase,
          "Initial OAD ...",
        ));
        assert(updateCmd.bleDevice != null);
        currentDevice = DeviceCc2640(updateCmd.bleDevice);
        // do sth in init...............
        inAddUpdateCmd
            .add(UpdateCtrlCmd(OadPhase.CHECK_VERSION, updateCmd.context));
        break;
      case OadPhase.CHECK_VERSION:
        _inShowUpdateProgress.add(UpdateProgressInfo(
          updateCmd.oadPhase,
          "Checking version...",
        ));
        // TODO: 检查固件版本, 然后直接返回到...... 待考虑....

        inAddUpdateCmd.add(UpdateCtrlCmd(OadPhase.GET_FIRM, updateCmd.context));
        break;
      case OadPhase.GET_FIRM:
        _inShowUpdateProgress.add(UpdateProgressInfo(
          updateCmd.oadPhase,
          "Downloading frimware...",
        ));
        binContent = await _getByteList(_getFirmwareFromFile());
        inAddUpdateCmd.add(UpdateCtrlCmd(
            Platform.isAndroid
                ? OadPhase.REQUEST_MTU_PRIORITY
                : OadPhase.LISTEN_CHARA_AND_SEND_HEAD,
            updateCmd.context));
        break;
    /////////////////////////////////////////////////////////////////////////////////////////////
      case OadPhase.REQUEST_MTU_PRIORITY:
        _inShowUpdateProgress.add(UpdateProgressInfo(
          updateCmd.oadPhase,
          "Request MTU & Priority...",
        ));

        currentDevice
            .requestMtuAndPriority(mtu: 200, priority: ConnectionPriority.high);
        inAddUpdateCmd.add(UpdateCtrlCmd(
            OadPhase.LISTEN_CHARA_AND_SEND_HEAD, updateCmd.context));
        break;
      case OadPhase.LISTEN_CHARA_AND_SEND_HEAD:
        _inShowUpdateProgress.add(UpdateProgressInfo(
          updateCmd.oadPhase,
          "Open notify...",
        ));

        await currentDevice.openAndListenCharNotify(inAddUpdateCmd, [
          DeviceCc2640.identifyCharUuid,
          DeviceCc2640.blockCharUuid,
          DeviceCc2640.statusCharUuid
        ]);
        await Future.delayed(const Duration(milliseconds: 300));
        final head = binContent[0].sublist(0, 16);
        print('_exeUpdateCmd 向特征发送头文件: $head');

        (await currentDevice.charMap)[DeviceCc2640.identifyCharUuid]
            .write(head, withoutResponse: true);
        break;
      case OadPhase.RECEIVE_NOTIFY:
        _inShowUpdateProgress.add(UpdateProgressInfo(
            updateCmd.oadPhase, "Sending Firmware...",
            phraseProgress: 0));

        NotifyInfo notifyInfo = updateCmd.notifyInfo;
        print(
            'SettingsPageBloc._exeUpdateCmd 监听到 ${notifyInfo.char.uuid
                .toString()} 消息: ${notifyInfo.notifyValue}');
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
                'SettingsPageBloc._oadNotify 正在向ffc2发送: ${value +
                    binContent[index]}');
            // 将索引号加上
            notifyInfo.char
                .write(value + binContent[index], withoutResponse: true);
            _inShowUpdateProgress.add(UpdateProgressInfo(
                OadPhase.RECEIVE_NOTIFY, "Sending Firmware...",
                phraseProgress: index / binContent.length));
            break;
          case DeviceCc2640.statusCharUuid:
            inAddUpdateCmd.add(UpdateCtrlCmd(
                OadPhase.LISTENED_RESULT, updateCmd.context,
                notifyInfo: notifyInfo));
            break;
        }
        break;
      case OadPhase.LISTENED_RESULT:
        isUpdating = false;
        var msg = const [
          "Success!",
          "CRC error!",
          "Flash error!",
          "Buffer error!",
        ][updateCmd.notifyInfo.notifyValue[0]];

        print('SettingsPageBloc._oadNotify 监听到ffc4: $msg, 15s后返回 UN_OAD状态');

        _inShowUpdateProgress.add(UpdateProgressInfo(
            OadPhase.RECEIVE_NOTIFY, msg,
            phraseProgress: 1));

        Future.delayed(const Duration(seconds: 15)).then((_) =>
            inAddUpdateCmd
                .add(UpdateCtrlCmd(OadPhase.UN_OAD, updateCmd.context)));
        break;
    }
  }
}

class UpdateCtrlCmd {
  final OadPhase oadPhase;
  final NotifyInfo notifyInfo;
  final BuildContext context;
  final BluetoothDevice bleDevice;

  UpdateCtrlCmd(this.oadPhase,
      this.context, {
        this.bleDevice,
        this.notifyInfo,
      });
}

class UpdateProgressInfo {
  final OadPhase oadPhase;
  final String phaseMsg;
  final double phraseProgress;

  double get sendFirmProgress =>
      (oadPhase == OadPhase.RECEIVE_NOTIFY) ? phraseProgress : null;

  UpdateProgressInfo(this.oadPhase,
      this.phaseMsg, {
        this.phraseProgress: 0,
      });
}

enum OadPhase {
  UN_OAD,
  INIT_OAD,
  CHECK_VERSION,
  GET_FIRM, // 3%
  REQUEST_MTU_PRIORITY, // 1%
  LISTEN_CHARA_AND_SEND_HEAD, // 1%
  RECEIVE_NOTIFY, // 95%
  LISTENED_RESULT, // 收到ffc4的消息
}

Future<File> _getFirmwareFromFile() async {
  const String firmwareName = "app_OAD2_128_CRC.bin";
//  const String firmwareName = "from_net.bin";
//  const String firmwareName = "firmware.bin";
  const String downloadUrl =
      "https://file.racehf.com/RaceHF_Bean/bean_latest.bin";
//      "https://raw.githubusercontent.com/Hu-Wentao/File_Center/master/app_OAD1_16.bin";
  Directory dir = await getApplicationDocumentsDirectory();
  File f = new File(dir.path + "/$firmwareName");
  if (!await f.exists() || firmwareName == "from_net.bin") {
    Response response = await Dio().download(downloadUrl, f.path);
    print('_getFirmwareFromNet response的信息:  ${response.data.toString()}');
  }
  return new File(dir.path + "/$firmwareName");
}

/// 将二进制文件转换成 二维列表
Future<List<List<int>>> _getByteList(Future<File> f) async {
  List<int> content = await (await f).readAsBytes();
  List<List<int>> binList = [];

  /// 发送数据的长度
  const int sendLength = 128;
  for (int i = 0; i < content.length; i += sendLength) {
    int index = i + sendLength;
    if (index > content.length) index = content.length;
    binList.add(content.sublist(i, index));
  }
  return binList;
}
