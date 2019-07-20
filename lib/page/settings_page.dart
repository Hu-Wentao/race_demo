import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:race_demo/bloc/base_bloc.dart';
import 'package:race_demo/bloc/home_bloc.dart';
import 'package:race_demo/bloc/settings_page_bloc.dart';
import 'package:race_demo/widget/radius_container_widget.dart';
import 'package:race_demo/widget/text_divider_widget.dart';

class SettingsPage extends StatelessWidget {
  final String title;
  const SettingsPage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SettingsPageBloc _bloc = BlocProvider.of<SettingsPageBloc>(context);

//    final _homeBloc = BlocProvider.of<HomeBloc>(context);
//    print('SettingsPage.build 找到 homebloc: ${_homeBloc.info}');

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
              "About Device",
            ),
            _buildUpgradeFirmware(context, _bloc),
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

  _buildUpgradeFirmware(BuildContext context, SettingsPageBloc bloc) {

    return RadiusContainer(
      child: ListTile(
        title: Text("Upgrade Firmware"),
        trailing: StreamBuilder<BluetoothDevice>(
          stream: bloc.outGetConnectedDevice,
          initialData: null,
          builder: (context, snap){
            if(snap.data == null){
              return RaisedButton(
                child: Text("Please Connect Device"),
                onPressed: null,// todo 点击之后就开始扫描并连接设备(去调用 Status那边的Bloc)
              );
            }
            return RaisedButton(
              child: Text("Check for updates"),
              onPressed: ()=>_checkAndUpdateFirmware(snap.data),
            );
          }
        ),

      ),
    );
  }
  void _checkAndUpdateFirmware(BluetoothDevice device) {
    // TODO 检查固件版本
    // 升级固件

  }
}
