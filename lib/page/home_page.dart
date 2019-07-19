import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:race_demo/bloc/base_bloc.dart';
import 'package:race_demo/bloc/settings_page_bloc.dart';
import 'package:race_demo/bloc/status_page_bloc.dart';

import 'settings_page.dart';
import 'status_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.storage), title: Text("Status")),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), title: Text("Settings")),
          ],
        ),
        tabBuilder: (BuildContext context, int index) {
          switch (index) {
            case 0:
              return BlocProvider<StatusPageBloc>(
                bloc: StatusPageBloc(),
                child: StatusPage(
                  title: "Status",
                ),
              );
              break;
            case 1:
              return BlocProvider<SettingsPageBloc>(
                bloc: SettingsPageBloc(),
                child: SettingsPage(
                  title: "Settings",
                ),
              );
              break;
          }
          return null;
        });
  }
}
