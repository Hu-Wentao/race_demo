import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'app_const.dart';
import 'pages/device_screen.dart';
import 'widgets/radius_botton_widget.dart';
import 'widgets/radius_container_widget.dart';
import 'widgets/scan_result_tile.dart';
import 'widgets/text_divider_widget.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  //todo 需要判断 蓝牙是否开启
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Race Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: "蓝牙 demo"),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

//  StreamTransformer _filterDevice = new StreamTransformer<List<ScanResult>, List<ScanResult>>.fromHandlers(handleData: (data, sink));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TextDivider(
                "已配对设备",
                padLTRB: [16.0, 16.0, 16.0, 8.0],
              ),
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (buildContext, asyncSnapshot) => Column(
                  children: asyncSnapshot.data
                      .map((data) => RadiusContainer(
                              child: ListTile(
                            title: Text(data.name),
                            subtitle: Text(data.id.toString()),
                            trailing: StreamBuilder<BluetoothDeviceState>(
                              stream: data.state,
                              initialData: BluetoothDeviceState.disconnected,
                              builder: (c, snapshot) {
                                if (snapshot.data ==
                                    BluetoothDeviceState.connected) {
                                  return RadiusButton(
                                    child: Text("打开"),
                                    onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                DeviceScreen(device: data))),
                                  );
                                }
                                return RadiusButton(
                                    child: Text(snapshot.data.toString()));
                              },
                            ),
                          )))
                      .toList(),
                ),
              ),
              TextDivider("扫描结果"),
              StreamBuilder<List<ScanResult>>(
                /// 只显示 race开头的设备  *********************** 在这里过滤设备 **********
                stream: FlutterBlue.instance.scanResults.where((event) {
                  // todo del #######
                  print((event as ScanResult).device.name.toString());

                  return true;
//                  return (event as ScanResult).device.name.startsWith("Race");
                }),
                initialData: [],
                builder: (buildContext, asyncSnapshot) => Column(
                    children: asyncSnapshot.data
                            ?.map((data) => RadiusContainer(
                                  child: ScanResultTile(
                                      result: data,
                                      onTap: _jumpToDeviceScreen(context, data)),
                                ))
                            ?.toList() ??
                        [Text("没有扫描到Race开头的设备")]),
              )
            ],
          ),
        ));
  }

  /// 构建页面的appBar
  _buildAppBar() {
    return AppBar(
      title: Text(title),
      actions: <Widget>[
        StreamBuilder<bool>(
          stream: FlutterBlue.instance.isScanning,
          initialData: false,
          builder: (buildContext, asyncSnapshot) {
            if (asyncSnapshot.data) {
              return FlatButton(
                // todo 制作一个  表示正在搜索蓝牙设备的动画,
                // 方案1, 放一个刷新icon, 点击即旋转, 表示正在搜索, 动画结束, 表示搜索完毕
                // 方案2, 放一个正在搜索蓝牙icon, 点击后, 表示信号的弧形慢慢增多, 然后
                child: Icon(
                  Icons.stop,
                  color: Colors.red,
                ),
                onPressed: () => FlutterBlue.instance.stopScan(),
              );
            } else {
              return FlatButton(
                child: Icon(
                  Icons.search,
                  color: Colors.white,
                ),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: AppConst.BLUE_SCAN_TIMEOUT),
              );
            }
          },
        )
      ],
    );
  }

  /// 跳转到设备页面
  _jumpToDeviceScreen(BuildContext context, ScanResult data) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
//        data.device.connect();
        return DeviceScreen(device: data.device);
      }),
    );
  }
}
