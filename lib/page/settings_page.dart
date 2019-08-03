import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:provider/provider.dart';
import 'package:race_demo/bloc/base_bloc.dart';
import 'package:race_demo/bloc/settings_page_bloc.dart';
import 'package:race_demo/provider/app_state.dart';
import 'package:race_demo/provider/oad_state.dart';
import 'package:race_demo/race_device.dart';
import 'package:race_demo/widget/none_border_color_expansion_tile.dart';
import 'package:race_demo/widget/radius_container_widget.dart';
import 'package:race_demo/widget/text_divider_widget.dart';

class SettingsPage extends StatelessWidget {
//  final HomeBloc homeBloc;
//  final Key checkUpdateBtnKey = const ValueKey("checkUpdateBtnKey");

  const SettingsPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SettingsPageBloc _settingsBloc =
        BlocProvider.of<SettingsPageBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 48),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextDivider(
                "Show speed in: ",
              ),
              RadiusContainer(
                child: _buildSetSpeedUnit(context),
              ),
              TextDivider(
                "Show altitude in: ",
              ),
              RadiusContainer(
                child: _buildSetAltitudeUnit(context),
              ),
              TextDivider(
                "Display position as: ",
              ),
              RadiusContainer(
                child: _buildSetPositionStyle(context),
              ),
              TextDivider(
                "About device",
              ),
              RadiusContainer(
                child: _buildUpgradeFirmware(context, _settingsBloc),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildSetSpeedUnit(BuildContext context) {
    return ListTile();
  }

  _buildSetAltitudeUnit(BuildContext context) {
    return ListTile();
  }

  _buildSetPositionStyle(BuildContext context) {
    return ListTile();
  }

  _buildUpgradeFirmware(BuildContext context, SettingsPageBloc settingsBloc) {
    final greyTextStyle =
        TextStyle(color: Theme.of(context).textTheme.caption.color);

    return StreamBuilder<UpdateProgressInfo>(
      stream: settingsBloc.outUpdateProgress,
      initialData: UpdateProgressInfo(
        null,
        phraseProgress: 0.0,
      ),
      builder: (context, snap) {
        // todo................. 考虑将以下内容都移动到BLoC中
        String oadPhaseMsg = "Null";
        switch (snap.data.oadPhase) {
          case OadPhase.UN_OAD:
            oadPhaseMsg = "当前尚未开始OAD, 本内容不应当出现在界面中";
            break;
          case OadPhase.GET_FIRM:
            settingsBloc.inAddTimerCmd.add(true); // 开始计时
            oadPhaseMsg = "Downloading firm...";
            break;
          case OadPhase.REQUEST_MTU_PRIORITY:
            oadPhaseMsg = "Request MTU & Priority...";
            break;
          case OadPhase.LISTEN_CHARA_AND_SEND_HEAD:
            oadPhaseMsg = "Open characteristic notify...";
            break;
          case OadPhase.RECEIVE_NOTIFY:
            oadPhaseMsg = "Sending Firmware...";
            break;
          case OadPhase.LISTENED_RESULT:
            //todo 此处应显示 升级成功 或 升级失败.....................
            oadPhaseMsg = "Receive Result";
            settingsBloc.inAddTimerCmd.add(false); // 计时结束
            break;
          case OadPhase.CHECK_VERSION:
            // TODO: Handle this case.
            break;
        }

        var tile = NoneBorderColorExpansionTile(
          // todo  .................. 在这里添加点击事件, (包裹一个可点击的控件等)方式, 以控制面板的自动开启与关闭
          title: Text("Upgrade Firmware"),
          trailing: Consumer<AppState>(
            builder: (context, appState, _) {
              var oadState = appState.currentOadState;
              var device = appState.currentDevice;

              return (oadState.isOad || device == null)
                  ? Text("Please Connect Device")
                  : RaisedButton(
                      child: Text("Check for updates"),
                      onPressed: () {
                        //todo  可以考虑直接传入 OadState
                        _checkAndUpdateFirmware(
                            device, settingsBloc.inAddOadCmd);
                      });
            },
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Update Phrase  ",
                    style: greyTextStyle,
                    softWrap: true,
                  ),
                  Text(
                    oadPhaseMsg,
                    style: greyTextStyle,
                    softWrap: true,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Text(
                "Oad Progress",
                textAlign: TextAlign.center,
                style: greyTextStyle,
              ),
              title: LinearProgressIndicator(
                value: snap.data.sendFirmProgress,
              ),
              trailing: Text(
                "${(snap.data.phraseProgress * 100).toStringAsFixed(2)}%",
                style: greyTextStyle,
              ),
            ),
            // 计时............................................................
            StreamBuilder<int>(
              stream: settingsBloc.outCurrentTime,
              initialData: 0,
              builder: (context, snap) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
                child: Text("${snap.data / 1000} sec"),
              ),
            ),
          ],
        );
//        tile.handleTap();
        return tile;
      },
    );
  }

  // todo .............................请将该方法放入BLoC中处理.........................
  void _checkAndUpdateFirmware(
      RaceDevice device, StreamSink<RaceDevice> inAddOadCmd) {
    print(
        'SettingsPage._checkAndUpdateFirmware 升级按钮被点击了! 当前已连接的设备: ${device.device.name}');
    // todo 这里弹出窗口, 检查更新( 将该步骤移动到Oad流程中)
    // 升级固件流程
    inAddOadCmd.add(device);
  }
}
