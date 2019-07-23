import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:race_demo/bloc/base_bloc.dart';
import 'package:race_demo/bloc/home_bloc.dart';
import 'package:race_demo/bloc/settings_page_bloc.dart';
import 'package:race_demo/widget/radius_container_widget.dart';
import 'package:race_demo/widget/text_divider_widget.dart';

class SettingsPage extends StatelessWidget {
  final String title;
  final HomeBloc homeBloc;

  const SettingsPage(this.homeBloc, {Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SettingsPageBloc _bloc = BlocProvider.of<SettingsPageBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            TextDivider(
              "Show speed in: ",
            ),
            _buildSetSpeedUnit(context),
            TextDivider(
              "Show altitude in: ",
            ),
            _buildSetAltitudeUnit(context),
            TextDivider(
              "Display position as: ",
            ),
            _buildSetPositionStyle(context),
            TextDivider(
              "About device",
            ),
            _buildUpgradeFirmware(context, homeBloc, _bloc),
          ],
        ),
      ),
    );
  }

  _buildSetSpeedUnit(BuildContext context) {
    return RadiusContainer(
      child: ListTile(title: Text("test")),
    );
  }

  _buildSetAltitudeUnit(BuildContext context) {
    return RadiusContainer(
      child: ListTile(title: Text("test")),
    );
  }

  _buildSetPositionStyle(BuildContext context) {
    return RadiusContainer(
      child: ListTile(title: Text("test")),
    );
  }

  _buildUpgradeFirmware(
      BuildContext context, HomeBloc homeBloc, SettingsPageBloc settingsBloc) {
    return RadiusContainer(
        child: Column(
      children: <Widget>[
        ListTile(
          title: Text("Upgrade Firmware"),
          trailing: StreamBuilder<BluetoothDevice>(
              stream: homeBloc.outGetConnectedDevice,
              initialData: null,
              builder: (context, snap) {
                if (snap.data == null) {
                  return RaisedButton(
                    child: Text("Please Connect Device"),
                    onPressed: null, // todo 点击之后就开始扫描并连接设备(去调用 Status那边的Bloc)
                  );
                }
                return RaisedButton(
                  child: Text("Check for updates"),
                  onPressed: () => _checkAndUpdateFirmware(
                      snap.data, settingsBloc.inAddOadCmd),
                );
              }),
        ),
        StreamBuilder<UpdateProgressInfo>(
          stream: settingsBloc.outUpdateProgress,
          initialData: UpdateProgressInfo(
            null,
            phraseProgress: 0.0,
          ),
          builder: (context, snap) {
            String updatePhaseMsg;
            switch (snap.data.updatePhase) {
              case UpdatePhase.DOWNLOAD_FIRM:
                updatePhaseMsg = "Downloading firm...";
                break;
              case UpdatePhase.FIND_SERVICE:
                updatePhaseMsg = "Finding Service...";
                break;
              case UpdatePhase.OPEN_CHARA:
                updatePhaseMsg = "Open characteristic";
                break;
              case UpdatePhase.SEND_HEAD:
                updatePhaseMsg = "Send head...";
                break;
              case UpdatePhase.SEND_FIRM:
                updatePhaseMsg = "Updataing...";
                break;
              case UpdatePhase.RECEIVE_RESULT:
                updatePhaseMsg = "Receive result...";
                break;
            }

            return Column(
              children: updatePhaseMsg == null
                  ? []
                  : <Widget>[
                      ListTile(
                        title: Text("Updata Phrase"),
                        trailing: Text(updatePhaseMsg),
                      ),
                    ],
            );
          },
        )
      ],
    ));
  }

  void _checkAndUpdateFirmware(BluetoothDevice device,
      StreamSink<BluetoothDevice> inAddOadCmd) {
    print(
        'SettingsPage._checkAndUpdateFirmware 升级按钮被点击了! 当前已连接的设备: ${device.name}');
    // TODO 检查固件版本
    // 升级固件流程
    inAddOadCmd.add(device);
  }
}
