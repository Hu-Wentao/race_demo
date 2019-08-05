// Copyright 2019, Hu Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
// Date : 2019/8/5
// Time : 14:13
part of 'app_redux.dart';


class SetCurrentOadPhase extends Action{
  final OadPhase phase;
  SetCurrentOadPhase(this.phase):super(AcType._SET_CURRENT_OAD_PHASE);
}

/// 管理 OAD 状态
class OadState {
  OadPhase _oadPhase = OadPhase.UN_OAD;

  bool get isOad => _oadPhase != OadPhase.UN_OAD;

  OadPhase get oadPhase => _oadPhase;
}

enum OadPhase {
  UN_OAD,
  INIT_OAD, // 初始化 OAD
  CHECK_VERSION, // 检查固件版本与最新版本
  GET_FIRM, // 下载固件
  REQUEST_MTU_PRIORITY, // 设置请求与MTU
  LISTEN_CHARA_AND_SEND_HEAD, // 打开特征监听, 发送请求头
  RECEIVE_NOTIFY, // 监听特征
  LISTENED_RESULT, // 用于返回OAD 出错, 成功, 等信息
}