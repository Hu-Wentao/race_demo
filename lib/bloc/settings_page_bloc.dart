//import 'dart:async';
//import 'package:flutter_blue/flutter_blue.dart';

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:path_provider/path_provider.dart';

import 'base_bloc.dart';

class SettingsPageBloc extends BaseBloc {
  BluetoothDevice bleDevice;
  List<List<int>> binContent;
  int openCharDelay = 0;

  @override
  void dispose() {
    _transportDevice.close();
    _oadCtrl.close();
    _updateFirmware.close();
    _notifyController.close();
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

  // 监听各个char的通知
  StreamController<NotifyInfo> _notifyController = StreamController.broadcast();

  StreamSink<NotifyInfo> get _inAddNotify => _notifyController.sink;

  Stream<NotifyInfo> get _outGetNotify => _notifyController.stream;

  // 设备升级流, 只是用来展示固件升级的进度
  StreamController<UpdateProgressInfo> _updateFirmware =
      StreamController.broadcast();

  StreamSink<UpdateProgressInfo> get _inAddUpdateProgress =>
      _updateFirmware.sink;

  Stream<UpdateProgressInfo> get outUpdateProgress => _updateFirmware.stream;

  SettingsPageBloc() {
    // todo 只获取一次设备, 可能出现bug (点击按钮触发)
    _outOadCmd.take(1).listen((device) => _oadFlow(device));
    //
    _outGetNotify.listen((notify) => _oadNotify(notify));
  }

  Future _oadFlow(BluetoothDevice device) async {
    if (bleDevice != null) {
      print('SettingsPageBloc._oadFlow 本方法被再次激活, 已自动屏蔽...');
      return;
    }
    bleDevice = device;

    // 下载固件
    binContent = await _getByteList(_getFirmwareFromNet());
    _inAddUpdateProgress.add((UpdateProgressInfo(
      UpdatePhase.GET_FIRM,
    )));
    // 修改MTU
    print('SettingsPageBloc._oadFlow 请求MTU 与 优先级...');
    bleDevice.requestMtu(512).then((_) {
      bleDevice.requestConnectionPriority(ConnectionPriority.high);
    }).then((_) {
      // 获取 service
      print('SettingsPageBloc._oadFlow 开始寻找服务...');
      _inAddUpdateProgress.add(UpdateProgressInfo((UpdatePhase.FIND_SERVICE)));
      return bleDevice.discoverServices();
    }).then((serList) {
      print('SettingsPageBloc._oadFlow 得到服务列表: $serList');
      _inAddUpdateProgress.add(UpdateProgressInfo(UpdatePhase.OPEN_CHARA));
      return serList
          .where((s) =>
              ["abf0", "ffc0"].contains(s.uuid.toString().substring(4, 8)))
          .toList()[0];
    }).then((service) async {
      // todo 这里可能出现问题. 比如返回的 service 为null
      print('SettingsPageBloc._oadFlow 找到服务: ${service.uuid}');
      _inAddUpdateProgress.add(
          UpdateProgressInfo(UpdatePhase.FIND_SERVICE, phraseProgress: 0.2));

      await _openCharNotify(service);
      _inAddUpdateProgress
          .add(UpdateProgressInfo(UpdatePhase.OPEN_CHARA, phraseProgress: 0));
      return service.characteristics;
    }).then((charList) {
      print('SettingsPageBloc._oadFlow 开始初始化特征的监听器');
      charList.forEach((char) {
        // 监听特征
        char.value.listen((notifyIntList) {
          // todo 考虑在这里添加过滤, 将重复的信息过滤掉
          _inAddNotify.add(NotifyInfo(
              char: char,
              charKeyUuid: char.uuid.toString().substring(4, 8),
              notifyValue: notifyIntList));
        });
      });
      return charList;
    }).then((charList) {
      print('SettingsPageBloc._oadFlow 向特征发送头文件: ${binContent[0]}');
      _inAddUpdateProgress
          .add(UpdateProgressInfo(UpdatePhase.SEND_HEAD, phraseProgress: 1));
      BluetoothCharacteristic ch = charList
          .where((char) => char.uuid.toString().substring(4, 8) == "ffc1")
          .toList()[0];

      print('SettingsPageBloc._oadFlow 最终选择的特征是: ${ch.uuid}');

      ch.write(binContent[0], withoutResponse: true);
    });
  }

  _openCharNotify(BluetoothService service) async {
    var rightCharList = service.characteristics
        .where((char) => ["abf1", "ffc1", "ffc2", "ffc4"]
            .contains(char.uuid.toString().substring(4, 8)))
        .toList();

    for (int i = 0; i < rightCharList.length; i++) {
      print('SettingsPageBloc._oadFlow 开启: ${rightCharList[i].uuid} 特征通知...');
      await rightCharList[i].setNotifyValue(true);
      // todo del
      print('SettingsPageBloc._openCharNotify 开启成功....................');
      _inAddUpdateProgress.add(UpdateProgressInfo(UpdatePhase.OPEN_CHARA,
          phraseProgress: openCharDelay / rightCharList.length));
    }
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
        _inAddUpdateProgress.add(UpdateProgressInfo(UpdatePhase.SEND_FIRM,
            phraseProgress: index / binContent.length));
        // 将索引号加上
        notify.char.write(value + binContent[index], withoutResponse: true);
        break;
      case "ffc4":
        print('SettingsPageBloc._oadNotify 监听到ffc4: ${notify.notifyValue}');
        break;
    }
  }
}

class UpdateProgressInfo {
  final UpdatePhase updatePhase;
  final double phraseProgress;

  double get totalProgress {
    switch (updatePhase) {
      case UpdatePhase.GET_FIRM:
        return (phraseProgress ?? 0) * 0.05;
      case UpdatePhase.FIND_SERVICE:
        return (phraseProgress ?? 0) * 0.01 + 0.05;
      case UpdatePhase.OPEN_CHARA:
        return (phraseProgress ?? 0) * 0.02 + 0.06;
      case UpdatePhase.SEND_HEAD:
        return (phraseProgress ?? 0) * 0.01 + 0.08;
      case UpdatePhase.SEND_FIRM:
        return (phraseProgress ?? 0) * 0.9 + 0.09;
      case UpdatePhase.RECEIVE_RESULT:
        return (phraseProgress ?? 0) * 0.01 + 0.99;
    }
    return 0;
  }
  UpdateProgressInfo(
    this.updatePhase, {
    this.phraseProgress,
  });
}

enum UpdatePhase {
  GET_FIRM, // 5%
  FIND_SERVICE, // 1%
  OPEN_CHARA, // 2%
  SEND_HEAD, // 1%
  SEND_FIRM, // 90%
  RECEIVE_RESULT, // 1%
}

Future<File> _getFirmwareFromNet() async {
  const String downloadUrl = "http://file.racehf.com/RaceHF_Bean/bean_v02.bin";
  Directory dir = await getApplicationDocumentsDirectory();

  File f = new File(dir.path + "/firmware.bin");
  Response response = await Dio().download(downloadUrl, f.path);
  print('_getFirmwareFromNet response的信息:  ${response.data.toString()}');

  return new File(dir.path + "/firmware.bin");
}

///
/// 将二进制文件转换成 二维列表
Future<List<List<int>>> _getByteList(Future<File> f) async {
  List<int> content = await (await f).readAsBytes();
  List<List<int>> binList = [];

  /// 发送数据的长度
  const int sendLength = 32;

  // 第一包
  binList.add(content.sublist(0, 16));
  // 后面的包
  for (int i = 16; i < content.length; i += sendLength) {
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
