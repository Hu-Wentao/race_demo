// Copyright 2019/7/26, Hu-Wentao. All rights reserved.
// Email: hu.wentao@outlook.com
import 'package:flutter/material.dart';
import 'bloc/base_bloc.dart';
import 'bloc/home_bloc.dart';
import 'page/home_page.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
          title: "RaceHF Bean",
          theme: ThemeData(
            primarySwatch: Colors.red,
          ),
          home: BlocProvider<HomeBloc>(
            bloc: HomeBloc(),
            child: HomePage(),
          ),
        );
  }
}


