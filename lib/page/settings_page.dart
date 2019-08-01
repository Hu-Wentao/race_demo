import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:race_demo/bloc/base_bloc.dart';
import 'package:race_demo/bloc/home_bloc.dart';
import 'package:race_demo/bloc/settings_page_bloc.dart';
import 'package:race_demo/widget/none_border_color_expansion_tile.dart';
import 'package:race_demo/widget/radius_container_widget.dart';
import 'package:race_demo/widget/text_divider_widget.dart';

class SettingsPage extends StatelessWidget {
  final String title;
  final HomeBloc homeBloc;

  const SettingsPage(this.homeBloc, {Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SettingsPageBloc _settingsBloc =
        BlocProvider.of<SettingsPageBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
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
                child: _buildUpgradeFirmware(context, homeBloc, _settingsBloc),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _buildSetSpeedUnit(BuildContext context) {
    return ListTile(title: Text("test"));
  }

  _buildSetAltitudeUnit(BuildContext context) {
    return ListTile(title: Text("test"));
  }

  _buildSetPositionStyle(BuildContext context) {
    return ListTile(title: Text("test"));
  }

  _buildUpgradeFirmware(
      BuildContext context, HomeBloc homeBloc, SettingsPageBloc settingsBloc) {
    final greyTextStyle =
        TextStyle(color: Theme.of(context).textTheme.caption.color);

    return StreamBuilder<UpdateProgressInfo>(
      stream: settingsBloc.outUpdateProgress,
      initialData: UpdateProgressInfo(
        null,
        phraseProgress: 0.0,
      ),
      builder: (context, snap) {

//        settingsBloc.inAddTimerCmd.add(snap.data.updatePhase == UpdatePhase.GET_FIRM);
        String updatePhaseMsg = "Null";
        switch (snap.data.updatePhase) {
          case UpdatePhase.GET_FIRM:
            settingsBloc.inAddTimerCmd.add(true); // 开始计时
            updatePhaseMsg = "Downloading firm...";
            break;
          case UpdatePhase.REQUEST_MTU_PRIORITY:
            updatePhaseMsg = "Request MTU & Priority...";
            break;
          case UpdatePhase.LISTEN_CHARA_AND_SEND_HEAD:
            updatePhaseMsg = "Open characteristic notify...";
            break;
          case UpdatePhase.RECEIVE_NOTIFY:
            updatePhaseMsg = "Sending Firmware...";
            break;
          case UpdatePhase.LISTENED_RESULT:
            //todo 此处应显示 升级成功 或 升级失败.....................
            updatePhaseMsg = "Sending Firmware...";

            settingsBloc.inAddTimerCmd.add(false);  // 计时结束
            break;
        }

        return NoneBorderColorExpansionTile(
          title: Text("Upgrade Firmware"),
          trailing: StreamBuilder<BluetoothDevice>(
              stream: homeBloc.outGetConnectedDevice,
              builder: (context, snap) {
                return RaisedButton(
                  child: Text("Check for updates"),
                  onPressed: () {
                    _checkAndUpdateFirmware(
                        snap.data, settingsBloc.inAddOadCmd);
                  },
                );
              }),
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
                    updatePhaseMsg,
                    style: greyTextStyle,
                    softWrap: true,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Text(
                "Total\nProgress",
                textAlign: TextAlign.center,
                style: greyTextStyle,
              ),
              title: LinearProgressIndicator(
                value: snap.data.sendFirmProgress,
              ),
              trailing: Text(
//                "${(snap.data.totalProgress * 100).toStringAsFixed(2)}%",
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
                child: Text("${snap.data/1000} sec"),
              ),
            ),
          ],
        );
      },
    );
  }

  void _checkAndUpdateFirmware(
      BluetoothDevice device, StreamSink<BluetoothDevice> inAddOadCmd) {
    print(
        'SettingsPage._checkAndUpdateFirmware 升级按钮被点击了! 当前已连接的设备: ${device.name}');
    // TODO 检查固件版本
    // 升级固件流程
    inAddOadCmd.add(device);
  }
}
