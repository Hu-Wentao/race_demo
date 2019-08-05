// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:race_demo/redux/app_redux.dart';
import 'package:redux/redux.dart';

import 'page/home_page.dart';

void main() {
  runApp(AppRedux());
}

class AppRedux extends StatelessWidget {
  final Store<AppState> store =
      Store<AppState>(appReducer, initialState: AppState.initState());

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
        store: store,
        child: MaterialApp(
            title: "RaceHF Bean",
            theme: ThemeData(
              primarySwatch: Colors.red,
            ),
            home: HomePage()));
  }
}
