import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:race_demo/bloc/base_bloc.dart';
import 'package:race_demo/bloc/home_bloc.dart';
import 'package:race_demo/bloc/settings_page_bloc.dart';
import 'package:race_demo/race_device.dart';
import 'package:race_demo/redux/app_redux.dart';
import 'package:race_demo/widget/none_border_color_expansion_tile.dart';
import 'package:race_demo/widget/radius_container_widget.dart';
import 'package:race_demo/widget/radius_stream_expansion_tile.dart';
import 'package:race_demo/widget/text_divider_widget.dart';

class SettingsPage extends StatelessWidget {
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
        OadPhase.UN_OAD,
        "init",
        phraseProgress: 0.0,
      ),
      builder: (context, snap) {
        final String oadPhaseMsg = snap.data.phaseMsg;
        return RadiusStreamExpansionTile(
          title: Text("Upgrade Firmware"),
          trailing: StoreConnector<AppState, bool>(
            builder: (context, showBtnBool) => Offstage(
              // 如果正在OAD, 则隐藏trailing
              offstage: showBtnBool,
              child: StoreConnector<AppState, bool>(
                builder: (context, haveConnectedDevice) => haveConnectedDevice
                // 当前是否已连接设备, 如果已连接, 则提示"检查更新", 否则提示 "请连接设备"
                    ?  RaisedButton(
                        child: Text("Check for updates"),
                        onPressed: () {
                          settingsBloc.inAddUpdateCmd.add(UpdateCtrlCmd(OadPhase.INIT_OAD, context));
                        },
                      )
                    : Text("Please Connect Device"),
                converter: (appStore) => appStore.state.deviceState.currentDevice != null,
              ),
            ),
            converter: (appStore) {
              print('SettingsPage._buildUpgradeFirmware ######## isOad 改变: ${appStore.state.oadState.oadPhase}.............................');
              return appStore.state.oadState.isOad;
            },
          ),
          manualControl: false,
          expansionStream: settingsBloc.outUpdateProgress.map((upi)=>upi.oadPhase != OadPhase.UN_OAD),
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
                "OAD\nProgress",
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
      },
    );
  }
}
