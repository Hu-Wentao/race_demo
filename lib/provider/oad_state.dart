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
  GET_FIRM,
  REQUEST_MTU_PRIORITY,
  LISTEN_CHARA_AND_SEND_HEAD,
  RECEIVE_NOTIFY,
  LISTENED_RESULT, // 收到ffc4的消息, 出错, 成功, 等信息
}
