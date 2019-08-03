// Copyright 2019, Hu Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
// Date : 2019/8/2
// Time : 21:12
import 'package:flutter/foundation.dart';

class OadState with ChangeNotifier {
  OadPhase _oadPhase = OadPhase.UN_OAD;

  get isOad => _oadPhase != OadPhase.UN_OAD;
  get oadPhase => _oadPhase;
  setCurrentOadPhase(OadPhase currentPhase) {
    _oadPhase = currentPhase;
    notifyListeners();
  }
}

enum OadPhase {
  UN_OAD,
  CHECK_VERSION,  // 检查固件版本与最新版本
  GET_FIRM,       // 下载固件
  REQUEST_MTU_PRIORITY, // 设置请求与MTU
  LISTEN_CHARA_AND_SEND_HEAD, // 打开特征监听, 发送请求头
  RECEIVE_NOTIFY,     // 监听特征
  LISTENED_RESULT,    // 用于返回OAD 出错, 成功, 等信息
}
