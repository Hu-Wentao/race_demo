//import 'dart:async';
//import 'package:flutter_blue/flutter_blue.dart';

import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

import 'base_bloc.dart';

class SettingsPageBloc extends BaseBloc {
  @override
  void dispose() {
    _transportDevice.close();
    _updateFirmware.close();
  }

  // 设备连接 事件的流入, 从 Status中流入, 在Settings中流出
  StreamController<BluetoothDevice> _transportDevice =
  StreamController.broadcast();

  StreamSink<BluetoothDevice> get inAddConnectedDevice => _transportDevice.sink;

  Stream<BluetoothDevice> get outConnectedDevice => _transportDevice.stream;

//  // 设备升级 流, 只是用来展示 固件升级的进度
  StreamController<UpdateProgressInfo> _updateFirmware = StreamController.broadcast();

  StreamSink<UpdateProgressInfo> get inAddUpdateProgress =>
      _updateFirmware.sink;

  Stream<UpdateProgressInfo> get outUpdateProgress => _updateFirmware.stream;

  SettingsPageBloc() {
    outUpdateProgress.listen((data) => _updateMethod(data));
  }

  _updateMethod(UpdateProgressInfo updateProgressInfo) {
    // todo  VVV V
    if (updateProgressInfo.updatePhase == UpdatePhase.FIND_SERVICE) {
      Stream.fromFuture(updateProgressInfo.bleDevice.discoverServices())
      // 获取 oad服务的特征列表
          .map((serList) {
        var ser = serList.where((ser) {
          print("oad_page ###服务的uuid:  ${ser.uuid.toString()}");
          if (ser.uuid.toString().substring(4, 8) == "ffc0" &&
              ser.uuid.toString().endsWith("0")) {
            print("oad_pag}e ###找到 Race 主服务:  ${ser.uuid.toString()}");
            return true;
          } else if (ser.uuid.toString().substring(4, 8) == "abf0") {
            /// debug ................................................................
            print("oad_page ###找到 RaceDB 主服务:  ${ser.uuid.toString()}");
            return true;
          } else {
            return false;
          }
        }).toList();
        return ser[0].characteristics;
      }).map((charList) {
        // 这里写一个 打开并监听 特征 的通知的方法, 如果出错, 考虑等监听出结果后再sink.add
        charList.forEach((char) {
          final String keyUuid = char.uuid.toString().substring(4, 8);
          switch (keyUuid) {
            case "abf1":
            case "ffc1":
            case "ffc2":
            case "ffc3":
            case "ffc4":
            case "abf4":
              char.value.listen((d) {
                char.setNotifyValue(true); // 打开监听
                print("监听到 $keyUuid 的消息: $d");
                if (d.length > 0) {
                  inAddUpdateProgress.add(UpdateProgressInfo(UpdatePhase.SEND_FIRM, ));
                }
              });
          }
        }
        );
      
      })
            .listen((_) {
          print("流已结束");
        });
      }
          // todo AAA

    switch (updateProgressInfo.updatePhase) {
      case UpdatePhase.DOWNLOAD_FIRM:
      // TODO: Handle this case.
        break;
      case UpdatePhase.FIND_SERVICE:
        break;
      case UpdatePhase.OPEN_CHARA:
      // TODO: Handle this case.
        break;
      case UpdatePhase.SEND_HEAD:
      // TODO: Handle this case.
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

  class UpdateProgressInfo {
  final UpdatePhase updatePhase;
  final double totalProgress;
  final BluetoothDevice bleDevice;

  UpdateProgressInfo(this.updatePhase, {this.totalProgress, this.bleDevice});
  }

  enum UpdatePhase {
  DOWNLOAD_FIRM, //10%
  FIND_SERVICE, // 0%
  OPEN_CHARA, // 0%
  SEND_HEAD, // 0%
  SEND_FIRM, // 90%
  RECEIVE_RESULT, // 0%
  }
