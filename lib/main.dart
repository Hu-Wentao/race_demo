import 'package:flutter/material.dart';

import 'page/home_page.dart';

void main()=>(runApp(
  MaterialApp(
    title: "Race demo",
    theme: ThemeData(
      primarySwatch: Colors.red,
    ),
    home: HomePage(),
  )
));

