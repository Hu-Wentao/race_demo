import 'package:flutter/material.dart';

import 'page/home_page.dart';
import 'page/settings_page.dart';

void main()=>(runApp(
  MaterialApp(
    title: "Race demo",
    home: HomePage(),
    routes: <String, WidgetBuilder>{
    "/status": (BuildContext context)=> HomePage(),
    "/settings": (BuildContext context)=> SettingsPage(),
  },
  )
));