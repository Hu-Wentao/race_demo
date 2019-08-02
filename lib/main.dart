// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:race_demo/provider/app_state.dart';
import 'page/home_page.dart';

main() => runApp(ChangeNotifierProvider(
      builder: (context) => AppState(),
      child: MainApp(),
    ));

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "RaceHF Bean",
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: HomePage(),
    );
  }
}
