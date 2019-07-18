import 'package:flutter/material.dart';

class HomePage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Status"),),
      bottomNavigationBar: BottomNavigationBar(items: [
        BottomNavigationBarItem(icon: Icon(Icons.storage), title: Text("Status"),),
        BottomNavigationBarItem(icon: Icon(Icons.settings), title: Text("Settings")),
        BottomNavigationBarItem(icon: Icon(Icons.info), title: Text("info"))
      ]),
    );
  }

}