// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'package:flutter/material.dart';
import 'package:race_demo/provider/store.dart';
import 'page/home_page.dart';


void main () {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('根部重建: $context');
    return Store.init(
        context: context,
        child: MaterialApp(
          title: 'Provider',
          home: Builder(
            builder: (context) {
              Store.widgetCtx = context;
              print('widgetCtx: $context');
              return HomePage();
            },
          ),
        )
    );
  }
}

//main() => runApp(ChangeNotifierProvider(
//      builder: (context) => RaceModel(),
//      child: MainApp(),
//    ));
//
//class MainApp extends StatelessWidget {
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      title: "RaceHF Bean",
//      theme: ThemeData(
//        primarySwatch: Colors.red,
//      ),
//      home: HomePage(),
//    );
//  }
//}
